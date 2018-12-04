#!/usr/bin/perl
#
# orfquality.pl
# -------------
# coding sequence taken on STDIN.  will output number and position of
# nonpresent codons.
# We've decided this is crap - mostly.  This should get dumped eventually.
# (SLC 03/02)
#
# internal data structure:
# array for each codon, fields will be:
# 0 - number of tRNAs for this codon
# 1 - Codon again
# 2 - one-letter abbreviation for amino acid
# 3 - three-letter abbreviation
# 4 - number of occurrences in genome
# 5 - percent of total codons in genome
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

if (defined ($ARGV[0])) {
  if ($ARGV[0] eq '-h' || $ARGV[0] eq '--help') {
    print "Usage: orfquality.pl org-code\n";
    exit;
  }
}
else { print "No ORG-CODE given.\n"; exit (1); }

use Orgmap qw(:DEFAULT $ffnfile $fnafile);
&read_orgmap;

my ($p1, $p2, $p3);
my (@cuf, @trf);
my $outfile;
my $header;
my $unknown;
my $pseudo;
my $line;
my $in;
my $codonusefile = $ffnfile;
my $trnasfile = $fnafile;
my @fields;
my $total;
my $num;
my $i;
my $codon;
my $aa;
my @aa;
my $response;
my $start;
my $last;
my $tempin;
my $nonnuc;
my @badcodons;
my $current_threeletter;
my $least_used_percent;
my $pos;
my $codon_data;

$codonusefile =~ s/oneline/codonusage/;
$trnasfile =~ s/oneline/trna-stats/;
$outfile = $ffnfile;
$outfile =~ s/oneline/marginal-codons/;

open CUF, $codonusefile;
open TRF, $trnasfile;
@cuf = <CUF>; @trf = <TRF>;
close CUF;
close TRF;
foreach $p1 ('G', 'A', 'T', 'C') {
  foreach $p2 ('G', 'A', 'T', 'C') {
    foreach $p3 ('G', 'A', 'T', 'C') {
      $codon_data->{$p1.$p2.$p3} = [];
    }
  }
}

$header = 1;
$unknown = 0;
$pseudo = 0;
foreach $line (@trf) {
  if ($header) {
    if ($line =~ /^tRNAs with undetermined/) {
      $line =~ m/(\d+)/;
      $unknown = $1;
      next;
    }
    if ($line =~ /^Predicted pseudogenes/) {
      $line =~ m/(\d+)/;
      $pseudo = $1;
      next;
    }
    next if (!($line =~ /^Total tRNAs/));
  }
  $header = 0;
  if ($line =~ /^Total tRNAs/) {
    $line =~ m/(\d+)/;
    $total = $1;
  }
  if ($line =~ /^[A-Z][a-z][a-z]...:/) {
    @fields = split /[\s:]+/, $line;
    # sanity checks
    $num = $fields[1]; $total -= $num;
    for ($i = 0; $i < scalar @fields; ++$i) {
      if ($fields[$i] =~ /([ACGT]{3})/) {
        my $codon = reverse ($fields[$i]);
        $codon =~ tr/ACGT/TGCA/;		# trna-stats gives anticodons
        if (($i < scalar @fields-1) && ($fields[$i+1] =~ /^(\d+)$/)) {
          push @{$codon_data->{$codon}}, $1;
          $num -= $1;
          ++$i;
        }
        else { push @{$codon_data->{$codon}}, 0; }
      }
    }
    if ($num != 0) { print STDERR "Error parsing tRNA-stats file - aa error\n"; exit(1); }
  }
}
if (($total != 0) && ($total != $unknown + $pseudo)) { print STDERR "Error parsing tRNA-stats file - total error\n"; exit(1); }

@aa = ();
foreach $line (@cuf) {
  next if ($line =~ /^>/);
  chomp $line;
  @fields = split /\t/, $line;
  push @{$codon_data->{$fields[0]}}, @fields;
  push @aa, $fields[2];		# keep track of relative usage for each aa
  push @{$codon_data->{$fields[2]}}, $fields[4];
}
foreach $aa (@aa) {
  @{$codon_data->{$aa}} = sort { $a <=> $b; } @{$codon_data->{$aa}};
}

open FFN, $ffnfile;
if (-e $outfile) {
  print "$outfile exists.  Overwrite? (y/N): ";
  $response = <STDIN>;
  if (!($response =~ /y/i)) { exit (1); }
}
#print "$outfile\n"; <STDIN>;
open (OUT, ">$outfile") || die;
while (defined($in = <FFN>)) {
  if ($in =~ /^>/) { print OUT $in; next; }
  chomp $in;
  $start = substr ($in, 0, 10);
  $in =~ tr/acgt/ACGT/;
  $tempin = $in;
  $nonnuc = $tempin =~ tr/ACGT//cd;
  if ($nonnuc) { print STDERR "$nonnuc non-nucleotide characters found in sequence beginning $start.  These will not be counted for statistics.\n"; }
  if (int(length($in)/3) != length($in)/3) {
    print STDERR "Length of sequence beginning $start is not divisible by 3.  Chopping off from the end and processing anyway.\n";
    while (int(length($in)/3) != length($in)/3) { chop $in; }
  }
  @badcodons = ();
  for (my $i = 0; $i < length($in); $i += 3) {
    $codon = substr ($in, $i, 3);
    $current_threeletter = $codon_data->{$codon}->[3];
    $least_used_percent = $codon_data->{$current_threeletter}->[0];
    if ((defined ($codon_data->{$codon}->[0])) && ($codon_data->{$codon}->[0] =~ m/\d+/)) {
      if (($codon_data->{$codon}->[0] == 0)	# there is no tRNA
       && ($codon_data->{$codon}->[5] == $least_used_percent)	# least frequently occurring
       && ($#{$codon_data->{$current_threeletter}} > 0))	# there's another better codon
        { push @badcodons, $i; }
      $last = $i;
    }
  }
  print OUT "Number of marginal $orgcode codons used: ", scalar @badcodons, "\t", sprintf("%.2f", 100*((scalar @badcodons)/length($in))), "\n";
  if (scalar @badcodons > 0) {
    print OUT "position	codon	one-letter	three-letter	total genomic usage (%)\n";
    foreach $pos (@badcodons) {
      $codon = substr ($in, $pos, 3);
      if (($pos != $last) || ($codon_data->{substr($in, $pos, 3)}->[3] ne 'stop')) {
        print OUT join ("\t", $pos, $codon, @{$codon_data->{$codon}}[2,3,5]), "\n";
      }
    }
  }
}
close FFN;
close OUT;
