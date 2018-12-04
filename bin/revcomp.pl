#!/usr/bin/perl
#
# revcomp.pl
# ----------
# Reverse sequence and translate subroutine
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
# Help section
#-----------------------------------
use warnings;
use strict;

if (defined($ARGV[0]) && (($ARGV[0] eq '--help') || ($ARGV[0] eq '-h'))) {
format =
Usage: revcomp.pl [ -h | --help ] [ INPUT_FILE ]
Print the reverse complement of a given DNA sequence.

-h or --help causes this help to be printed.

Input and output are from standard input and output, unless INPUT_FILE is
specified.
Input is of the form 
>Header_line
DNA_sequence

Header lines are printed as they are entered.  For printing the reverse
complement, each line of DNA_sequence is considered a different sequence,
so to get the reverse complement of a long sequence be sure that no
intervening newline characters are present.  Upper- and lower-case sequences
are ok, and case will be preserved in the output.  G, A, T, C are ok, as well
as the extended single-letter abbreviations for multiple nucleotides (i.e.
n or N = GATC, y or Y = CT).

.
write;
exit(0);
}

#-----------------------------------
#
# load module 

use Orgmap qw(revcomp);

my $inline;

while ($inline = <>) {
  chomp($inline);
  if ($inline =~ /^>/) { print STDOUT $inline, "\n"; }
  else {
    print STDOUT revcomp ($inline) . "\n";
  }
}
