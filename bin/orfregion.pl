#!/usr/bin/perl
#
# orfregion.pl
# ------------
# will take input as orf# <whitespace> UPSTREAM <whitespace> DOWNSTREAM
# will output header line then sequence
# >ORFxxxx_in_$orgcode
# sequence
# >UPSTREAM_bases_upstream_of_ORFxxxxx_in_$orgcode
# sequence
# >DOWNSTREAM_bases_downstream_of_ORFxxxxx_in_$orgcode
# sequence
#
# translations will be done so that you get the reading frame
# if it is reversed then you will see -ORFxxxxx
# if it is not reversed then you will see +ORFxxxxx
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
#-----------------------------------
if (defined($ARGV[0]) && (($ARGV[0] eq '--help') || ($ARGV[0] eq '-h'))) {
format =
Usage: orfregion.pl [ ORG-CODE [ INPUT_FILE ] | -h | --help ]
Pull out an orf's sequence and optionally sequences upstream and downstream.

ORG-CODE is a 4-letter code that specifies which genome files to use.  If
        omitted, ccre is the default.

-h or --help causes this help to be printed.

Input and output are from standard input and output, unless INPUT_FILE is
specified.  If you specify INPUT_FILE, you must specify ORG-CODE.
Input is of the form 
>Header_line
[-]ORF [UPSTREAM DOWNSTREAM]

where:

  ORF is the gene you're interested in (you can use just a number if you
like, i.e. 3035, or you can use the full systematic name, i.e. CC3035).  If
you put a negative sign (-) in front of ORF then the program will not output
the orf sequence; this is useful if you want to just pull out upstream or
downstream sequences.

  UPSTREAM is the number of nucleotides upstream of ORF you want.  If you
don't want any you can use 0.

  DOWNSTREAM is the number of nucleotides downstream of ORF that you want.
If you don't want any you can use 0.

If you want neither upstream nor downstream sequence, you can leave both of
them out.  If you want upstream and no downstream, you can leave out
DOWNSTREAM.  But if you want downstream sequence and not upstream, you need to
make sure you put in a 0 for upstream otherwise it will just give you upstream
sequence.

Header lines are printed as they are entered.  Output consists of a
descriptive header followed by the sequence.

.
write;
exit(0);
}
#-----------------------------------

#---------------------------------------------------------
# Initialize some stuff

use Orgmap qw(:DEFAULT read_sequence subseq revcomp $seqlength $geneformat $pttfile $genefield $topology);
&read_orgmap;
&read_sequence;

# variables
my $in;
my $inline;
my $orf;
my ($up, $down);
my $no_orf;
my $namescale;
my $tenpower;
my $sorf;
my $tempnumber;
my $tempstr;
my $subststr;
my ($high, $low);
my ($start, $end);
my $found;
my @t;
my @t2;
my $gcc;
my $dir;
my ($useq, $dseq, $oseq);
my ($useqStart, $dseqStart);
my ($useqOut, $oseqOut);
my $oseqEnd;
my ($uplength, $downlength);


while (defined($in = <>)) {
  ($orf, $up, $down) = (0,0,0);
  chomp $in;
  if ($in =~ /^>/) { print STDOUT $in, "\n"; }
  else {
    ($orf, $up, $down) = split /\s+/, $in;
    if (!defined($orf)) { next; }
    $no_orf = $orf =~ s/^-//;
    if (($orf =~ /^\d+$/) && ($geneformat ne 'NA')) {
      if ($orf == 0) { print STDOUT ">ORF_number_$orf"."_out_of_range.\n"; next; }
        
      # deal with different systematic gene names.  We'll do this by counting
      # the number of x's in the $geneformat.  If this is 5, for example, then
      # add the orf number to 10^5, then chop off the leading 1 so we are left
      # with just the orf number padded with the correct number of 0's.

      $namescale = ($geneformat =~ tr/\#/\#/);
      $tenpower = 10**$namescale;
      if ($orf >= $tenpower) { print STDOUT ">ORF_number_$orf"."_out_of_range.\n"; next; }
      $sorf = $geneformat;
      $tempnumber = $tenpower + $orf;
      $tempstr = substr ($tempnumber, 1, $namescale);
      $subststr = '#' x $namescale;
      $sorf =~ s/$subststr/$tempstr/;
    }
    else { $sorf = $orf; }
    if (!defined($up)) { $up = 0; }
    if (!defined($down)) { $down = 0; }
    ($found, $start, $end) = (0,0,0);
    open (GENELIST, $pttfile); 
    while (defined($gcc = <GENELIST>)) {
      next if $gcc !~ m/^\s*?\d+\.\.\d+/;	# Don't look at header lines
      @t = split /\t/, $gcc;
      $t[0] =~ s/^\s*//;
      @t2 = split /\.+/, $t[0];
      if ($t[$genefield] =~ m/$sorf/) {
        $found = 1;
        if ($t[1] =~ /\+/) { ($start, $end) = ($t2[0], $t2[1]); }
        else { ($end, $start) = ($t2[0], $t2[1]); }
        &print_output ($start, $end);
      }
    }
    close GENELIST;
    if (!$found) { print STDOUT ">some_problem_finding_$sorf"."_in_$orgcode\n"; }
  }
}


sub print_output {
  my ($start, $end) = @_;
  if ($start < $end) {
    $dir = '+';
    $oseqEnd = $end - $start + 1;
    $useqStart = $start - 1;
    $dseqStart = $end + 1;
    if ($useqStart <= 0 && $topology == 0) { $useqStart += $seqlength; }
    if ($dseqStart > $seqlength && $topology == 0) { $dseqStart -= $seqlength; }
    
    $oseq = subseq ($start, $oseqEnd);
    if ($useqStart > 0) {
        $useqOut = subseq ($useqStart, -$up);
        $useq = revcomp ($useqOut);
    }
    if ($dseqStart <= $seqlength) {
        $dseq = subseq ($dseqStart, $down);
    }
  }
  else {
    $dir = '-';
    $oseqEnd = $start - $end + 1;
    $useqStart = $start + 1;
    $dseqStart = $end - 1;
    if ($useqStart > $seqlength && $topology == 0) { $useqStart -= $seqlength; }
    if ($dseqStart <= 0 && $topology == 0) { $dseqStart += $seqlength; }
    
    $oseqOut = subseq ($end, $oseqEnd);
    $oseq = revcomp ($oseqOut);
    if ($useqStart <= $seqlength) {
      $useqOut = subseq ($useqStart, $up);
      $useq = revcomp ($useqOut);
    }
    if ($dseqStart > 0) {
      $dseq = subseq ($dseqStart, -$down);
    }
  }
  
  if ($no_orf == 0) {
    print STDOUT ">".$dir.$t[$genefield]."_in_$orgcode\n$oseq\n";
  }
  if ($up > 0 && defined $useq) {
    $uplength = length $useq;
    print STDOUT ">$uplength"."_bases_upstream_of_$t[$genefield]"."_in_$orgcode\n$useq\n";
  }
  if ($down > 0 && defined $dseq) {
    $downlength = length $dseq;
    print STDOUT ">$downlength"."_bases_downstream_of_$t[$genefield]"."_in_$orgcode\n$dseq\n";
  }
}
