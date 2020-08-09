#! /bin/sh/
logfile=$PACKAGE/$1/loadpackages/4.in.log
echo running in intalation $1 >> $logfile 2>&1
destroydb -udba $2 >> $logfile 2>&1
if [ $? -ne 0 ]; then
	echo "Database $2 ($1) does not exist or can not be locked"
	exit 1
fi >> $logfile 2>$1
cd $3
mknod namepipe p
sql -s -f4F79.38 -f8F79.38 -u'"$ingres"' $2 <<EOF >> $logfile 2>&1
set session with privilages=all\p\g\t
EOF
rm namepipe
wait
echo "Optimizedb starting `date`" >> $logfile 2>&1 
optimizedb -zk -udba $2 >> $logfile 2>&1
echo "Job completed `date`;please check the log carefully!" \
							>> $logfile 2>&1


