#!/bin/bash

WORD=$1
LOG=$2
DATE=`date`

if grep -i $WORD $LOG &> /dev/null
then
  logger "$DATE: I found the word $WORD in the log $LOG, Master!"
fi
exit 0

