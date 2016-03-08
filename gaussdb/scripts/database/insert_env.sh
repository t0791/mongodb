#!/bin/bash

user=$1
port=$2
userApimgtdbPassword=$3

doc="/opt/gaussdb/configure/properties.xml"
xmlContent=`awk 'BEGIN{FS="[<>]";OFS=" ";ORS="|"}/property/{print $2,"value="$3}' $doc`

OLDIFS=$IFS;IFS='|';
for kkk in $xmlContent
do
   line=`echo $kkk | awk 'BEGIN{OFS="\n";}{print $2,$3,$4}'`
   name=`echo $line | awk -F"[=\"]" '/name=/{print $3}'`
   readonly=`echo $line | awk -F"[=\"]" '/readonly=/{print $3}'`
   value=`echo $line | awk -F"[=\"]" '/value=/{print $2}'`
   echo $value
  if [ -n "$readonly" ]; then
    if [ "${readonly}" == "true" ]; then 
      readonly="1"
    else
      readonly="0"
    fi
  else
    readonly="0"
  fi
   #generate sql
  if [ -n "$value" ]; then
    sql="INSERT INTO AM_ENV(NAME, VALUE, READONLY) VALUES('"$name"', '"$value"', '"$readonly"');"
  else
    sql="INSERT INTO AM_ENV(NAME, READONLY) VALUES('"$name"', '"$readonly"');"
  fi
  db_command='gsql -d WSO2AM_DB -U apimgtdb -W '$userApimgtdbPassword' -p '$port' -c "'$sql'" >> /dev/null 2>&1'
  echo $db_command
  su - $user -c "$db_command" >> /dev/null 2>&1
done
IFS=$OLDIFS
