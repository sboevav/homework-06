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

MESSAGE=/tmp/log_checking.txt
VARS_FILE=/etc/watchlogvars/vars
REC_NO=0
var1=qw
var2=123
LAST_DATE="-"

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
  # рабочий вариант - количество впереди
  echo "Обработка журнала со времени последнего запуска ($LAST_DATE)"

  echo "$IP_COUNT IP адресов с наибольшим количеством запросов" >> $MESSAGE
  cat $LOG | awk '/GET/{ ipcount[$1]++ } END { for (i in ipcount) { printf "%4d times - IP: %s\n", ipcount[i], i } }' | sort -rnk1 | head -$IP_COUNT >> $MESSAGE

  echo "$ADDR_COUNT запрашиваемых адресов с наибольшим количеством запросов" >> $MESSAGE
  cat $LOG | awk '/GET/{ addrcount[$11]++ } END { for (i in addrcount) { printf "%4d times - addr: %50s\n", addrcount[i], i } }' | sort -rnk1 | head -$ADDR_COUNT >> $MESSAGE

  echo "Полный список запросов с кодом возврата, отличающегося от 200 и 301" >> $MESSAGE
  cat $LOG | awk '$9 != 200 && $9 != 301' >> $MESSAGE

  echo "Перечень всех кодов возврата с указанием их количества" >> $MESSAGE
  cat $LOG | awk '{ ipcount[$9]++ } END { for (i in ipcount) { printf "result:%4d - %4d times\n", i, ipcount[i]} }' | sort -nk2 >> $MESSAGE
}

#TEMPVAR=0

if [ ! -f $VARS_FILE ]
then
  sudo mkdir -p  echo ${VARS_FILE%/*}
  sudo touch $VARS_FILE
  sudo chmod +777  $VARS_FILE
else
  while read REC_NO var2 var3; 
  do   
    logger "REC_NO=$REC_NO"
    logger "var2=$var2"
    logger "var3=$var3";
  done < "$VARS_FILE"

#  awk '{ vars[$1]=$1 } END { for (i in vars) { printf "%10s=%s\n", i, vars[i]} }'
#  read REC_NO < "$VARS_FILE"
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
#mail -s "Log_checking" "$EMAIL" < $MESSAGE
sudo bash /vagrant/scripts/sendemail.sh $EMAIL "Log_checking ($DATE)" $MESSAGE
# Удалим исходный файл письма
#rm $MESSAGE

REC_NO=$((REC_NO+1))
#TEMPVAR=$((TEMPVAR+1000))

# сохраним переменные в файле
echo "$REC_NO" > $VARS_FILE
echo "$var2" >> $VARS_FILE
echo "$var3" >> $VARS_FILE

#echo "$TEMPVAR" >> $VARS_FILE

exit 0

