#########################################################################
# File Name: deploy.sh
# Author: xiangcai
# mail: xiangcai@gmail.com
# Created Time: Wed 19 Feb 2020 12:29:13 PM CST
#########################################################################
#!/bin/bash

# ===================run the script with root user=================================
# ==========================开始配置==================================

# 1.docker-compose.yml依赖配置
# mysql 版本
MYSQL_VERSION=5.7
# 宿主机mysql服务端口
REAL_MYSQL_PORT=3306
# mysql root密码
MYSQL_ROOT_PASSWORD=123456
# 允许使用root用户访问mysql的ip地址
MYSQL_ROOT_HOST=localhost

# redis 版本
REDIS_VERSION=latest
# 宿主机redis服务端口
REAL_REDIS_PORT=6379

# es 版本
ES_VERSION=6.6.2
# 宿主机redis服务端口
REAL_ES_HTTP_PORT=9200
REAL_ES_TCP_PORT=9300

# es_head 版本
ES_HEAD_VERSION=5
# 宿主机redis服务端口
REAL_ES_HEAD_PORT=9100

# 2.mysql服务配置
# 默认引擎
default_storage_engine=INNODB
# 默认时区
default_time_zone='+8:00'
# 事务超时后的回滚策略
innodb_rollback_on_timeout='ON'
# 最大连接数
max_connections=2048
# 事务超时时间
innodb_lock_wait_timeout=50
# 处理时间超过多少秒标记为慢查询
long_query_time=1
mysql_bind=0.0.0.0

# 3.redis服务配置
redis_bind=0.0.0.0
# 是否持久化
appendonly=yes

# 4.es服务配置
es_bind=0.0.0.0

# 是否配置docker加速器 
# 是否配置docker加速器   1/0
docker_accelerator=1
# 是否指定pip的下载源
pip_repository=https://pypi.tuna.tsinghua.edu.cn/simple
# 启动的服务
services="mysql redis es es_head"

# ==========================配置结束==================================

for service in $services
do
    mkdir -p ../$service/{data,logs}
    chmod o+w ../$service/logs
    if [ $service = es ]
    then
        chmod 777 ../$service/{data,logs}
    fi
done


# 声明变量
install_docker_script=./install_docker.sh
mysql_dir=../mysql
mysql_conf=$mysql_dir/my.cnf
redis_dir=../redis
redis_conf=$redis_dir/redis.conf
es_dir=../es
es_conf=$es_dir/elasticsearch0.yml
es_head_dir=../es_head

if [ -n "$pip_repository" ]
then
    sed -i "s#pip install#pip install -i $pip_repository#g" $install_docker_script
fi


# 检查/安装docker和docker-compose
sh $install_docker_script
if [ -n "$pip_repository" ]
then
    git checkout $install_docker_script
fi

if [ "$docker_accelerator" = 1 ]
then
    echo '{"registry-mirrors":["https://docker.mirrors.ustc.edu.cn"]}' > /etc/docker/daemon.json
    systemctl daemon-reload 
    systemctl restart docker
fi


echo "MYSQL_VERSION=$MYSQL_VERSION
MYSQL_DIR=$mysql_dir
MYSQL_CONF=$mysql_conf
REAL_MYSQL_PORT=$REAL_MYSQL_PORT
MYSQL_ROOT_PASSWORD=$MYSQL_ROOT_PASSWORD
MYSQL_ROOT_HOST=$MYSQL_ROOT_HOST

REDIS_VERSION=$REDIS_VERSION
REDIS_DIR=$redis_dir
REDIS_CONF=$redis_conf
REAL_REDIS_PORT=$REAL_REDIS_PORT

ES_VERSION=$ES_VERSION
ES_DIR=$es_dir
ES_CONF=$es_conf
REAL_ES_TCP_PORT=$REAL_ES_TCP_PORT
REAL_ES_HTTP_PORT=$REAL_ES_HTTP_PORT

ES_HEAD_VERSION=$ES_HEAD_VERSION
ES_HEAD_DIR=$es_head_dir
REAL_ES_HEAD_PORT=$REAL_ES_HEAD_PORT
" > .env

echo "[mysqld]
default_storage_engine=$default_storage_engine
default_time_zone=$default_time_zone
innodb_rollback_on_timeout=$innodb_rollback_on_timeout
max_connections=$max_connections
innodb_lock_wait_timeout=$innodb_lock_wait_timeout
character_set_server=utf8mb4
collation_server=utf8mb4_unicode_ci
init_connect='SET NAMES utf8mb4'
explicit_defaults_for_timestamp=true
skip_host_cache
skip_name_resolve
disable_partition_engine_check=1
log_error=/logs/error.log
slow_query_log_file=/logs/slow.log
slow_query_log=on
long_query_time=$long_query_time
general_log=off
general_log_file=/logs/mysql.log
log_bin=mysql_bin
server_id=1
expire_logs_days=14
max_binlog_size=100M
bind_address=$mysql_bind

[client]
default_character_set=utf8mb4

[mysql]
default_character_set=utf8mb4
" > $mysql_conf

echo "daemonize no
port 6379
bind $redis_bind
appendonly $appendonly

loglevel notice
logfile /logs/redis.log
" > $redis_conf

echo "cluster.name: 'docker-cluster'
network.host: $es_bind
node.name: node0
node.master: true
node.data: true

# 配置跨域
http.cors.enabled: true
http.cors.allow-origin: '*'
" > $es_conf

for service in $services
do
    # 启动服务
    docker-compose up -d $service
    upper_service=${service^^}
    if [ $service = es ]
    then
        service_port1=`eval echo '$'"REAL_${upper_service}_TCP_PORT"`
        service_port2=`eval echo '$'"REAL_${upper_service}_HTTP_PORT"`
        firewall-cmd --permanent --add-port=$service_port1/tcp
        firewall-cmd --permanent --add-port=$service_port2/tcp
    else
        service_port=`eval echo '$'"REAL_${upper_service}_PORT"`
        # 添加端口到防火墙
        firewall-cmd --permanent --add-port=$service_port/tcp
    fi
done

# 重新加载防火墙
firewall-cmd --reload

