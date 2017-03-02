#!/bin/bash

JOBNAME="Servername-Backup"


for f in $(echo "list jobs"| bconsole | egrep -i ${JOBNAME} | awk '{print $2}' | tr -d ","); do
	echo "delete jobid=$f" | bconsole ;
#echo $f
done
