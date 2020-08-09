#! /bin/sh
#
# Parameter validation etc
#
if [ $# -ne 3 ];then 
	echo "Useage: $0 II_SYSTEM dbname loadpakage"
	exit 1
fi
iisystem=$1
database=$2
loadpack=$3
. /support/bin/switch $iisystem
if[ $? -ne 0]
	exit 1
fi
ingprenv II_INSTALATION | read II_INSTALATION
ingprenv II_TEMPORARY | read II_TEMPORARY
basename $loadpack | cut -d\. -f1 | read index 
logfile=/data/$II_INSTALATION/loadpakages/$index.in.log
if [ -f $logfile ]; then 
	if [ -f /data/$II_INSTALATION/loadpakages/.$index.$index ]; then 
		cat /data/$II_INSTALATION/loadpakages/.$index.$index | read ix
		let ix=$ix+1
	else 
		ix=1
	fi
	echo $ix > /data/$II_INSTALATION/loadpakages/.$index.$index
	mv $logfile /data/$II_INSTALATION/loadpakages/$index.$ix.in.log 
fi
date >> logfile
#
#Set up the environment 
#
if [ ! -d $II_TEMPORARY/unoad ]; then 
	mkdir $II_TEMPORARY/unoad
fi
who am i  | read whoamireally xxx
export UNLOADDIR=$II_TEMPORARY/unoad/${whoamireally}_$$
#trap 'rm -f $UNLOADDIR' 0
mkdir $UNLOADDIR
cd $UNLOADDIR 
echo "your logfile is:\n\t\$ogfile"
backgrounded () {
gtar xvf $loadpack >> $logfile 2>&1
./reloaddb.sh $II_INSTALATION $database $UNLOADDIR
}
backgrounded &
