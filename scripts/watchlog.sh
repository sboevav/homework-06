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
cat $LOG | awk '/GET/{ addrcount[$6$7$8]++ } END { for (i in addrcount) { printf "ADDR:%50s - %d times\n", i, addrcount[i] } }' | sort -rn | head -10 >> $MESSAGE

cat $LOG | awk '/GET /{ ipcount[$11]++ } END { for (i in ipcount) { printf "ADDR: %15s - %d times\n", i, ipcount[i] } }' | sort -rn > output
https://qarchive.ru/10042020_sortirovka_massiva_v_obolochke_s_pomosch_ju_awk
}

VARSFILE=/etc/watchlogvars/vars
RECNO=0
#TEMPVAR=0

if [ ! -f $VARSFILE ]
then
  sudo mkdir -p  echo ${VARSFILE%/*}
  sudo touch $VARSFILE
  sudo chmod +777  $VARSFILE
else
  read RECNO < "$VARSFILE"
  logger "RECNO=$RECNO"
#  read TEMPVAR < "$VARSFILE"
#  logger "TEMPVAR=$TEMPVAR"
fi


#if [ -n "$num" ]; then 
#      "переменная что-то имеет и можно запустить другой процесс"
#else
#   echo "пустая переменная, останавливаем скрипт"	
#   exit 0;
#fi


# Сформируем текст письма
createMessageFile

logger "Message=$(< $MESSAGE)"

# Пошлем сформированный файл почты
#sudo bash /vagrant/scripts/sendemail.sh $EMAIL "Log_checking" $MESSAGE
# Удалим исходный файл письма
rm $MESSAGE

RECNO=$((RECNO+1))
#TEMPVAR=$((TEMPVAR+1000))

# сохраним переменные в файле
echo "$RECNO" > $VARSFILE
#echo "$TEMPVAR" >> $VARSFILE

exit 0

