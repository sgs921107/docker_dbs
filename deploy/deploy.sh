#########################################################################
# File Name: deploy.sh
# Author: xiangcai
# mail: xiangcai@gmail.com
# Created Time: Wed 19 Feb 2020 12:29:13 PM CST
#########################################################################
#!/bin/bash

# ===================run the script with root user=================================
# 1.首先根据conf/env_demo生成自己的env配置文件/etc/dbs/.env
# 2.使用root用户执行此脚本
# =================================================================================

source /etc/dbs/.env

# 配置文件目录
conf_dir=../conf
# 安装docker的脚本路径
install_docker_script=./install_docker.sh
# mysql配置文件路径
mysql_conf=$conf_dir/my.cnf
# redis配置文件路径
redis_conf=$conf_dir/redis.conf
# es配置文件路径
es_conf=$conf_dir/elasticsearch0.yml

# 安装docker服务
sh $install_docker_script || { echo "部署失败: 安装docker失败,请检查是否缺少依赖并重新运行部署脚本"; exit 1; }

echo "COMPOSE_PROJECT_NAME=dbs
LOG_DIR=$DBS_LOG_DIR

MYSQL_VERSION=$MYSQL_VERSION
MYSQL_CONF=$mysql_conf
REAL_MYSQL_PORT=$REAL_MYSQL_PORT
MYSQL_ROOT_PASSWORD=$MYSQL_ROOT_PASSWORD
MYSQL_ROOT_HOST=$MYSQL_ROOT_HOST

REDIS_VERSION=$REDIS_VERSION
REDIS_CONF=$redis_conf
REAL_REDIS_PORT=$REAL_REDIS_PORT

ES_VERSION=$ES_VERSION
ES_CONF=$es_conf
REAL_ES_TCP_PORT=$REAL_ES_TCP_PORT
REAL_ES_HTTP_PORT=$REAL_ES_HTTP_PORT

ES_HEAD_VERSION=$ES_HEAD_VERSION
REAL_ES_HEAD_PORT=$REAL_ES_HEAD_PORT

MONGO_VERSION=$MONGO_VERSION
MONGO_ROOT_USERNAME=$MONGO_ROOT_USERNAME
MONGO_ROOT_PASSWORD=$MONGO_ROOT_PASSWORD
REAL_MONGO_PORT=$REAL_MONGO_PORT

RABBITMQ_VERSION=$RABBITMQ_VERSION
REAL_RABBITMQ_PORT=$REAL_RABBITMQ_PORT
REAL_RABBITMQ_ADMIN_PORT=$REAL_RABBITMQ_ADMIN_PORT
RABBITMQ_DEFAULT_USER=$RABBITMQ_DEFAULT_USER
RABBITMQ_DEFAULT_PASS=$RABBITMQ_DEFAULT_PASS
RABBITMQ_ERLANG_COOKIE=$RABBITMQ_ERLANG_COOKIE" > .env

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
default_character_set=utf8mb4" > $mysql_conf

echo "daemonize no
port 6379
requirepass $redis_passwd
bind $redis_bind
appendonly $appendonly

loglevel notice
logfile /logs/redis.log" > $redis_conf

echo "cluster.name: 'docker-cluster'
network.host: $es_bind
node.name: node0
node.master: true
node.data: true

# 配置跨域
http.cors.enabled: true
http.cors.allow-origin: '*'" > $es_conf

for service in $services
do
    # 创建服务日志目录, 并添加写权限
    service_log_dir="$DBS_LOG_DIR/$service"
    if [ ! -d "$service_log_dir" ]
    then
        mkdir -p $service_log_dir
    fi
    chmod a+w $service_log_dir

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

