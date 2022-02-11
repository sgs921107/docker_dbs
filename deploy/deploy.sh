#########################################################################
# File Name: deploy.sh
# Author: xiangcai
# mail: xiangcai@gmail.com
# Created Time: Wed 19 Feb 2020 12:29:13 PM CST
#########################################################################
#!/bin/bash

# ===================run the script with root user=================================
# 1.首先根据conf目录下conf demo生成自己的配置文件
#   conf/my.cnf.demo -> /etc/dbs/my.cnf
#   conf/redis.conf.demo -> /etc/dbs/redis.conf
#   conf/elasticsearch0.yml.demo -> /etc/dbs/elasticsearch0.yml
#   conf/env_demo -> /etc/dbs/.env
# 3.使用root用户执行此脚本
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
    # 将服务的宿主机端口添加至防火墙
    # upper_service=${service^^}
    # if [ $service = es ]
    # then
    #     service_port1=`eval echo '$'"REAL_${upper_service}_TCP_PORT"`
    #     service_port2=`eval echo '$'"REAL_${upper_service}_HTTP_PORT"`
    #     firewall-cmd --permanent --add-port=$service_port1/tcp
    #     firewall-cmd --permanent --add-port=$service_port2/tcp
    # else
    #     service_port=`eval echo '$'"REAL_${upper_service}_PORT"`
    #     # 添加端口到防火墙
    #     firewall-cmd --permanent --add-port=$service_port/tcp
    # fi
done

# 删除产生的<none>镜像
# docker rmi $(docker images | grep '<none>' | awk '{print $3}')

# 重新加载防火墙
# firewall-cmd --reload
