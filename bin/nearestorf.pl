#!/usr/bin/perl
#
# nearestorf.pl
# -------------
# This is version 2.  It should be faster.  Implement a binary search.  Use
# an array instead of a hash.
#
# Input is a number (which nucleotide).
# Output is the closest orf number, with + for upstream, - for downstream.
#
# some constants to make %genome more readable
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

# Help section
#--------------------------
if (defined($ARGV[0]) && (($ARGV[0] eq '--help') || ($ARGV[0] eq '-h'))) {
format =
Usage: nearestorf.pl [ ORG-CODE [ [-]m ] | -h | --help ] [ -format <fasta|tab> ] [ INPUT_FILE ]
Find genes closest to a given nucleotide position.

ORG-CODE is a 4-letter code which tells the program which genome files to
	use.  Common ones are:
		ccre	Caulobacter crescentus
		ecol	Escherichia coli K12
	If no ORG-CODE is specified then ccre is assumed.
   -m	If ORG-CODE is specified, you can add an additional command line
	parameter which will be the default 'm' used below for number of
	extra nearby genes to print out.  This can still be overridden on
	a line-by-line basis by specifying it in the input.

-format specifies output format.  If this is "fasta" then you will get output
  with a header line and the result.  If this is any other string, then you
  will get tab delimited output with the nucleotide position in the first
  column and the nearest orf(s) in the second column.

-h or --help cause this file to be printed.

Input and output are standard input and output, unless INPUT_FILE is specified.
Input is of the form:
>Header_line
n	m

where n is the nucleotide position you're interested in, and m is the number
of extra nearby genes you want (defaults to 0 if not given).  Each n and m
must be on separate lines.  Header lines can occur anywhere (they start with
a '>') and will just be printed as they are encountered.  A + or - in front of
n will be ignored.

Output will tell you if n is inside a gene, and which gene.  If n is between
genes, it will tell you how far it is from the closest gene on either side
(- is upstream, + is downstream), and what direction the gene is in (+ is
the direction assigned by Genbank in the sequence (.fna) file, - is the
reverse direction).  All numbers and directions are given relative to the
gene they refer to.  If m is greater than 0, then you will get the next
closest genes on either side, with output indented another space for each
additional 'shell' of genes.

.
write;
exit(0); 
}
#--------------------------

use Orgmap qw(:DEFAULT read_sequence $sequence $seqlength $pttfile $topology get_genename get_desc);
use Getopt::Long;
&Getopt::Long::Configure("pass_through");
my $output_format = "fasta";	# default, original
GetOptions (
  'format=s' => \$output_format	# options are fasta or tab
				# actually if it's not fasta we'll use tab
				# i.e. any string here will do to change format
);

&read_orgmap;
&read_sequence;
my $default_m = 0;
my @output_array = ();
if (defined($ARGV[0])) {
  if ($ARGV[0] =~ m/^-?[0-9]*/) { $default_m = abs ($ARGV[0]); shift @ARGV; }
}
$sequence = '';			# try to free up a little bit of memory
undef ($sequence);
my @ptt;
my $n_orig;
my $more;
my $inline;
my $n;
my ($high, $low);
my ($highest_s, $highest_e);
my ($lowest_s, $lowest_e);
my $now;
my ($i, $j);
my ($s, $e);
my ($high_s, $high_e);
my ($low_s, $low_e);
my ($h, $l);
my $pad;
my ($outline_h, $outline_l);
my ($dist_high, $dist_low);

# returns smaller (in absolute value) number preserving signs when returning
sub smaller {
  my ($a, $b) = @_;
  if (abs($a) < abs($b)) {
    return $a;
  }
  else {
    return $b;
  }
}

sub get_se {
  my ($line) = @_;
  my @t = split /\t/, $line;
  $t[0] =~ s/^\s*//;
  my @t2 = split /\.+/, $t[0];
  if ($t[1] =~ /-/) {
    return ($t2[1], $t2[0]);
  }
  else { return ($t2[0], $t2[1]); }
}

