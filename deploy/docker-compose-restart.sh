###
 # @Author: xiangcai
 # @Date: 2022-04-22 10:51:59
 # @LastEditors: xiangcai
 # @LastEditTime: 2022-04-22 10:58:31
 # @Description: file content
### 

echo "---------------------开始启动服务---------------------"
# 宿主机的env配置文件所在的目录
HOST_ENV_PATH=/etc/dbs/.env

source $HOST_ENV_PATH

# 启动服务
for service in mysql redis es es_head mongo rabbitmq
do
    switch_name=`echo service_"$service" | tr a-z A-Z`
    switch=$(eval echo \$$switch_name)
    if [ "$switch" != "0" ]
    then
        docker-compose restart $service \
        && { sleep 2; echo "启动"$service"服务成功"; docker-compose logs  --tail 10 $service; } \
        || echo "启动服务"$service"失败!!!"
    fi
done
echo "---------------------启动服务结束---------------------"