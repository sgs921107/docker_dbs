#########################################################################
# File Name: deploy.sh
# Author: xiangcai
# mail: xiangcai@gmail.com
# Created Time: Wed 19 Feb 2020 12:29:13 PM CST
#########################################################################
#!/bin/bash

# ===================run the script with root user=================================
# 1.首先根据conf目录下conf demo生成自己的配置文件(不启动的服务忽略)
#   conf/my.cnf.demo -> /etc/dbs/my.cnf
#   conf/redis.conf.demo -> /etc/dbs/redis.conf
#   conf/elasticsearch0.yml.demo -> /etc/dbs/elasticsearch0.yml
#   conf/env_demo -> /etc/dbs/.env
# 2.使用root用户执行此脚本
#   sudo sh deploy.sh
# 
# expmple cmd:
# set -ex \
#   && mkdir /etc/dbs \
#   && cp ../conf/my.cnf.demo /etc/dbs/my.cnf \
#   && cp ../conf/redis.conf.demo /etc/dbs/redis.conf \
#   && cp ../conf/elasticsearch0.yml.demo /etc/dbs/elasticsearch0.yml \
#   && cp ../conf/env_demo /etc/dbs/.env
# =================================================================================

source /etc/dbs/.env

# 进入部署目录
cd $HOST_PROJECT_DIR/deploy

# 安装docker服务
sh install_docker.sh || { echo "部署失败: 安装docker失败,请检查是否缺少依赖并重新运行部署脚本"; exit 1; }

# 将.env链接至部署目录
ln -s /etc/dbs/.env $HOST_PROJECT_DIR/deploy/.env


# 启动服务
for service in mysql redis es es_head mongo rabbitmq
do
    switch=`echo service_$service | tr a-z A-Z`
    if [ "$(eval echo \$$switch)" == "1" ]
    then
        docker-compose up -d $service \
        && { echo "启动"$service"服务成功"; docker-compose logs  --tail 10 $service; } \
        || echo "启动服务"$service"失败!!!"
    fi
done
