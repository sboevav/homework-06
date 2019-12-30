#!/bin/bash

#-------------------------------------------------
# объявление переменных

# обрабатываемый лог-файл
LOG=$1
# адрес почты, куда будет послано сообщение 
EMAIL=$2
# количество обрабатываемых строк
RECORD_COUNT=$3
# количество IP адресов, посылаемое в сообщении, с которого поступило наибольшее количество запросов
IP_COUNT=$4
# количество запрашиваемых адресов, посылаемое в сообщении, с наибольшим кол-вом запросов
ADDR_COUNT=$5
# дата/время запуска скрипта
DATE=`date`
# временный файл для создания текста письма
MESSAGE=/tmp/log_checking.txt
# файл хранения переменных между вызовами скрипта
VARS_FILE=/etc/watchlogvars/vars
# файл блокировки повторного запуска скрипта
LOCK_FILE=/tmp/watchloglockfile

#logger "LOG=$LOG"
#logger "EMAIL=$EMAIL"
#logger "PERIOD=$PERIOD"
#logger "IP_COUNT=$IP_COUNT"
#logger "ADDR_COUNT=$ADDR_COUNT"
#logger "DATE=$DATE"

#-------------------------------------------------
# функции скрипта

# очистка временных данных при выходе
Cleanup() {
  # в качестве кода выхода запомним код возврата последней команды
  RET_VALUE=$?
  # удалим временный файл создания сообщения и файл блокировки скрипта 
  rm -rf "$MESSAGE"
  rm -rf "$LOCK_FILE"
  exit $RET_VALUE
}

# считывание сохраненных переменных из файла
# если файл не существует, то он создается и переменные инициализируются начальным значением
# допускается формат хранения:
#  - просто значение в строке (например 12)
#  - значение с указанием имени переменной (например var1=12)
LoadVars () {
  if [ ! -f $VARS_FILE ]
  then
    # файл не существует 
    # создаем файл
    sudo mkdir -p  echo ${VARS_FILE%/*}
    sudo touch $VARS_FILE
    sudo chmod +777  $VARS_FILE
    # инициализируем переменные начальными значениями
    REC_NO=1
    PREV_DATE="-"
  else
    # считываем весь файл в массив
    i=0 
    while IFS='' read -r line; do 
      v[$i]=$(echo ${line} | cut -f2 -d'=') 
      ((i++))
    done < "$VARS_FILE"
    # распределяем массив по переменным
    REC_NO=${v[0]}
    PREV_DATE=${v[1]}
  fi
}

# сохранение переменных в файл
# значения необходимо сохранять с указанием имени переменной (например var1=12)
SaveVars () {
  echo "REC_NO=$REC_NO" > $VARS_FILE
  echo "PREV_DATE=$PREV_DATE" >> $VARS_FILE
}

# обработка журнала
CheckLog () {
  echo "Обработка журнала со времени последнего запуска" >> $MESSAGE
  echo "($PREV_DATE - $DATE)" >> $MESSAGE
  echo "(записи: [$REC _NO; $REC_NO_LAST) )" >> $MESSAGE

  echo -e "\n1)$IP_COUNT IP адресов с наибольшим количеством запросов" >> $MESSAGE
  cat $LOG | awk -v first="$REC_NO" -v last="$REC_NO_LAST" 'first <= NR && NR < last && /GET/{ ipcount[$1]++ } END { for (i in ipcount) { printf "%4d раз - IP: %s\n", ipcount[i], i } }' | sort -rnk1 | head -$IP_COUNT >> $MESSAGE

  echo -e "\n2)$ADDR_COUNT запрашиваемых адресов с наибольшим количеством запросов" >> $MESSAGE
  cat $LOG | awk -v first="$REC_NO" -v last="$REC_NO_LAST" 'first <= NR && NR < last && /GET/{ addrcount[$11]++ } END { for (i in addrcount) { printf "%4d раз - addr: %50s\n", addrcount[i], i } }' | sort -rnk1 | head -$ADDR_COUNT >> $MESSAGE

  echo -e "\n3) Полный список запросов с кодом возврата, отличающегося от 200 и 301" >> $MESSAGE
  cat $LOG | awk -v first="$REC_NO" -v last="$REC_NO_LAST" 'first <= NR && NR < last && $9 != 200 && $9 != 301' >> $MESSAGE

  echo -e "\n4) Перечень всех кодов возврата с указанием их количества" >> $MESSAGE
  cat $LOG | awk -v first="$REC_NO" -v last="$REC_NO_LAST" 'first <= NR && NR < last { ipcount[$9]++ } END { for (i in ipcount) { printf "result:%4d - %4d раз\n", i, ipcount[i]} }' | sort -nk2 >> $MESSAGE
}

# создание файла с сообщением
CreateMessageFile () {
  echo  "Имя хоста: `hostname`" > $MESSAGE
  echo "+------------------------------+" >> $MESSAGE
  CheckLog
  echo "+------------------------------+" >> $MESSAGE
}

#-------------------------------------------------
# основной код скрипта

# проверим не выставлена ли блокировка выполнения скрипта
if [[ -f $LOCK_FILE ]]; then
  echo "script watchlog.sh is already locked!" >&2
  exit 1
fi

# заблокируем повторный вызов 
touch $LOCK_FILE
# установим трап вызова очистки временных файлов на полученные сигналы  
trap "Cleanup" INT TERM EXIT

# загрузим сохраненые переменные
LoadVars

# определим номер последней записи
TOTAL_LINES=$(cat $LOG | awk 'END { print NR }')
REC_NO_LAST=$((REC_NO+RECORD_COUNT))
# при отсутсвии новых записей закончим обработку
if [[ $TOTAL_LINES < $REC_NO ]]; then
  exit 0;
fi
# проверим номер последней обрабатываемой записи
if [[ $TOTAL_LINES < $REC_NO_LAST ]]
then
  REC_NO_LAST=$((TOTAL_LINES+1))  
fi

# сформируем текст письма
CreateMessageFile
# пошлем сформированный файл почты
sudo bash /vagrant/scripts/sendemail.sh $EMAIL "Log_checking ($DATE)" $MESSAGE

# присвоим новые значения переменным
REC_NO=$REC_NO_LAST
PREV_DATE=$DATE
# сохраним переменные в файле
SaveVars

exit 0

