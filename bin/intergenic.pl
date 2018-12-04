#!/usr/bin/perl
#
# intergenic.pl
# -------------
# Generalized script to make intergenic file.
# Each intergenic region will be on a separate line.
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

my $ORF = 0;
my $END = 1;
my %genome;
my $adjuststart;
my $firstend;
my $laststart;
my $inline;
my @t;
my @t2;
my $orf;
my $low;
my ($firstorf, $lastorf, $wraporf);
my $len;
my ($startpoint, $endpoint);
my $wrapinter;

# for this intergenic.pl program, $ORF will actually hold
# the direction of the orf (+/-) and the orf name.

use Orgmap qw(:DEFAULT read_sequence $pttfile $genefield $sequence $seqlength $topology);
&read_orgmap;
&read_sequence;

open (GENELIST, $pttfile);
# old ptt headers were 6 lines.  This isn't necessarily the case any more
# for ($i = 1; $i < 6; ++$i) { $inline = <GENELIST>; } # get rid of headers

%genome = ();
$adjuststart = 0;		# for dealing with wrap-around genes
$firstend = $seqlength;		# for dealing with wrap-around intergenics
$laststart = 0;

while (defined($inline = <GENELIST>)) {
  next unless $inline =~ /^\s*\d+\.\.\d+/;	# skip header lines
  @t = split /\t/, $inline;
  $t[0] =~ s/^\s*//;
  @t2 = split /\.+/, $t[0];
  $orf = $t[$genefield]; 
# key this hash with the lower position number,
# regardless of direction
# note that if the orf starts/ends at position n, the intergenic region
# starts/ends at position n-1 or n+1
  $low = $t2[0] - 1;
  $genome{$low}[$END] = $t2[1] + 1;
  if ($t[1] =~ /-/) { $genome{$low}[$ORF] = '-'.$orf; }
  else { $genome{$low}[$ORF] = '+'.$orf; }
  if ($topology == 0 &&
      $low > $genome{$low}[$END] &&
      $genome{$low}[$END] > $adjuststart) {
    $adjuststart = $genome{$low}[$END];
    $wraporf = $genome{$low}[$ORF];
  }
  if ($low < $firstend) {
    $firstend = $low;
    $firstorf = $genome{$low}[$ORF];
  }
  if ($genome{$low}[$END] > $laststart) { 
    $laststart = $genome{$low}[$END];
    $lastorf = $genome{$low}[$ORF];
  }
}

if ($adjuststart > 0) {
  $startpoint = $adjuststart;
  $lastorf = $wraporf;
} elsif ($topology == 0) {
  $len = $seqlength - $laststart + 1;
  $wrapinter = substr($sequence, $laststart-1, $len);
  $len += $firstend;
  $wrapinter .= substr($sequence, 0, $firstend);
  print STDOUT ">$len|$laststart,$firstend|$lastorf$firstorf\n";
  print STDOUT $wrapinter, "\n";
  $startpoint = $genome{$firstend}[$END];
  $lastorf = $genome{$firstend}[$ORF];
} else {
  $startpoint = 1;
  $lastorf = 'Begin';
}
sub numerically { $a <=> $b; }
foreach $endpoint (sort numerically keys %genome) {
  if ($startpoint <= $endpoint) {
  $len = $endpoint - $startpoint + 1;
  print STDOUT ">$len|$startpoint,$endpoint|$lastorf$genome{$endpoint}[$ORF]\n";
  print STDOUT substr($sequence, $startpoint-1, $len),"\n";
  }
  if ($genome{$endpoint}[$END] > $startpoint) {
    $startpoint = $genome{$endpoint}[$END];
  }
  $lastorf = $genome{$endpoint}[$ORF];
}
if ($topology == 1) {
  # do the last one which will go to the end
  $len = $seqlength - $startpoint + 1;
  print STDOUT ">$len|$startpoint,$seqlength|$lastorf", "End\n";
  print STDOUT substr($sequence, $startpoint-1, $len),"\n";
}

# be careful about counting because substr function is zero-based
# but the indexes in the genelist file are one-based
