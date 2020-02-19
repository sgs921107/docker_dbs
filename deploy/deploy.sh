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
MYSQL_ROOT_HOST=%

# redis 版本
REDIS_VERSION=latest
# 宿主机redis服务端口
REAL_REDIS_PORT=6379

# 2.mysql服务配置
# 默认引擎
default_storage_engine=INNODB
# 默认时区
default_time_zone='+8:00'
# 事务超时后的回滚策略
innodb_rollback_on_timeout='ON'
# 最大连接数
max_connections=500
# 事务超时时间
innodb_lock_wait_timeout=500
# 编码
charset=utf8mb4

# 3.redis服务配置
redis_bind=0.0.0.0
# 是否持久化
appendonly=yes

# 是否配置docker加速器 
# 是否配置docker加速器   1/0
docker_accelerator=1
# 是否指定下载仓库      ""/或仓库地址
docker_repository=hub.c.163.com/library
# 是否指定pip的下载源
pip_repository=https://pypi.tuna.tsinghua.edu.cn/simple
# 启动的服务
services="mysql redis"

# ==========================配置结束==================================

for service in $services
do
    mkdir -p ../$service/{data,logs}
done


# 声明变量
install_docker_script=./install_docker.sh
mysql_dir=../mysql
mysql_conf=$mysql_dir/my.cnf
redis_dir=../redis
redis_conf=$redis_dir/redis.conf

if [ -n "$pip_repository" ]
then
    sed -i "s#pip install#pip install -i $pip_repository#g" $install_docker_script
fi


# 检查/安装docker和docker-compose
sh $install_docker_script
git checkout .

if [ "$docker_accelerator" = 1 ]
then
    echo '{"registry-mirrors":["https://docker.mirrors.ustc.edu.cn"]}' > /etc/docker/daemon.json
    systemctl daemon-reload 
    systemctl restart docker
fi


echo "MYSQL_VERSION=$MYSQL_VERSION
MYSQL_DIR=$mysql_dir
REAL_MYSQL_PORT=$REAL_MYSQL_PORT
MYSQL_ROOT_PASSWORD=$MYSQL_ROOT_PASSWORD
MYSQL_ROOT_HOST=$MYSQL_ROOT_HOST

REDIS_VERSION=$REDIS_VERSION
REDIS_DIR=$redis_dir
REAL_REDIS_PORT=$REAL_REDIS_PORT
" > .env

echo "[mysqld]
default-storage-engine=$default_storage_engine
default-time-zone=$default_time_zone
innodb_rollback_on_timeout=$innodb_rollback_on_timeout
max_connections=$max_connections
innodb_lock_wait_timeout=$innodb_lock_wait_timeout
character-set-server=$charset

[client]
default-character-set=$charset

[mysql]
default-character-set=$charset
" > $mysql_conf

echo "daemonize no
port 6379
bind $redis_bind
appendonly $appendonly
" > $redis_conf

for service in $services
do
    if [ -n "$docker_repository" ]
    then
        case $service in
            mysql)
                service_version=$MYSQL_VERSION
                service_port=$REAL_MYSQL_PORT
                ;;
            redis)
                service_version=$REDIS_VERSION
                service_port=$REAL_REDIS_PORT
                ;;
            *)
                echo "unsupported the service: $service"
        esac
        docker pull $docker_repository/$service:$service_version
        docker tag $docker_repository/$service:$service_version "$service-test":$service_version
    fi
    
    # 启动服务
    docker-compose up -d $service
    # 添加端口到防火墙
    firewall-cmd --permanent --add-port=$service_port/tcp
done

# 重新加载防火墙
firewall-cmd --reload

