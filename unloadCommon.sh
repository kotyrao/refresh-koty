dotheunload () {
#
#SET UP WORKING ENVIRONMENT
#
if [ ! -d $II_TEMPORARY/unload ]; then
	mkdir $II_TEMPORARY/unload
fi
who am i  | read whoamireally xxx
export UNLOADDIR=$II_TEMPORARY/unoad/${whoamireally}_$$
trap 'cd;rm -fr UNLOADDIR' 0
mkdir $UNLOADDIR
mkdir $UNLOADDIR/data
#
# USE unloaddb AS TEMPLATE
#
cd $UNLOADDIR
unloaddb $database -udba -d. -source=./data -dest=./data \
	     >> $targetdir/$index.out.log 2>&1
		 
#
# MODIFIED copy.out FORMS BASICS of unloaddb.sh
# this awk script takes the unloaddb's copy.out and modifies it so that we
# can copy the data out to a name pipe instead of file, then the data in
# that named pipe can be compressed before writing to an actual file
sed -e's/\\p\\g/\\p\\g\\t/g' copy.out | awk -v unloaddir=$UNLOADDIR \
											-v database=$database \
											-v targetdir=$targetdir \
											-v logindex=$index '
BEGIN {
	print "#! /bin/sh";				#standerd hash-bang to start off the script 
	print "cd " unloaddir;			# work out of temporary directory
	auth = "?";						#unauthorised value
	mknod = "mknod namedpipe p";	#command to create the named pipe
	rmnod = "rm namedpipe";			#command to remove the named pipe
	eof = "\\p\\g\\t\nEOF";			#command to terminate the sql session
	# command to commance an sql session:-
	sqltemplate = "sql -s -f4F79.38  -f8F79.38 -u'\''%s'\'' " database <<EOF
	sqltemplate = sqltemplate " >> " targetdir "/" logindex ".out.log 2>&1 &"
	sqltemplate = sqltemplate "\n\\p\\g\\t\n"
}
# at the session authorization, remember the auth userid and skip this & 1 line
/set session authorization / {
	auth = $4;
	seqn = -1;
	next;
}
# if auth userid not yet set then skip
auth == "?" {next}
# skip 1st line after auth is set (\p\g)
seqn == -1 { seqn++; next }
# first line after a skip ...
auth !=dba && auth != "\"$ingres\"" && auth != "ingres" && seqn == 0 { next }
seqn == 0 {
		print mknod; 				# make the named pipe 
		printf(sqltemplate,auth);   # open the sql session, set authority 
		tablename = $2;				# save the table name
		# copy  table out into a named pipe:-
		print "copy " $2 " () into '\''" unloaddir "/namedpipe'\''";
		seqn++; next;
}


#
seqn == 1 {
		print eof;		# close the sql session
		# compressed the data in the named pipe out to a file:-
		print "gzip < namedpipe > data/" tablename ".dat.gz 
		print rmnod;
		seqn = 0;
}
' > $UNLOADDIR/unloaddb.sh

# set permission on newly created script, ready to run.
chmod 555 $UNLOADDIR/unloaddb.sh

#    ... run it 
$UNLOADDIR/unloaddb.sh

#
# Now create the script to reload that data
#
cat copy.in | sed -e's/\\p\\g/\\p\\g\\t/g' | awk -v logindex=$index '
BEGIN {
	print "#! /bin/sh";
	print "logfile=$/$1/loadpackages/" logindex ".in.log"
	print "echo Running in installation $1 >> $logfile 2>&1"; # runtime info
	print "destroydb -udba $2 >> $logfile 2>&1"; #destroy existing database
	# if database cannot be destroyed for any reason, fail out
	print "if [ $?-ne 0 ]; then";
	print "		echo \"Database $2 ($1) does not exists or can not be locked\"";
	print "		exit 1";
	print "fi >> $logfile 2>&1";
	print "createdb -udba $2 >> $logfile 2>&1"; # Recreate empty database
	print "cd $3";								# relocate to our wworking directory 
	mknod = "mknod namedpipe p";				
	rmnod = "rm namedpipe";
	eof = "\\p\\g\\t\nEOF";
	# instruction to commence an sql session
	sqltemplate = "sql -s -f4F79.38 -f8F79 -u'\''%s''\'' $2 <<EOF;
	sqltemplate = sqltemplate "\nset session with privileges=all\\p\\g\\t\n";
	print mknod;
	printf(sqltemplate,"\"$ingres\"");
}

# remember auth userid when it changes
/set session authorization /{auth = $4}
# skip if authorization is not a core user 
auth !=dba && auth != "\"$ingres\"" && auth != "ingres" { next }
# on a "copy from" line, be sure to copy from the named pipe
/^copy /{
	tablename=$2;
	copyline = "copy " tablename " () from '\'namedpipe\''";
	skip=1;
	next;
}
# if in skip-mode and not reached \p]g then add the lione to buffer
skip == 1 && ! /^\\p\\g/ {
	copyline=copyline "\n" $0;
	next;
}

skip == 1 {
	print copyline;
	print eof;
	print "gunzip < data/" tablename ".dat.gz >  namedpipe"
	print "wait"
	print rmnod;
	print mknod;
	printf(sqltemplate,auth);
	skip = 0;
	next;
}
{
	sub(/\$/,"\\\$");
	print;
}
END {
	print "EOF";
	print rmnod;
	print "wait";
	print "optimizedb -zk -udba $2 >> $logfile 2>&1";
	print "\t\t>> $logfile 2>&1";
}
' > reloaddb.sh

chmod 555 reloaddb.sh

gtar czvf $zipfile reloaddb.sh data \
			>> $targetdir/$index.out.log 2>&1
date >> $targetdir/$index.out.log 2>&1
}