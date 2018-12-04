#!/usr/bin/perl
#
# print-genome-file.pl
# --------------------
# This script will take an orgcode and an argument and will print
# a given genome output file.
# e.g. intergenics, gatc content, codon usage
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

if ((!defined $ARGV[0]) || ($ARGV[0] eq '-h') || ($ARGV[0] eq '--help')) {
  print STDOUT "Usage: print-genome-file.pl orgcode -suffix filesuffix\n";
  exit;
}

use Orgmap qw(:DEFAULT $fileprefix);
&read_orgmap;

use Getopt::Long;
&Getopt::Long::Configure("pass_through");
my $suffix = '';
GetOptions('suffix=s' => \$suffix);

my $filename = $fileprefix . "." . $suffix;
my $line;

if (-e $filename) {
  open(INFILE, $filename);
  while(defined($line = <INFILE>)) {
    print $line;
  }
  close(INFILE);
}
