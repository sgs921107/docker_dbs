#!/bin/bash
#########################################################################
# File Name: deploy.sh
# Author: 
# mail: 
# Created Time: Thu 19 Sep 2019 04:10:20 PM CST
#########################################################################

# 移除旧版本docker
# yum remove docker  docker-common docker-selinux docker-engine

# 判断docker是否已安装
if ! docker --version;
then
    # 更新yum
    yum update -y
    
    # 安装依赖
    yum install -y yum-utils device-mapper-persistent-data lvm2
    # 添加docker源 
    sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
    # 安装docker
    yum install -y docker-ce
    # 安装命令补全
    yum install -y bash-completion
    # 加速
    echo '{"registry-mirrors":["https://docker.mirrors.ustc.edu.cn"]}' > /etc/docker/daemon.json
    # systemctl restart docker
fi

# 启动docker配置开机自启
systemctl start docker
systemctl enable docker

# 判断docker-compose是否已安装
if ! docker-compose --version;
then
    # 安装docker-compose依赖
    yum -y install libffi-devel epel-release python-pip python-devel
    yum -y groupinstall 'Development Tools'
    
    yum clean all && rm -rf /var/cache/yum/* && rm -rf /tmp/*
    # 安装docker-compose
    pip install --upgrade pip
    pip install --no-cache-dir docker-compose
fi
