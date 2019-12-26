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
VARS_FILE=/etc/watchlogvars/vars
REC_NO=0
LAST_DATE="-"

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
# рабочий вариант - адрес впереди 
#cat $LOG | awk '/GET/{ ipcount[$1]++ } END { for (i in ipcount) { printf "IP: %15s - %d times\n", i, ipcount[i] } }' | sort -rnk4 | head -$IP_COUNT
#cat $LOG | awk '/GET/{ addrcount[$11]++ } END { for (i in addrcount) { printf "ADDR: %50s - %d times\n", i, addrcount[i] } }' | sort -rnk4 | head -$ADDR_COUNT

  # рабочий вариант - количество впереди
  echo "$IP_COUNT IP адресов с наибольшим кол-вом запросов" >> $MESSAGE
  cat $LOG | awk '/GET/{ ipcount[$1]++ } END { for (i in ipcount) { printf "%4d times - IP: %s\n", ipcount[i], i } }' | sort -rnk1 | head -$IP_COUNT >> $MESSAGE

  echo "$ADDR_COUNT запрашиваемых адресов с наибольшим кол-вом запросов" >> $MESSAGE
  cat $LOG | awk '/GET/{ addrcount[$11]++ } END { for (i in addrcount) { printf "%4d times - addr: %50s\n", addrcount[i], i } }' | sort -rnk1 | head -$ADDR_COUNT >> $MESSAGE

  echo "Полный список запросов со времени последнего запуска ($LAST_DATE), с кодом возврата, отличающегося от 200 и 301" >> $MESSAGE
  cat $LOG | awk '$9 != 200 && $9 != 301' >> $MESSAGE

}

#TEMPVAR=0

if [ ! -f $VARS_FILE ]
then
  sudo mkdir -p  echo ${VARS_FILE%/*}
  sudo touch $VARS_FILE
  sudo chmod +777  $VARS_FILE
else
  read REC_NO < "$VARS_FILE"
  logger "REC_NO=$REC_NO"
#  read TEMPVAR < "$VAR_SFILE"
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

REC_NO=$((REC_NO+1))
#TEMPVAR=$((TEMPVAR+1000))

# сохраним переменные в файле
echo "$REC_NO" > $VARS_FILE
#echo "$TEMPVAR" >> $VARS_FILE

exit 0

