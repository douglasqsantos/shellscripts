#!/bin/bash

for f in $(cat "list.txt"); do
	echo "delete jobid=$f" | bconsole ;
#echo $f
done