# read in some data we'll need

open (GENELIST, $pttfile);
@ptt = ();
while (<GENELIST>) {
  # clean the ptt file, this used to be done by assuming a certain number of
  # header lines - now we check each line for validity
  if (/^\s*\d+\.\.\d+\s+/) {
    push @ptt, $_;
  }
}
close GENELIST;

while (defined($inline = <>)) {
  if ($inline =~ /^>/) { print STDOUT $inline; next; }
  chomp ($inline);
  next if ($inline =~ /^\s*$/);	 # skip blank lines
  ($n_orig, $more) = split /\s+/, $inline;
  if (defined($n_orig)) { $n = abs ($n_orig); }
  if (!defined($more)) { $more = $default_m; }
  if (($n == 0) || ($n > $seqlength)) { print STDERR "$n is out of range, skipping...\n"; next; }
  $low = 0;
  $high = scalar (@ptt) - 1;

# first boundary conditions
  ($lowest_s, $lowest_e) = get_se ($ptt[$low]);
  ($highest_s, $highest_e) = get_se ($ptt[$high]);
  if ((($n < $lowest_s) && ($n < $lowest_e)) ||
     (($n > $highest_s) && ($n > $highest_e))) {
    if ($topology == 0) {	# circular topology, do some wrap-around
      $high = $low;
      $low = scalar (@ptt) - 1;
      $now = $high;
    } else {			# linear topology, no wrap-around
      if (($n < $lowest_s) && ($n < $lowest_e)) {
        $high = $low;
        $low = -1;
        $now = $high;
      } else {
        $low = $high;
        $high = -1;
        $now = $low;
      }
    }
  }

# Binary search.  If inside an orf set $high = $low at that orf.  If
# not in an orf then $high = $low + 1, $high and $low should be nearest orfs.
  while (($high - $low > 1) && ($low >= 0)) {
    $now = int (($low + $high)/2);
    ($s, $e) = get_se ($ptt[$now]);
    if (($n < $s) && ($n < $e)) {		# we're not far enough
      $high = $now;
    }
    elsif (($n > $s) && ($n > $e)) {		# we're past it
      $low = $now;
    }
    elsif ((($n >= $s) && ($n <= $e)) || (($n <= $s) && ($n >= $e))) {
      $low = $now;				# we're inside the orf
      $high = $now;
    }
  }
  # check if we missed checking one
  if (($high != $low) && ($high >= 0) && ($low >= 0)) {
    if ($low == $now) { ($s, $e) = get_se ($ptt[$high]); }
    else { ($s, $e) = get_se ($ptt[$low]); }
    if ((($n >= $s) && ($n <= $e)) || (($n <= $s) && ($n >= $e))) {
      if ($low == $now) { $low = $high; }
      else { $high = $low; }
    }
  }

  if ($output_format eq "fasta") {
    print STDOUT "Position $n_orig in $orgcode is\n"; 
  } else {
    if ($n_orig < 0) {
      push @output_array, "$orgcode$n_orig";
    } else {
      push @output_array, "$orgcode" . "+" . $n_orig;
    }
  }
  for ($i = 0; $i <= $more; ++$i) { 
    if (($high == $low) && ($i == 0)) {
      if ($output_format eq "fasta") {
        print STDOUT " inside ", get_genename ($ptt[$high]).' '.get_desc ($ptt[$high]), "\n";
      } else {
        push @output_array, "inside " . get_genename($ptt[$high]) . ' ' . get_desc($ptt[$high]);
      }
      if ($low == 0) { $low = scalar(@ptt); }
      ($s, $e) = get_se ($ptt[$low-1]);
      if ((($n >= $s) && ($n <= $e)) || (($n <= $s) && ($n >= $e))) {
        if ($output_format eq "fasta") {
          print STDOUT " inside ", get_genename ($ptt[$low-1]).' '.get_desc ($ptt[$low-1]), "\n";
        } else {
          push @output_array, "inside " . get_genename ($ptt[$low-1]).' '.get_desc ($ptt[$low-1]);
        }
        $low = $low-1;
      }
      if ($high == scalar(@ptt) - 1) { $high = -1; }
      ($s, $e) = get_se ($ptt[$high+1]);
      if ((($n >= $s) && ($n <= $e)) || (($n <= $s) && ($n >= $e))) {
        if ($output_format eq "fasta") {
          print STDOUT " inside ", get_genename ($ptt[$high+1]).' '.get_desc ($ptt[$high+1]), "\n";
        } else {
          push @output_array, "inside " . get_genename ($ptt[$high+1]).' '.get_desc ($ptt[$high+1]);
        }
        $high = $high+1;
      }
    } else {
      $pad = '';
      for ($j = 0; $j <= $i; ++$j) { $pad .= ' '; }
      $outline_l = $pad;
      $outline_h = $pad;
      if ($topology == 1) {
        if (($low >=0) && ($low - $i < 0)) { $low = -1; }
        if (($high >=0) && ($high + $i > scalar(@ptt) - 1)) { $high = -1; }
      }
      if ($low >= 0) {
        ($low_s, $low_e) = get_se ($ptt[wraparound($low-$i,$#ptt)]);
      }
      if ($high >= 0) {
        ($high_s, $high_e) = get_se ($ptt[wraparound($high+$i,$#ptt)]);
      }
      if ((wraparound($high+$i,$#ptt) < wraparound($low-$i,$#ptt)) && ($topology == 0)) {
        if (($n < $low_s) && ($n < $low_e)) { 
        $low_s -= $seqlength; $low_e -= $seqlength;
        }
        if (($n > $high_s) && ($n > $high_e)) {
        $high_s += $seqlength; $high_e += $seqlength;
        }
      }

      if ($low >= 0) {
        $dist_low = smaller ($n - $low_s, $n - $low_e);	  # by design all these
        if ($low_s < $low_e) { $outline_l .= "+".$dist_low." away from "; }
        else { $outline_l .= "-".$dist_low." away from "; }
        $outline_l .= get_genename ($ptt[wraparound($low-$i,$#ptt)]).' '.get_desc ($ptt[wraparound($low-$i,$#ptt)]);
        if ($output_format eq "fasta") {
          print STDOUT "$outline_l\n";
        }
      }
      if ($high >= 0) {
        $dist_high = smaller ($high_s - $n, $high_e - $n);  # numbers should be >0
        if ($high_s < $high_e) { $outline_h .= "-".$dist_high." away from "; }
        else { $outline_h .= "+".$dist_high." away from "; }
        $outline_h .= get_genename ($ptt[wraparound($high+$i,$#ptt)]).' '.get_desc ($ptt[wraparound($high+$i,$#ptt)]);
        if ($output_format eq "fasta") {
          print STDOUT "$outline_h\n";
        }
      }
      if ($output_format ne "fasta") {
        $outline_l =~ s/^\s*//;
        $outline_h =~ s/^\s*//;
        push @output_array, join ("|", $outline_l, $outline_h);
      }
    }
  }
  if ($output_format ne "fasta") {
    print join ("\t", @output_array), "\n";
    @output_array = ();
  }
}

sub wraparound {
  my ($i, $max) = @_;
  # assume have an array with $max+1 elements ($max is the largest index)
  # perl already takes care of negative $i
  # if $i is greater than $max, we're going to wrap that around to the beginning
  # just to be complete we'll take care of negative $i also
  if ($i < 0) {
    return ($max + 1 + $i);	# want to start at $max if $i = -1
  }
  if ($i > $max) {
    return ($i - 1 - $max);	# want to start at 0 if $i = $max + 1
  }
  return $i;
}
