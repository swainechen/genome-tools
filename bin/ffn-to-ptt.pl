#!/usr/bin/perl -w
#
# ffn-to-ptt.pl
# -------------
# go from ffn header line to ptt line
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

if (defined ($ARGV[0]) && ($ARGV[0] eq '-h' || $ARGV[0] eq '--help')) {
  print "Usage: ./ffn-to-ptt.pl orgcode [ INPUT_FILE ]\n";
  print "orgcode will default to ccre but you must specify it if you specify INPUT_FILE.\n";
  exit (0);
}
use vars qw($i);
use Orgmap qw(:DEFAULT read_sequence $pttfile $sequence $seqlength);
&read_orgmap;
&read_sequence;

# variables
my %ptt;	# global to hold ptt information
my $in;

sub key {
  my ($ffnheader) = @_;

  my $matchunit;
  my @nums;
  my $range;
  my $wrap;
  my $searchfor;

  $matchunit = 'c?[<>]?(\d+)-[<>]?(\d+)';
  @nums = ();
  while ($ffnheader =~ m/$matchunit/g) {
    push @nums, $1, $2;
  }
  @nums = sort { $a <=> $b } @nums;
  if ($nums[0] == 1 && $nums[$#nums] == $seqlength) {
    $range = $nums[$#nums] - $nums[0];
    foreach $i (1 .. $#nums) {
      $wrap = pop @nums;
      unshift @nums, $wrap - $seqlength;
      if ($nums[$#nums] - $nums[0] > $range) {
        $wrap = shift @nums;
        push @nums, $wrap + $seqlength;
        last;
      }
      else { $range = $nums[$#nums] - $nums[0]; }
    }
    if ($nums[0] < 1) { $nums[0] = $nums[0] + $seqlength; }
  }
  $searchfor = $nums[0].'~'.$nums[$#nums];
  return ($searchfor);

#  # >(gi|6626251:c3034302-3034228, c3034226-3033204), b2891
#  # this is common for RF-2 to be in 2 pieces like this
#  if ($ffnheader =~ m/:c?(\d+)-(\d+),(.*?c?)(\d+)-(\d+)/) {
#    my @nums = ($1, $2, $4, $5);
#    @nums = sort { $a <=> $b } @nums;
#    $searchfor = $nums[0].'~'.$nums[$#nums];
#    return ($searchfor);
#  }
#
#  # >gb|AE005673|AE005673:160-1107,	regular
#  # >emb|AL591688|:c>3259273-3258668,   this is how smel annotates overlap
#  #					with another orf, I think
#  if ($ffnheader =~ m/(:c?)[<>]?(\d+)-[<>]?(\d+),/) {
#    if ($1 eq ':c') { $searchfor = $3.'~'.$2; }
#    else { $searchfor = $2.'~'.$3; }
#    return ($searchfor);
#  }

}

sub read_ptt {
  my @ptt;
  my $key;
  my $line;
  open PTT, $pttfile; @ptt = <PTT>; close PTT;
  foreach $line (@ptt) {
    if ($line =~ m/\s*(\d+)\.\.(\d+)\s/) {
      chomp $line;
      $key = $1.'~'.$2;
      $ptt{$key} = $line;
    }
  }
}

&read_ptt;
while (defined ($in = <>)) {
  if ($in =~ m/^>/) {
    chomp $in;
    if (defined $ptt{key($in)}) { print $ptt{key($in)}, "\n"; }
    #else { print "$orgcode $in ", key($in), "\n"; }
  }
}
