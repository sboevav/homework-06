VARS_FILE=~/linux/homework-06/scripts/vars

# Считывание сохраненных переменных из файла
# Допускается формат хранения:
#  - просто значение в строке (например 12)
#  - значение с указанием имени переменной (например var1=12)
LoadVars () {
  # Считываем весь файл в массив
  i=0 
  while IFS='' read -r line; do 
    v[$i]=$(echo ${line} | cut -f2 -d'=') 
    ((i++))
  done < "$VARS_FILE"
  # Распределяем массив по переменным
  REC_NO=${v[0]}
  var2=${v[1]}
  var3=${v[2]}
}

# Сохранение переменных в файл
# Значения необходимо сохранять с указанием имени переменной (например var1=12)
SaveVars () {
  echo "REC_NO=$REC_NO" > $VARS_FILE
  echo "var2=$var2" >> $VARS_FILE
  echo "var3=$var3" >> $VARS_FILE
}

LoadVars

echo ${v[0]}
echo ${v[1]}
echo ${v[2]}

echo "REC_NO=$REC_NO"
echo "var2=$var2"
echo "var3=$var3"

REC_NO=$((REC_NO+1))
SaveVars

exit 0

