#!/bin/bash

# Copyright (C) Shen Hong

reader=[your reader end point]
master=[your writer end point]
d=[database id]
u=[user id]
p=[password]
cmd_v=0
n_time=`date "+%Y%m%d%H%M%S"`
while true
do
	if [ $cmd_v == 0 ]; then
		read  -n 1 -p "(r)run; (c)check; (p)prepare:" cmd_v
		echo "/n"
	fi
	if [ $cmd_v == "p" ]; then
		echo "Start to prepare the test..."
		bash -c "sysbench --mysql-host=${master} --mysql-user=${u} --mysql-password=${p} --tables=1 --table_size=0 --time=${t} --report-interval=${i}  --mysql-db=${d} --batch_inserts=${b} aurora_rr_insert prepare >> ~/prepare.${n_time}.log"

	elif [ $cmd_v == "c" ] ; then
		echo "Start to check..."
		bash -c "sysbench --mysql-host=${reader} --mysql-user=${u} --threads=50 --mysql-password=${p} --tables=1 --table_size=0 --time=${t}  --report-interval=${i} --mysql-db=${d} --batch_inserts=${b} aurora_rr_check run >> ~/check.${n_time}.log"
	else
		echo "Start to run..."
		bash -c "sysbench --mysql-host=${master} --mysql-user=${u} --threads=1 --mysql-password=${p} --tables=1 --table_size=0 --time=${t} --report-interval=${i}  --mysql-db=${d} --batch_inserts=${b} aurora_rr_insert run >> ~/run.${n_time}.log"
	fi
	rt=$?
	if [ $rt -gt 0 ]; then
		echo "Fail at $(date)"
#		sleep 1
	else
		echo "Done!"
		break
	fi

done

