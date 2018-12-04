#!/usr/bin/perl
#
# position.pl
# -----------
# Will ask for a "consensus sequence" one base at a time.
# Will be able to take multiple bases at each position.
# Will be search for perfect matches only, output to STDOUT.
#
# @bases is an array of the input, formatted nicely for internal use.
#        By this I mean of the form (G|A|C) for GAC or (.) for N.
# $base is just a variable used to collect input.
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
#----------------------------------
if (defined($ARGV[0]) && (($ARGV[0] eq '--help') || ($ARGV[0] eq '-h'))) {
format =
Usage: position.pl [ ORG-CODE [ INPUT_FILE ] | -h | --help ]
Give all positions of a DNA sequence within a genome.

ORG-CODE is a 4-letter code which tells the program which genome files to
        use.  Common ones are:
                ccre    Caulobacter crescentus
                ecol    Escherichia coli K12
        If no ORG-CODE is specified then ccre is assumed.

-h or --help cause this file to be printed.

Input and output are standard input and output, unless INPUT_FILE is specified.
ORG_CODE must be specified if you want to specify INPUT_FILE.
Input is of the form:
>Header_line
DNA_sequence

Where DNA_sequence is the sequence you want to search for.  This usually will
only contain G, A, T, or C, but it will also take extended one-letter
abbreviations for ambiguous bases (BDHKMNRSVWXY).  Upper and lowercase input
are both ok.

Output will print out header lines as they appear.  For each DNA_sequence
it will give you a descriptive header line followed by nucleotide positions
of exact matches to DNA_sequence.  It will indicate which strand the match is
on by a + or - before the position number.  It will always give you the
nucleotide position of the first character of DNA_sequence, whether that is
on the (+) or the (-) strand (as given by the Genbank sequence (.fna) file).
i.e. if your sequence is 5bp long, it will get an exact match at say
position 10 through 14 on the (+) strand, and say 16 through 20 on the (-)
strand.  The program will give you +10, and -20, which are the positions
of the first (5'-most) base in the sequence you entered.

.
write;
exit(0);
}
#----------------------------------

#---------------------------------------------------------
# Initialize some stuff

use Orgmap qw(:DEFAULT read_sequence $sequence);
&read_orgmap;
&read_sequence;
my $bases;
my $offset;

#---------------------------------------------------------

sub searchfor {
  my ($s) = @_;

  print STDOUT ">Matches_to_$bases"."_in_$orgcode:\n";
  while ($sequence =~ m/$s/g) {
     print STDOUT '+'.(pos($sequence)-$offset), "\n";
  }

  $s =~ tr/GATC[]/CTAG][/;                          # translate everything

  $s = reverse $s;
  while ($sequence =~ m/$s/g) {
    print STDOUT '-'.pos($sequence), "\n";
  }
}

#------------------------------------------------------------------
# Main program
#------------------------------------------------------------------

while (defined($bases = <>)) {
  if ($bases =~ /^>/) { print STDOUT $bases; next; }
  chomp $bases;
  if (length($bases) <= 0) { next; }
  $offset = length($bases) - 1;

  $bases = uc($bases);
  if ($bases =~ m/[^ACGT]/) {
    $bases =~ s/B/[CGT]/g;
    $bases =~ s/D/[AGT]/g;
    $bases =~ s/H/[ACT]/g;
    $bases =~ s/K/[GT]/g;
    $bases =~ s/M/[AC]/g;
    $bases =~ s/N/[ACGT]/g;
    $bases =~ s/R/[AG]/g;
    $bases =~ s/S/[CG]/g;
    $bases =~ s/V/[ACG]/g;
    $bases =~ s/W/[AT]/g;
    $bases =~ s/X/[ACGT]/g;
    $bases =~ s/Y/[CT]/g;
  }
  searchfor $bases;
}
