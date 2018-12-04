#!/usr/bin/perl
#
# codonuse.pl
# -----------
# generate a table of codon usage
# input will be from fasta format (usually .fna.oneline file)
#
# this won't deal with frameshifts.  If the sequence length isn't a multiple
# of 3 it won't get counted at all.
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

# variables
use vars qw($TTT $TTC $TTA $TTG $TCT $TCC $TCA $TCG $TAT $TAC $TAA $TAG $TGT $TGC $TGA $TGG $CTT $CTC $CTA $CTG $CCT $CCC $CCA $CCG $CAT $CAC $CAA $CAG $CGT $CGC $CGA $CGG $ATT $ATC $ATA $ATG $ACT $ACC $ACA $ACG $AAT $AAC $AAA $AAG $AGT $AGC $AGA $AGG $GTT $GTC $GTA $GTG $GCT $GCC $GCA $GCG $GAT $GAC $GAA $GAG $GGT $GGC $GGA $GGG);
my %codons = ();
my %genetic_code = ();
my $total = 0;
my $in;
my $i;
my $cod;
my @goodcodons;

&init;
while (defined ($in = <>)) {
  while ($in =~ /^>/) {
    $in = <>;
  }
  chomp $in;
  $in =~ tr/a-z/A-Z/;
  if (length($in)/3 == int(length($in)/3)) {
    for ($i = 0; $i < length($in); $i = $i + 3) {
      ++$codons{substr($in, $i, 3)};
      ++$total;
    }
  }
}
if ($total > 0) {
  print STDOUT ">Total_codons:$total\n";
  print STDOUT ">Codon	One-letter	Three-letter	Number	Percent\n";
  foreach $cod (sort @goodcodons) {
    print STDOUT join "\t", $cod, $genetic_code{$cod}, $codons{$cod}, sprintf("%.2f", 100*($codons{$cod}/$total));
    print STDOUT "\n";
  }
}
sub init {
  @goodcodons = ();
  my ($a, $b, $c);
  foreach $a ('G', 'A', 'T', 'C') {
    foreach $b ('G', 'A', 'T', 'C') {
      foreach $c ('G', 'A', 'T', 'C') {
        push @goodcodons, $a.$b.$c;
        $codons{$a.$b.$c} = 0;
      }
    }
  }

  $genetic_code{TTT} = "F\tPhe";
  $genetic_code{TTC} = "F\tPhe";
  $genetic_code{TTA} = "L\tLeu";
  $genetic_code{TTG} = "L\tLeu";
  $genetic_code{TCT} = "S\tSer";
  $genetic_code{TCC} = "S\tSer";
  $genetic_code{TCA} = "S\tSer";
  $genetic_code{TCG} = "S\tSer";
  $genetic_code{TAT} = "Y\tTyr";
  $genetic_code{TAC} = "Y\tTyr";
  $genetic_code{TAA} = "X\tstop";
  $genetic_code{TAG} = "X\tstop";
  $genetic_code{TGT} = "C\tCys";
  $genetic_code{TGC} = "C\tCys";
  $genetic_code{TGA} = "X\tstop";
  $genetic_code{TGG} = "W\tTrp";
  $genetic_code{CTT} = "L\tLeu";
  $genetic_code{CTC} = "L\tLeu";
  $genetic_code{CTA} = "L\tLeu";
  $genetic_code{CTG} = "L\tLeu";
  $genetic_code{CCT} = "P\tPro";
  $genetic_code{CCC} = "P\tPro";
  $genetic_code{CCA} = "P\tPro";
  $genetic_code{CCG} = "P\tPro";
  $genetic_code{CAT} = "H\tHis";
  $genetic_code{CAC} = "H\tHis";
  $genetic_code{CAA} = "Q\tGln";
  $genetic_code{CAG} = "Q\tGln";
  $genetic_code{CGT} = "R\tArg";
  $genetic_code{CGC} = "R\tArg";
  $genetic_code{CGA} = "R\tArg";
  $genetic_code{CGG} = "R\tArg";
  $genetic_code{ATT} = "I\tIle";
  $genetic_code{ATC} = "I\tIle";
  $genetic_code{ATA} = "I\tIle";
  $genetic_code{ATG} = "M\tMet";
  $genetic_code{ACT} = "T\tThr";
  $genetic_code{ACC} = "T\tThr";
  $genetic_code{ACA} = "T\tThr";
  $genetic_code{ACG} = "T\tThr";
  $genetic_code{AAT} = "N\tAsn";
  $genetic_code{AAC} = "N\tAsn";
  $genetic_code{AAA} = "K\tLys";
  $genetic_code{AAG} = "K\tLys";
  $genetic_code{AGT} = "S\tSer";
  $genetic_code{AGC} = "S\tSer";
  $genetic_code{AGA} = "R\tArg";
  $genetic_code{AGG} = "R\tArg";
  $genetic_code{GTT} = "V\tVal";
  $genetic_code{GTC} = "V\tVal";
  $genetic_code{GTA} = "V\tVal";
  $genetic_code{GTG} = "V\tVal";
  $genetic_code{GCT} = "A\tAla";
  $genetic_code{GCC} = "A\tAla";
  $genetic_code{GCA} = "A\tAla";
  $genetic_code{GCG} = "A\tAla";
  $genetic_code{GAT} = "D\tAsp";
  $genetic_code{GAC} = "D\tAsp";
  $genetic_code{GAA} = "E\tGlu";
  $genetic_code{GAG} = "E\tGlu";
  $genetic_code{GGT} = "G\tGly";
  $genetic_code{GGC} = "G\tGly";
  $genetic_code{GGA} = "G\tGly";
  $genetic_code{GGG} = "G\tGly";
}
