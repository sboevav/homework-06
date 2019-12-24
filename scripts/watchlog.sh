#!/bin/bash

# Обрабатываемый лог-файл
LOG=$1
# Адрес почты, куда будет послано сообщение 
EMAIL=$2
# Длительность периода, в секундах
PERIOD=$3
# Количество IP адресов, посылаемое в сообщении, с которого поступило наибольшее количество запросов
IP_COUNT=$4
# Количество запрашиваемых адресов, посылаемое в сообщении, с наибольшим кол-вом запросов
ADDR_COUNT=$5
# Дата/время запуска скрипта
DATE=`date`

MESSAGE="/tmp/log_checking.txt"

#echo "LOG=$LOG"
#echo "EMAIL=$EMAIL"
#echo "PERIOD=$PERIOD"
#echo "IP_COUNT=$IP_COUNT"
#echo "ADDR_COUNT=$ADDR_COUNT"
#echo "DATE=$DATE"

#logger "LOG=$LOG"
#logger "EMAIL=$EMAIL"
#logger "PERIOD=$PERIOD"
#logger "IP_COUNT=$IP_COUNT"
#logger "ADDR_COUNT=$ADDR_COUNT"
#logger "DATE=$DATE"


#if grep -i $WORD $LOG &> /dev/null
#then
#  logger "$DATE: I found the word $WORD in the log $LOG, Master!"
#fi

createMessageFile () {
echo  "Hostname: `hostname`" > $MESSAGE
echo "+------------------------------+" >> $MESSAGE
checkLog
echo "+------------------------------+" >> $MESSAGE
}

checkLog () {
cat $LOG | awk '/GET \/ HTTP/{ ipcount[$1]++ } END { for (i in ipcount) { printf "IP:%15s - %d times\n", i, ipcount[i] } }' | sort -rn | head -10 >> $MESSAGE
}


# Сформируем текст письма
createMessageFile

logger "Message=$(< $MESSAGE)"

# Пошлем сформированный файл почты
#sudo bash /vagrant/scripts/sendemail.sh $EMAIL "Log_checking" $MESSAGE
# Удалим исходный файл письма
rm $MESSAGE

exit 0

