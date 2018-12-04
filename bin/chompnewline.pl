#!/usr/bin/perl
#
# chompnewline.pl
# ---------------
# Remove newlines from gcc.seq file.
# Final output will be >ORF# description/n sequence/n
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

my $inline;
my $need_newline = 0;

$inline = <>;
while (defined $inline && $inline =~ m/^>/) {
  chomp $inline;
  $inline =~ s/\r$//;
  print $inline, "\n";
  $need_newline = 0;
  $inline = <>;
}
if (defined $inline) {
  chomp $inline;
  $inline =~ s/\r$//;
  print $inline;
  $need_newline = 1;
}
while (defined ($inline = <>)) {
  chomp $inline;
  $inline =~ s/\r$//;
  if ($inline =~ /^>/) { 
    print "\n", $inline, "\n";
    $need_newline = 0;
  } else {
    print $inline;
    $need_newline = 1;
  }
}
print "\n" if $need_newline;
