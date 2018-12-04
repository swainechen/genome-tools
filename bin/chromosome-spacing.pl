#!/usr/bin/perl
#
# chromosome-spacing.pl
# ---------------------
# This program does some chromosome spacing stuff
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

use warnings;
use strict;
use Orgmap qw(:DEFAULT read_sequence $sequence $seqlength $pttfile $topology $genefield);
&read_orgmap;
&read_sequence;

use Getopt::Long;
&Getopt::Long::Configure("pass_through");

my $input = '';
my @results = ();
my @infile;
my $orf;
my ($found, $centisomes, $low, $high, $strand);
my $pttline;
my @pttArray;
my @pttPosition;
my $i;
my $gene;

GetOptions ('input=s' => \$input);

if (!$input || !-e $input) {
  print "Usage: chromosome-spacing.pl ORG-CODE -i <input file>\n";
  print "  - Input File should have 1 gene (systematic name) per line\n";
  exit(-1);
}

open(INFILE, $input) || die "Could not open $input for reading.";
@infile = <INFILE>;
close(INFILE);

# First, find and calculate the positions for each of the genes
foreach $orf (@infile) {
  chomp($orf);

  ($found, $centisomes, $low, $high, $strand) = (0,0,0,0,0);
  open(PTTFILE, $pttfile);
  while (defined($pttline = <PTTFILE>)) {
    next if $pttline !~ m/^\s*?\d+\.\.\d+/;
    @pttArray = split /\t/, $pttline;
    $pttArray[0] =~ s/^\s*//;
    @pttPosition = split /\.+/, $pttArray[0];
    if ($pttArray[$genefield] =~ /$orf/) {
      $found = 1;
      ($centisomes, $low, $high, $strand) = (sprintf("%.2f", 100 * ($pttPosition[0]/$seqlength)), $pttPosition[0], $pttPosition[1], $pttArray[1]);
      push @results, [$orf, $centisomes, $low, $high, $strand, 0];
      last; # stop reading the file once you find the gene
    }
  }
  close(PTTFILE);
}

# Second, calculate the intervening space between the genes
@results = sort {@$a[1] <=> @$b[1]} @results;
for ($i = 1; $i < scalar(@results); $i++) {
  $results[$i][5] = $results[$i][2] - $results[$i - 1][3];
}
# First gene is a special case (do wrap-around calculations)
if ($topology == 0) {
  $results[0][5] = $results[0][2] + ($seqlength - $results[scalar(@results) - 1][3]);
} elsif ($topology == 1) {
  $results[0][5] = $results[0][2] - 1;
}

# Last, output everything
print "Gene\tCentisomes\tLow Coord\tHigh Coord\tStrand\tDistance from Prev\n";
foreach $gene (@results) {
  print join("\t", @$gene), "\n";
}
