#!/usr/bin/perl -w
#
# Convert feature table from new GCA/GCF assemblies at Genbank to old ptt format
# Careful - only provides output for the first chromosome unless specified
#
use strict;
use Getopt::Long;
&Getopt::Long::Configure("pass_through");
my $chrom = "";
GetOptions (
  'chrom=s' => \$chrom
);
my @f;
my $i;
my @out;
print join ("\t", "Location", "Strand", "Length", "PID", "Gene", "Synonym", "Code", "COG", "Product"), "\n";
while (<>) {
  next if /^#/;
  next if /^$/;
  chomp;
  @f = split /\t/, $_;
  next if $f[0] eq "gene";
  if ($chrom eq "") {
    $chrom = $f[6];
  }
  next if $f[6] ne $chrom;
  @out = ();
  $out[0] = join ("..", $f[7], $f[8]);
  $out[1] = $f[9];
  if (defined $f[18] && $f[18] =~ /^\d+/) {
    $out[2] = $f[18];
  } else {
    $out[2] = $f[17];
  }
  $out[3] = $f[10];
  $out[4] = $f[14];
  $out[5] = $f[16];
  $out[6] = "";
  $out[7] = "";
  $out[8] = $f[13];
  foreach $i (0..$#out) {
    if (!defined $out[$i] || $out[$i] =~ /^\s*$/) {
      $out[$i] = "-";
    }
  }
  print join ("\t", @out), "\n";
}
