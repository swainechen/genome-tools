#!/usr/bin/perl -w
#
# surround.pl
# -----------
# input will be middle_position <whitespace> length
# output will have a header line marked by ">" then sequence on next line
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

# Help section *****Removed by Ji due to syntax highlighting issues.
# Please insert:
#-----------------------------------

#---------------------------------------------------------
# Initialize some stuff

use Orgmap qw(:DEFAULT read_sequence subseq revcomp);
&read_orgmap;
&read_sequence;

my $in;
my $middle;
my $length;
my $strand;
my $leftLength;
my $rightLength;
my $seqtorev;
my $seq1;
my $seq2;
my $revseq;
my $outseq;
my $outlength;

#---------------------------------------------------------


while (defined($in = <>)) {
  if ($in =~ '^>') { print $in; next; }
  chomp $in;
  
  ($middle, $length) = split /\s+/, $in;
  if (!defined($middle) || !defined($length)) { next; }
  if ($length < 0) {
    print STDOUT ">Out_of_range:length=$length"."_is_negative\n";
    next;
  }
  $strand = '+';
  if ($middle < 0) { $middle = -$middle; $strand = '-'; }
  else { $middle =~ s/^\+//; }	# get rid of leading + if it's there
  $leftLength = int($length/2) + 1;
  $rightLength = $length - $leftLength + 1;
  
  $seqtorev = subseq ($middle, -$leftLength);
  $seq1 = revcomp ($seqtorev);
  $seq2 = subseq ($middle, $rightLength);

  chomp($seq1);
  chop($seq1);
  chomp($seq2);
  
  $outseq = $seq1 . $seq2;
  $outlength = length $outseq;
  print STDOUT ">$outlength"."_bases_surrounding_$strand$middle"."_in_$orgcode\n";
  if ($strand eq '-') {
    $revseq = revcomp ($outseq);
    print STDOUT "$revseq\n";
  } else {
    print STDOUT "$outseq\n";
  }
}

