#!/usr/bin/perl -w
#
# subseq.pl
# ---------
# input will be start_position <whitespace> length
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

# Help section
#-----------------------------------
if (defined($ARGV[0]) && (($ARGV[0] eq '--help') || ($ARGV[0] eq '-h'))) {
format =
Usage: subseq.pl [ ORG-CODE [ INPUT_FILE ] | -h | --help ]
Pull out a subsequence from a particular genome sequence, starting at a
specified nucleotide position.

ORG-CODE is a 4-letter code that specifies which genome files to use.  If
	omitted, ccre is the default.

-h or --help causes this help to be printed.

Input and output are from standard input and output, unless INPUT_FILE is
specified.  You must specify ORG-CODE if you want to specify INPUT_FILE.
Input is of the form
>Header_line
[+|-]n	[+|-]m

where n is the starting nucleotide position, and m is the length of the
sequence you're interested in.  The [+|-] indicates which strand you want.
If one or the other of n and m are negative, you get the negative strand.
If both are + or both are - then you get the positive strand.

** NOTE **
This means that you cannot use n = 0.  Also, n = -1 does not mean the
next to last position in the genome.  n = -1 means position 1, (-) strand.
**********

Header lines are printed as they are entered.  Output consists of a
descriptive header indicating n and m, followed by the sequence on the
appropriate strand (as set by the Genbank sequence (.fna) file).

.
write;
exit(0);
}
#-----------------------------------
#
# load module

use Orgmap qw(:DEFAULT read_sequence subseq $topology $sequence);
&read_orgmap;
&read_sequence;

my $genome_length = length($sequence);
my $in;
my $instart;
my $inlength;

while (defined($in = <>)) {
  if ($in =~ m/^>/) { print STDOUT $in; next; }
  chomp $in;
  if ($in =~ m/(\d+)\.\.(\d+)/) {
    $instart = $1;
    if ($1 < $2) {
      $inlength = $2 - $1 + 1;
    } else {
      $inlength = $2 - $1 - 1;
    }

    # try to be a little smart about this
    # if you have a circular chromosome and your length is negative, could
    # be one of two things: you want + strand but wrapped around the start
    # you want the - strand.  Hopefully, in both cases, you will be asking for
    # less than half the genome, i.e. your two coordinates will be in the same
    # half of the genome.  That's how this will cut if off, anyway.
    if ($inlength < -$genome_length/2 && $topology == 0) {
      $inlength += $genome_length;
    }

  } else {
    ($instart, $inlength) = split /\s+/, $in;
  }
  if (defined($inlength)) {
    print STDOUT ">$inlength"."_bases_at_position_$instart"."_in_$orgcode\n" . subseq ($instart, $inlength) . "\n";
  }
}
