#!/usr/bin/perl
#
# mergeptt.pl
# -----------
# will merge other-annotation file with original genbank .ptt file.
# have to sort the locations for compatibility
#
#  Copyright (C) 2002 Swaine Chen and William Lee
#
#  This program is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 2 of the License, or
#  (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program; if not, write to the Free Software
#  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#
use warnings;
use strict;

if (not $ARGV[0]) { die "No ORG-CODE specified.\nUsage: mergeptt.pl ORG-CODE\n"; }
use Orgmap qw(:DEFAULT $pttfile $straindir $accession);
&read_orgmap;

my $temp;
my $origptt;
my $lspath;
my @others;
my $i;
my $in;
my $file;

$temp = $pttfile;
$temp =~ s/\.ptt$//;
$origptt = $temp.'.ptt.genbank-original';

$lspath = `which ls`;
chomp $lspath;
@others = `$lspath -1 $straindir/$accession.*.ptt.others`;

if (!(-e $pttfile) && !(-e $origptt)) { die "I can't find the base .ptt file\n"; }
if (!(-e $origptt)) {
  print "Backing up your original .ptt file\n";
  system "mv $pttfile $origptt";
}

open (ORIG, $origptt);
open (OUT, '>'.$pttfile);

$i = 1;
while ($in = <ORIG>) {
  last if $in =~ /^\s*\d+\.\.\d+/;	# stop if get to valid ptt lines
  print OUT $in;
  $i++;
}
close ORIG;
close OUT;

#system "tail +6 $origptt > mergeptt.temp.file";
system "tail -n +$i $origptt > mergeptt.temp.file";
foreach $file (@others) {
  chomp $file;
  system "cat '".$file."' >> mergeptt.temp.file";
}
system "sort -n mergeptt.temp.file >> $pttfile";
system "rm mergeptt.temp.file";
