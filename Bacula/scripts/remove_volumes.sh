#!/bin/bash

VOLUME="volume-servername"

for f in $(echo "list volume" | bconsole | egrep -i ${VOLUME} | awk '{print $4}' | egrep -v "^$"); do
	echo "delete volume=$f yes" | bconsole;
#	echo "delete volume=$f yes"

done
