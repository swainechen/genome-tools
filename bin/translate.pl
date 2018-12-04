#!/usr/bin/perl
#
# translate.pl
# ------------
# translate sequences.  Output header line indicating frame, then sequence,
# then aa sequence
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

use Getopt::Long;
&Getopt::Long::Configure("pass_through");

my $outfile = '';
my $nosingle = 0;
my $notriple = 0;
my $nosix = 0;
my $nosequence = 0;
my $in;
my $out;
my $response;
my $codon_data;

GetOptions ('o=s' => \$outfile,
            'nosingle' => \$nosingle,
            'notriple' => \$notriple,
            'nosix' => \$nosix,
            'nosequence' => \$nosequence);
if (($outfile ne '') && (-e $outfile)) {
  print "$outfile exists.  Overwrite? (y/N): ";
  $response = <STDIN>;
  if (!($response =~ /y/i)) { exit (1); }
}
if ($outfile ne '') { open (OUT, ">$outfile") || die; $out = *OUT; }
else { $out = *STDOUT; }


if (defined ($ARGV[0])) {
  if ($ARGV[0] eq '-h' || $ARGV[0] eq '--help') {
    print "Usage: translate.pl [-nosingle] [-notriple] [-nosix] [-nosequence] [INFILE] [-o OUTFILE]\n";
    print "INFILE should have FASTA formatted DNA sequences.  If not specified,\nprogram will read from stadard input.\n";
    print "-nosingle suppresses single letter translation output.\n";
    print "-notriple suppresses three letter translation output.\n";
    print "-nosix gives only the first reading frame, no six-frame translation.\n";
    print "-nosequence suppresses printing of the sequence you entered.\n\n";
    print "NOTE: X = stop codon in one-letter translation.  In three-letter translation,\nSTOP = stop codon.  Non-GATC characters give ? or ??? in one and three-letter\ntranslations respectively.\n";
    exit;
  }
}

&init;
while (defined ($in = <>)) {
  if ($in =~ m/^>/) { print $out $in; next; }
  chomp $in;
  if ($nosix) {
    &do_trans($in);
  }
  else {
    print $out ">Frame_+1\n";
    &do_trans($in);
    print $out ">Frame_+2\n";
    &do_trans(substr($in, 1));
    print $out ">Frame_+3\n";
    &do_trans(substr($in, 2));
    $in = reverse $in;
    $in =~ tr/gatcGATC/ctagCTAG/;
    print $out ">Frame_-1\n";
    &do_trans($in);
    print $out ">Frame_-2\n";
    &do_trans(substr($in, 1));
    print $out ">Frame_-3\n";
    &do_trans(substr($in, 2));
  }
}

sub do_trans {
  my ($s) = @_;
  if (!$nosequence) { print $out $s, "\n"; }
  $s =~ tr/a-z/A-Z/;
  my $outline1 = '';
  my @outline3 = ();
  my $i;
  my $codon;
  for (my $i = 0; $i < length($s); $i += 3) {
    $codon = substr($s, $i, 3);
    if (defined $codon_data->{$codon}->[0]) {
      $outline1 .= $codon_data->{$codon}->[0];
      push @outline3, $codon_data->{$codon}->[1];
    }
    else {
      $outline1 .= '?';
      push @outline3, '???';
    }
  }
  if (!$nosingle) { print $out $outline1, "\n"; }
  if (!$notriple) { print $out join (' ', @outline3), "\n"; }
}

sub init {
  $codon_data->{TTT} = ["F", "Phe"];
  $codon_data->{TTC} = ["F", "Phe"];
  $codon_data->{TTA} = ["L", "Leu"];
  $codon_data->{TTG} = ["L", "Leu"];
  $codon_data->{TCT} = ["S", "Ser"];
  $codon_data->{TCC} = ["S", "Ser"];
  $codon_data->{TCA} = ["S", "Ser"];
  $codon_data->{TCG} = ["S", "Ser"];
  $codon_data->{TAT} = ["Y", "Tyr"];
  $codon_data->{TAC} = ["Y", "Tyr"];
  $codon_data->{TAA} = ["X", "STOP"];
  $codon_data->{TAG} = ["X", "STOP"];
  $codon_data->{TGT} = ["C", "Cys"];
  $codon_data->{TGC} = ["C", "Cys"];
  $codon_data->{TGA} = ["X", "STOP"];
  $codon_data->{TGG} = ["W", "Trp"];
  $codon_data->{CTT} = ["L", "Leu"];
  $codon_data->{CTC} = ["L", "Leu"];
  $codon_data->{CTA} = ["L", "Leu"];
  $codon_data->{CTG} = ["L", "Leu"];
  $codon_data->{CCT} = ["P", "Pro"];
  $codon_data->{CCC} = ["P", "Pro"];
  $codon_data->{CCA} = ["P", "Pro"];
  $codon_data->{CCG} = ["P", "Pro"];
  $codon_data->{CAT} = ["H", "His"];
  $codon_data->{CAC} = ["H", "His"];
  $codon_data->{CAA} = ["Q", "Gln"];
  $codon_data->{CAG} = ["Q", "Gln"];
  $codon_data->{CGT} = ["R", "Arg"];
  $codon_data->{CGC} = ["R", "Arg"];
  $codon_data->{CGA} = ["R", "Arg"];
  $codon_data->{CGG} = ["R", "Arg"];
  $codon_data->{ATT} = ["I", "Ile"];
  $codon_data->{ATC} = ["I", "Ile"];
  $codon_data->{ATA} = ["I", "Ile"];
  $codon_data->{ATG} = ["M", "Met"];
  $codon_data->{ACT} = ["T", "Thr"];
  $codon_data->{ACC} = ["T", "Thr"];
  $codon_data->{ACA} = ["T", "Thr"];
  $codon_data->{ACG} = ["T", "Thr"];
  $codon_data->{AAT} = ["N", "Asn"];
  $codon_data->{AAC} = ["N", "Asn"];
  $codon_data->{AAA} = ["K", "Lys"];
  $codon_data->{AAG} = ["K", "Lys"];
  $codon_data->{AGT} = ["S", "Ser"];
  $codon_data->{AGC} = ["S", "Ser"];
  $codon_data->{AGA} = ["R", "Arg"];
  $codon_data->{AGG} = ["R", "Arg"];
  $codon_data->{GTT} = ["V", "Val"];
  $codon_data->{GTC} = ["V", "Val"];
  $codon_data->{GTA} = ["V", "Val"];
  $codon_data->{GTG} = ["V", "Val"];
  $codon_data->{GCT} = ["A", "Ala"];
  $codon_data->{GCC} = ["A", "Ala"];
  $codon_data->{GCA} = ["A", "Ala"];
  $codon_data->{GCG} = ["A", "Ala"];
  $codon_data->{GAT} = ["D", "Asp"];
  $codon_data->{GAC} = ["D", "Asp"];
  $codon_data->{GAA} = ["E", "Glu"];
  $codon_data->{GAG} = ["E", "Glu"];
  $codon_data->{GGT} = ["G", "Gly"];
  $codon_data->{GGC} = ["G", "Gly"];
  $codon_data->{GGA} = ["G", "Gly"];
  $codon_data->{GGG} = ["G", "Gly"];
}
