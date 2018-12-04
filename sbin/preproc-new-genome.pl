#!/usr/bin/perl
#
# preproc-new-genome.pl
# ---------------------
# script to handle new genbank bacterial genomes.
# need to:
# 1. chompnewline for .fna, .ffn, .faa files
# 2. check if there are any rnatab files (needs to have 'rnatab' in the name
#      and no 'ptt' in the name).  If there are, convert them to 
#      .ptt.others files using rnatab-to-ptt.  This should get them included
#      by ptt-sanemaker.  Then check if there is a .ptt preprocessing script
#      (foo.ptt-sanemaker.pl) in the directory.  Backup the original genbank
#      file, then run the ptt-sanemaker.pl script.
# 3. run intergenic.pl on .fna file
# 4. run gatc.pl on .fna, .ffn files
# 5. run codonuse.pl on .ffn file, trna-stats.pl on .fna file
# 6. run formatdb on .fna, .ffn, .faa files so you can blast
#
# this should generate the following new files, assuming a filename of foo:
# 1. foo.fna.oneline
#    foo.ffn.oneline
#    foo.faa.oneline
# 2. *rnatab*.ptt.others
#    foo.ptt.genbank-original (made by ptt-sanemaker.pl)
# 3. foo.intergenic
# 4. foo.fna.gatc
#    foo.ffn.gatc
# 5. foo.ffn.codonusage
#    foo.fna.trna-stats
# 6. formatdb.log
#    foo.fna.nhr/nin/nsq
#    foo.ffn.nhr/nin/nsq
#    foo.faa.phr/pin/psq
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

if (not $ARGV[0]) { die "No ORG-CODE given\n"; }
use Orgmap qw(:DEFAULT $fnafile $ffnfile $faafile $pttfile $straindir $accession $BINPATH $SBINPATH $ROOTPATH);
&read_orgmap;

my $TOOLDIR = "$BINPATH/";
my $STOOLDIR = "$SBINPATH/";
my $gbfna;
my $gbffn;
my $gbfaa;
my $lspath;
my $file;
my @rnatabs;
my $sanemaker;
my $saneptt;
my $fnainter;
my $fnagatc;
my $ffngatc;
my $ffncodon;
my $fdbpath;

# Task 1. chompnewline for .fna, .ffn, .faa files
# $fnafile, $ffnfile, $faafile all have a '.oneline' appended already
# $pttfile doesn't have anything appended
print "Task 1. chompnewline for .fna, .ffn, .faa files\n";

$gbfna = $fnafile;
$gbfna =~ s/\.oneline$//;
$gbffn = $ffnfile;
$gbffn =~ s/\.oneline$//;
$gbfaa = $faafile;
$gbfaa =~ s/\.oneline$//;

print  $TOOLDIR."chompnewline.pl < $gbfna > $fnafile\n";
system $TOOLDIR."chompnewline.pl < $gbfna > $fnafile";
print  $TOOLDIR."chompnewline.pl < $gbffn > $ffnfile\n";
system $TOOLDIR."chompnewline.pl < $gbffn > $ffnfile";
print  $TOOLDIR."chompnewline.pl < $gbfaa > $faafile\n";
system $TOOLDIR."chompnewline.pl < $gbfaa > $faafile";

print "\n";

# Task 2. check for rnatab files and deal with them
# i.e. if there are rnatab files run rnatab-to-ptt.pl on them.
# if there is no .ptt.genbank-original then copy the .ptt file to it.
# if there is either at least one rnatab file then run mergeptt.pl.
print "Task 2. check for rnatab files and deal with them\n";

$lspath = `which ls`;
chomp $lspath;
@rnatabs = `$lspath -1 $straindir | grep rnatab | grep $accession | grep -v ptt`;
foreach $file (@rnatabs) {
  chomp $file;
  print  $STOOLDIR."rnatab-to-ptt.pl $orgcode '$straindir/$file' > '$straindir/$file".".ptt.others'\n";
  system $STOOLDIR."rnatab-to-ptt.pl $orgcode '$straindir/$file' > '$straindir/$file".".ptt.others'";
}

