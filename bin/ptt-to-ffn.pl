#!/usr/bin/perl
#
# ptt-to-ffn.pl
# -------------
# Gives you the FFN FASTA header and sequence for a given PTT file line
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

use Orgmap qw(:DEFAULT $ffnfile);
&read_orgmap;

my $in;
my $a;

while (defined($in = <>)) {
  chomp($in);
  if ($in =~ /^\s*(\d+)\.\.(\d+)\s+([\+-])/) {
    if ($3 eq '+') {
      $a = "$1-$2";
    } else {
      $a = "c$2-$1";
    }
    system "chompnewline.pl $ffnfile | grep -A1 \'$a\'";
  }
}
