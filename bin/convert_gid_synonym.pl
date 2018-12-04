#!/usr/bin/perl
#
# convert_gid_synonym.pl
# ----------------------
# This file takes either a GenBank ID or a GenBank Synonym (i.e. CCXXXX,
# bXXXX, etc...) and converts it to the other one.
# Reads from standard input, runs in N^2 time where N is the number of
# input IDs, basically because we don't preprocess the input.
#
# only tested with E. coli and C. crescentus 10/9
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
use Orgmap qw(:DEFAULT $pttfile $genefield $gidfield);
read_orgmap();

# variables
my @ptt;
my $input;
my @pttrow;
my $i;

open (PTT, $pttfile);
@ptt = <PTT>;
close (PTT);

while(defined($input = <STDIN>)) {
  chomp($input);
  for ($i = 0; $i < scalar(@ptt); $i++) {
    @pttrow = split(/\t/, $ptt[$i]);
    if (scalar(@pttrow) >= 5) {
      if ($input eq $pttrow[$genefield]) {
        print "$pttrow[$gidfield]\n";
        last;
      }
      if ($input eq $pttrow[$gidfield]) {
        print "$pttrow[$genefield]\n";
        last;
      }
    }
  }
}
