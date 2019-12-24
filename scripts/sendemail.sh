#!/bin/bash

# Адресат
TO=$1
# Тема письма
SUBJECT=$2
# Файл, в котором сохранен текст письма.
MESSAGE=$3

# Отсылка письма 
mail -s "$SUBJECT" "$TO" < $MESSAGE

