#! /bin/sh
# example unload.sh II ax20p06::ftxp1
# PARAMETER VAIDATION etc.
#
if [ $# -ne 2 ]; then
		echo "Usage: $0 II_SYSTEM dbname"
		exit 1
fi
iisystem=$1
database=$2
# SWITCH TOCORRECT DBMS INSTALLATION
. /support/bin/switch $iisystem > /dev/null
if [ $? -ne 0 ]; then 
		exit 1
fi
ingprenv II_INSTALATION | read II_INSTALATION
ingprenv II_TEMPORARY | read II_TEMPORARY

#
# ESTABLISH targetdir
#
targetdir=/data/$II_INSTALATION/loadpackages
if [ ! -f $targetdir/.index ]; then 
	echo 0 > $targetdir/.index
fi

cat $targetdir/.index | read index
let index=index+1
echo $index > $targetdir/.index

zipfile=$targetdir/$index.$II_INSTALATION.database.tar.gz

. unloadComman.sh 

dotheunload&