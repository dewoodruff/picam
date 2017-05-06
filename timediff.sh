#!/bin/bash

date2stamp () {
	date --utc --date "$1" +%s
}

if [ "$1" = "abs" ]; 
then
	dte1=$(date2stamp $2)
	dte2=$(date2stamp $3)
	diffSec=$((dte2-dte1))
	if ((diffSec < 0)); then abs=-1; else abs=1; fi
	echo $((diffSec*abs))
else
	dte1=$(date2stamp $1)
	dte2=$(date2stamp $2)
	diffSec=$((dte2-dte1))
	echo $diffSec
fi