if (!-e $pttfile.".genbank-original") {
  print "No .ptt.genbank-original file found, backup up .ptt\n";
  if (-e $pttfile) {
    print  "mv $pttfile $pttfile".".genbank-original\n";
    system "mv $pttfile $pttfile".".genbank-original";
  }
  else { print "No .ptt file found!\n"; }
}
$sanemaker = $pttfile."-sanemaker.pl";
$saneptt = $pttfile.".sane";

if (-e $sanemaker) {
  chdir $straindir;
  print  "$sanemaker < $pttfile".".genbank-original > $saneptt\n";
  system "$sanemaker < $pttfile".".genbank-original > $saneptt";
  print  $STOOLDIR."mergeptt.pl $orgcode\n";
  system $STOOLDIR."mergeptt.pl $orgcode";
}
elsif (scalar @rnatabs > 0) {
  print  $STOOLDIR."mergeptt.pl $orgcode\n";
  system $STOOLDIR."mergeptt.pl $orgcode";
}
else {
  system "cp $pttfile".".genbank-original $pttfile";
}

print "\n";

# Task 3. run intergenic.pl on .fna file
print "Task 3. run intergenic.pl on .fna file\n";

$fnainter = $gbfna.".intergenic";
print  $TOOLDIR."intergenic.pl $orgcode > $fnainter\n";
system $TOOLDIR."intergenic.pl $orgcode > $fnainter";

print "\n";

# Task 4. run gatc.pl on .fna, .ffn files
print "Task 4. run gatc.pl on .fna, .ffn files\n";

$fnagatc = $gbfna.".gatc";
$ffngatc = $gbffn.".gatc";
print  $TOOLDIR."gatc.pl < $fnafile > $fnagatc\n";
system $TOOLDIR."gatc.pl < $fnafile > $fnagatc";
system "echo '>All_coding_regions_of_$orgcode' >> $fnagatc";
print  "grep -v '>' $gbffn | $TOOLDIR"."chompnewline.pl | $TOOLDIR"."gatc.pl >> $fnagatc\n";
system "grep -v '>' $gbffn | $TOOLDIR"."chompnewline.pl | $TOOLDIR"."gatc.pl >> $fnagatc";
system "echo '>All_intergenic_regions_of_$orgcode' >> $fnagatc";
print  "grep -v '>' $fnainter | $TOOLDIR"."chompnewline.pl | $TOOLDIR"."gatc.pl >> $fnagatc\n";
system "grep -v '>' $fnainter | $TOOLDIR"."chompnewline.pl | $TOOLDIR"."gatc.pl >> $fnagatc";
print  $TOOLDIR."gatc.pl < $ffnfile > $ffngatc\n";
system $TOOLDIR."gatc.pl < $ffnfile > $ffngatc";

print "\n";

# Task 5. run codonuse.pl on .fna file, trna-stats.pl on .fna file
print "Task 5. run codonuse.pl on .fna file, trna-stats.pl on .fna file\n";

$ffncodon = $gbffn.".codonusage";
print  $TOOLDIR."codonuse.pl < $ffnfile > $ffncodon\n";
system $TOOLDIR."codonuse.pl < $ffnfile > $ffncodon";
system $STOOLDIR."trna-stats.pl $orgcode";

print "\n";

# Task 6. run formatdb on .fna, .ffn, .faa
print "Task 6. run formatdb on .fna, .ffn, .faa\n";

$fdbpath = `which formatdb`;
chomp $fdbpath;
if ($fdbpath ne '') {
  chdir $straindir;
  print  $fdbpath." -i $gbfna -p F\n";
  system $fdbpath." -i $gbfna -p F";
  print  $fdbpath." -i $gbffn -p F\n";
  system $fdbpath." -i $gbffn -p F";
  print  $fdbpath." -i $gbfaa -p T\n";
  system $fdbpath." -i $gbfaa -p T";
}
 
