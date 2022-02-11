# docker_dbs
使用docker部署数据库服务

# 项目描述
> 使用docker部署单机模式的数据库  
> 支持的服务：redis、mysql、es、mongo、elasticsearch

# centos7+用户部署
## 1.克隆或下载项目 
## 2.进入项目部署目录
> cd docker_dbs/deploy
## 3.根据配置文件demo生成自己的配置文件
首先根据conf目录下conf demo生成自己的配置文件
> conf/my.cnf.demo -> /etc/dbs/my.cnf  
> conf/redis.conf.demo -> /etc/dbs/redis.conf  
> conf/elasticsearch0.yml.demo -> /etc/dbs/elasticsearch0.yml  
> conf/env_demo -> /etc/dbs/.env
## 4.执行部署脚本
> sh deploy.sh
