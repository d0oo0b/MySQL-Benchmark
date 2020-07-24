#!/bin/bash
reader=database1-aurora-1-cluster.cluster-ro-clahnijqri5x.ap-northeast-1.rds.amazonaws.com
master=database1-aurora-1-cluster.cluster-clahnijqri5x.ap-northeast-1.rds.amazonaws.com
d=test
u=admin
p=1qaz2WSX
i=20
t=18000
b=100
cmd_v=0
n_time=`date "+%Y%m%d%H%M%S"`
while true
do
#        echo -n "count $j : "
#        num=$(od -A n -t d -N 1 /dev/urandom |tr -d ' ')
#	timeout 1 bash -c "mysql -u${_user} -p${_pass} -h${_host} -P${_port} --connect-timeout=1 --disable-reconnect -A -Bse \
#        \"UPDATE ${d}.sbtest1 SET k = $num WHERE id = 1\" > /dev/null 2> /dev/null"
#        if [ $? -eq 0 ]; then
#                echo "OK $(date)"
#        else
#                echo "Fail ---- $(date)"
#        fi
#        j=$(( $j + 1 ))
#        sleep 1
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

