#!/usr/bin/perl
#
# gatc.pl
# -------
# will take input and tell you how many g, a, t, and c's you have, and percent
# also will print out % GC
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
format=
Usage: gatc.pl [-h|--help] [INPUT_FILE]
Calculate nucleotide content of a given DNA sequence.

Input and output are taken from standard input and output, unless INPUT_FILE
is specified.
Input is FASTA format, i.e. a header line starting with '>'
then the sequence following.  For example,

>My_DNA_sequence
GCCATCGACGATC

Output will be any header lines followed by the number and percent of
G, A, T, and C content in the sequence.  The last line is number and percent
of GC content.  Any invalid letters will be ignored and will not affect
the percentages, but will be reported in the last line as discarded.

.
write;
exit(0);
}
#-----------------------------------

# variables
my $in;
my %base;
my $discard;
my $len;
my $ch;
my $k;
my $lenorig;

while (defined($in = <>)) {
  %base = ( 'G'=>0, 'A'=>0, 'C'=>0, 'T'=>0 );
  if ($in =~ /^>/) {
    print STDOUT $in;
  }
  else {
    chomp $in;
    $lenorig = length $in;
    $in =~ tr/a-z/A-Z/;
    $discard = $in =~ tr/GATC//cd;
    $len = $lenorig - $discard;
    $base{'G'} = $in =~ tr/G//;
    $base{'A'} = $in =~ tr/A//;
    $base{'T'} = $in =~ tr/T//;
    $base{'C'} = $in =~ tr/C//;
    if ($len > 0) {
      foreach $k (sort keys %base) {
         print STDOUT $k, "\t", $base{$k}, "\t", sprintf("%.2f", 100*($base{$k}/$len)), "\n";
      }
      print STDOUT "GC\t", $base{'G'}+$base{'C'}, "\t", sprintf("%.2f", 100*(($base{'G'}+$base{'C'})/$len)), "\n";
    } else {
      foreach $k (sort keys %base) {
         print STDOUT $k, "\t", $base{$k}, "\t", sprintf("%.2f", 0), "\n";
      }
      print STDOUT "GC\t", $base{'G'}+$base{'C'}, "\t", sprintf("%.2f", 0), "\n";
    }
    print STDOUT "Non-'GATC' characters, discarded: $discard (", sprintf("%.2f", 100*($discard/$lenorig)), "% of original input)\n";
  }
}
