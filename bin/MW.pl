#!/usr/bin/perl
#
# MW.pl
# -----
# calculate molecular weight of fasta sequence.
# take molecular weight values from
# http://psyche.uthct.edu/shaun/SBlack/aagrease.html
# but subtract 18 from each for water
#
# will respect fasta format, so spit back out the header lines
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

# Help section
#-----------------------------------
if (defined($ARGV[0]) && (($ARGV[0] eq '--help') || ($ARGV[0] eq '-h'))) {
format =
Usage: MW.pl [ -h | --help ] [ INPUT_FILE ]
Calculate the molecular weight of a given FASTA sequence.

Input and output are taken from standard input and output, unless INPUT_FILE
is specified.
Input is FASTA format, i.e. a header line starting with '>'", 
then the sequence following.  For example,

>My_protein_sequence
ACHKLEFMPYSM

Output will be any header lines followed by the molecular weight of the
sequence following.  Sequence must be on one line.  Sequence must use one-
letter amino acid abbreviations.  Invalid amino acid codes will be ignored.

.
write;
exit(0);
}
#-----------------------------------


use vars qw($A $C $D $E $F $G $H $I $K $L $M $N $P $Q $R $S $T $V $W $Y);
my $in;
my $mw;
my $letter;
my $residue;
my %mass;

foreach $letter ("A".."Z") {
  $mass{$letter} = 0;
}

$mass{A} = 71.09;
$mass{C} = 103.16;
$mass{D} = 115.10;
$mass{E} = 129.13;
$mass{F} = 147.19;
$mass{G} = 57.07;
$mass{H} = 137.16;
$mass{I} = 113.18;
$mass{K} = 128.19;
$mass{L} = 113.18;
$mass{M} = 131.21;
$mass{N} = 114.12;
$mass{P} = 97.13;
$mass{Q} = 128.15;
$mass{R} = 156.20;
$mass{S} = 87.09;
$mass{T} = 101.12;
$mass{V} = 99.15;
$mass{W} = 186.23;
$mass{Y} = 163.19;

while (defined($in = <>)) {
  if ($in =~ /^>/) {
    print STDOUT $in;
    $in = <>;
  }
  chomp $in;
  $in =~ tr/a-z/A-Z/;
  $in =~ tr/A-Z//cd;		# get rid of any non-letters
  $mw = 0;
  while ($residue = chop $in) {
    $mw += $mass{$residue};
  }
  print STDOUT $mw, "\n";
}
