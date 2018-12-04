#!/usr/bin/perl
#
# rnatab-to-ptt.pl
# ----------------
# take RNA features file and make .ptt file
# RNA features comes from Genbank, which for some reason didn't put them into
# the .ptt file.  For Caulobacter it comes from:
# http://www.ncbi.nlm.nih.gov/cgi-bin/Entrez/rnatab?gi=177&db=Genome
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

# $OFFSET is here so you can start at not 9999 for a 4-digit systematic gene
# number.  It will subtract $OFFSET from the highest gene number it starts with
my $OFFSET = 0;

if (not $ARGV[0]) { die "No ORG-CODE specified\nUsage: rnatab-to-ptt.pl ORG-CODE rnatab-file\n"; }
if (not $ARGV[1]) { die "No input Genbank rnatab file specified\nUsage: rnatab-to-ptt.pl ORG-CODE rnatab-file\n"; }

use Orgmap qw(:DEFAULT $geneformat $genefield);
&read_orgmap;

my $prefix;
my $num;
my $gnum;
my @in;
my $acount;
my $isHTML;
my $in;
my $pid;
my $location;
my $gene;
my $dir;
my $product;
my @fields;
my @t;
my $length;
my $llen;
my $dots;
my $prepack;
my $postpack;
my $systgene;

if ($geneformat eq 'NA') {
  $prefix = 'RNA_Gene';
  $num = 4;
  $gnum = 10**$num - $OFFSET;
} else {
  $prefix = $geneformat;
  $num = $prefix =~ tr/#//d;
  $gnum = 10**$num - $OFFSET;
}
$pid = -1;

open (IN, $ARGV[0]);
@in = <IN>;
close IN;

# figure out if we're HTML
$acount = 0;
$isHTML = 0;
foreach $in (@in) {
  chomp $in;
  if (($in) && ($in =~ /<HTML>/)) { $isHTML = 1; }
  if (($in) && ($in =~ m|</a>|) && ($in =~ m|\d+\.\.\d+|)) { ++$acount; }
}

if ($isHTML || $acount > 0) {			# this looks like HTML
  foreach $in (@in) {
    chomp $in;

    # Just quit the program if this is an empty rnatab file
    exit(0) if ($in =~ /0\sRNA\sgenes\sfound\sin\sthis\sregion/);

    if ($in =~ m|\d+\.\.\d+|) {			# look for a location
      $in =~ s/<.*?>/ /g;			# strip HTML stuff
      &dostuff($in);
    }
  }
}
  
# if it's a text file
# (made from selecting [Save] the report below in [Table] format
# on the rnatab/structural RNA genes page from Genbank.
# hopefully there are no spaces in the first three fields, so split by those.
# fields I expect are:
# location   direction   gene   product
# ###..###      +/-      abcA   abc gene product
else {
  foreach $in (@in) {
    chomp $in;
    next if (length($in) < 7);
    next if ($in =~ m/<.*>/);
    next if ($in =~ m/Location/);
    &dostuff($in);
  }
}

sub dostuff {
  my ($in) = @_;
  $in =~ s/^\s+//;
  ($location, $dir, $gene, $product) = ();
  @fields = split /\s+/, $in;
  $location = shift @fields;
  $dir = shift @fields;
  if (scalar @fields > 0) { $gene = shift @fields; }
  else { $gene = '-'; }
  if (scalar @fields > 0) { $product = join ' ', @fields; }
  else { $product = '-'; }
  @t = split /\.+/, $location;
  $length = $t[1] - $t[0] + 1;

  # hack to make this look like Genbank's ptt file
  # .. in location is at column 10, 11, location is padded by spaces to
  # a length of 20.  this leaves 9 chars for first number, 9 for the second
  # for direction, it's two characters, a space before the + or -.
  # as of 12/28/04, Genbank seems to have no leading or trailing spaces
  # and no space before the + or -

  $llen = length ($location);
  $location =~ m/\.\./g;
  $dots = pos ($location) - 1;
  $prepack = 10 - $dots;
  $postpack = 10 - ($llen - $dots);
#  $prepack = ' ' x $prepack;
#  $postpack = ' ' x $postpack;
  $prepack = "";
  $postpack = "";
  $location = $prepack.$location.$postpack;
#  $dir = ' '.$dir;

  --$gnum;
  $systgene = $prefix.$gnum;
  --$pid;
  if ($genefield == 4) {
    print STDOUT join ("\t", $location, $dir, $length, $pid, $systgene, $gene, '-', '-', $product), "\t\n";
  }
  elsif ($genefield == 5) {
    print STDOUT join ("\t", $location, $dir, $length, $pid, $gene, $systgene, '-', '-', $product), "\t\n";
  }
}
