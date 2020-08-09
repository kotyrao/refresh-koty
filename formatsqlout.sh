#! /bin/perl
# usage 
# sql $database <<EOF|formatsqlout.pm|read count
# select count(*) from secu where logon ='$user' and lvl=0
# \g
# EOF
my ($sqlout,$header) = (0,2)
my ($line);
for (my $ix=0; $ix<=$#ARGV; $ix++){ 
	if ($ARGV[$ix] eq "-h") {$header=1; next};
	die "USAGE: formatsqlout.pm [-h]\n"
}
while ($line=<STDIN>) {
		chomp $line;
		next if ($sqlout!=$header && $sqlout!=2 && $line!~/^\+/);
		if ($line=~/^\+/) {
			$sqlout++;
			$sqlout=0 if ($sqlout>2)
			next;	
		}
		$line =~ s/^\| *//;
		$line =~ s/ *\|$//;
		$line =~ s/\t/ /g;
		$line =~ s/ *\| */\t/g;
		print "$line\n";
}