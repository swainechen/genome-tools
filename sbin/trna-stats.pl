#!/usr/bin/perl
#
# trna-stats.pl
# -------------
# run tRNAscan on a genome's .fna file.  rename the stats file and put it
# in the organism's directory.
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
use Orgmap qw(:DEFAULT $fnafile);
&read_orgmap;

my $trnafile;
my $trnastatsfile;
my $trnafna;
my $trnacommand;

# should now have $fnafile.  tRNAscan does not want the .oneline file though.
$trnafna = $fnafile;
$trnafna =~ s/\.oneline$//;

# make $trnastatsfile filename
$trnastatsfile = $fnafile;
$trnastatsfile =~ s/oneline/trna-stats/;

$trnacommand = `which tRNAscan-SE`;
if ($trnacommand ne '') {
  chomp $trnacommand;
  print "$trnacommand -G -m $trnastatsfile -q $trnafna > /dev/null\n";
  system "$trnacommand -G -m $trnastatsfile -q $trnafna > /dev/null";
}
