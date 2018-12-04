#!/usr/bin/perl
#
# get_fasta.pl
# ------------
# This program simply takes an ID of some sort (like the GenBank PID)
# and goes into a fasta formatted file to find a sequence associated
# with that ID. If the ID is non-unique, returns only the first hit.
#
# Runs in N^2 time where N is number of input IDs.
# Could be better if we wanted to preprocess the whole fasta file
# and store it into memory in a hash or some such, but that makes
# this less flexible since there could only be 1 key used to search.
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

if (scalar(@ARGV) < 1) {
  print "Usage: ./get_fasta.pl <fasta file>\n";
  print "  Then enter ID #'s into standard input.\n";
  exit(-1);
}

my @infile;
my $input;
my $i;

open(INFILE, $ARGV[0]) || die "Could not open $ARGV[0]";
@infile = <INFILE>;
close(INFILE);

while (defined($input = <STDIN>)) {
  chomp ($input);
  for ($i = 0; $i < scalar(@infile); $i++) {
    if ($infile[$i] =~ /^>.*$input.*$/) {
      print "$infile[$i]";
      
      for ($i++; !($infile[$i] =~ /^>/) && ($i < scalar(@infile)); $i++) {
        print "$infile[$i]";
      }
      last;
    }
  }
}
