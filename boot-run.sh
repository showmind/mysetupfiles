#!/bin/bash
JAVA_OPTIONS_INITIAL=-Xms256M
JAVA_OPTIONS_MAX=-Xmx512M
#获取脚本所在的项目名称

BINPATH=$(cd `dirname $0`; pwd)

if [ $(ls ${BINPATH%/bin*}|grep .*.jar|wc -l) -gt 1 ] ;then
        echo “目录中含有多个jar文件”
        exit 0
fi
_JAR_KEYWORDS=$(ls ${BINPATH%/bin*}|grep .*.jar)
if [ "$_JAR_KEYWORDS" =  "" ] ;then
        echo “${BINPATH%/bin*}下未找到jar包！！”
        exit 0
fi
APP_NAME=${_JAR_KEYWORDS%.jar*}
if [ $1 == "start" ] ;then
        echo "当前启动的项目为：$APP_NAME，项目所在目录：${BINPATH%/bin*}"
fi
PID=$(ps aux | grep ${_JAR_KEYWORDS} | grep -v grep | awk '{print $2}' )

function check_if_process_is_running {
if [ "$PID" = "" ]; then
return 1
fi
ps -p $PID | grep "java"
return $?
}

# jar 包的启动参数 
prearg=''
postarg=''
for i in $@
do 
	echo "arg: $i";
	if [[ $i = --* ]]; then postarg="$postarg $i"; fi
	if [[ $i = -D* ]]; then prearg="$prearg $i"; fi
done


case "$1" in
status)
if check_if_process_is_running
then
echo -e "\033[32m $APP_NAME is running \033[0m"
else
echo -e "\033[32m $APP_NAME not running \033[0m"
fi
;;
stop)
if ! check_if_process_is_running
then
echo -e "\033[32m $APP_NAME already stopped \033[0m"
exit 0
fi
kill -9 $PID
echo -e "\033[32m Waiting for process to stop \033[0m"
NOT_KILLED=1
for i in {1..20}; do
if check_if_process_is_running
then
echo -ne "\033[32m . \033[0m"
sleep 1
else
NOT_KILLED=0
fi
done
echo
if [ $NOT_KILLED = 1 ]
then
echo -e "\033[32m Cannot kill process \033[0m"
exit 1
fi
echo -e "\033[32m $APP_NAME already stopped \033[0m"
;;
start)
if [ "$PID" != "" ] && check_if_process_is_running
then
echo -e "\033[32m $APP_NAME already running \033[0m"
exit 1
fi
cd ${BINPATH%/bin*}
nohup java -jar $JAVA_OPTIONS_INITIAL $JAVA_OPTIONS_MAX $prearg $_JAR_KEYWORDS $postarg >out.log  &
echo java -jar $JAVA_OPTIONS_INITIAL $JAVA_OPTIONS_MAX $prearg $_JAR_KEYWORDS $postarg 
echo -ne "\033[32m Starting \033[0m" 
for i in {1..20}; do
echo -ne "\033[32m.\033[0m"
sleep 1
done
if check_if_process_is_running
then
echo -e "\033[32m $APP_NAME fail \033[0m"
else
echo -e "\033[32m $APP_NAME started \033[0m"
fi
;;
restart)
$0 stop
if [ $? = 1 ]
then
exit 1
fi
$0 start
;;
*)
echo "Usage: $0 {start|stop|restart|status}"
exit 1
esac

exit 0
