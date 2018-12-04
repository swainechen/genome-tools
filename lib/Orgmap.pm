#!/usr/bin/perl
#
# Orgmap.pm
#   This code does all the parsing and reading of the org-map file.
#   It will return such things as filenames, and location of generic gene name.
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

package Orgmap;
require Exporter;

use Getopt::Long;
&Getopt::Long::Configure("pass_through");
use warnings;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK);
use vars qw($ROOTPATH $GENOMESPATH $BINPATH $LIBPATH $SBINPATH $default_orgcode);
use vars qw($orgcode $topology $orgname $subname $genbanklink $faafile $ffnfile $fnafile $pttfile $gidfield $geneformat $genefield $descfields $sequence $straindir $fileprefix $accession $seqlength $cmd_faafile $cmd_ffnfile $cmd_fnafile $cmd_pttfile);

@ISA = qw(Exporter);

@EXPORT = qw(read_orgmap $orgcode);
@EXPORT_OK = qw(read_sequence get_desc get_genename subseq revcomp $topology $orgname $subname $genbanklink $faafile $ffnfile $fnafile $pttfile $gidfield $geneformat $genefield $descfields $sequence $straindir $fileprefix $accession $seqlength $BINPATH $LIBPATH $SBINPATH $GENOMESPATH $ROOTPATH);

# Read in constants
my @conffiles = ("/etc/genome-tools.conf", "/usr/etc/genome-tools.conf", "/usr/local/etc/genome-tools.conf", glob("~/.genome-toolsrc"));
foreach my $conffile (@conffiles) {
  if (-f $conffile) {
    do $conffile;
  }
}

$faafile = '';
$ffnfile = '';
$fnafile = '';
$pttfile = '';
$cmd_faafile = '';
$cmd_ffnfile = '';
$cmd_fnafile = '';
$cmd_pttfile = '';
$seqlength = 0;
$sequence = '';
$accession = '';

GetOptions ('faa=s' => \$cmd_faafile,
            'ffn=s' => \$cmd_ffnfile,
            'fna=s' => \$cmd_fnafile,
            'ptt=s' => \$cmd_pttfile);

sub read_orgmap {
  my ($argument) = @_;
  my @straindir;
  my $done;
  my $in;
  my @temp;
  my $fieldnum;
  if (defined $argument && length($argument) == 4) {
    $orgcode = $argument;
  } elsif (not $ARGV[0]) { $orgcode = $default_orgcode; }
  else { $orgcode = $ARGV[0]; }
  open (ORGMAP, "$LIBPATH/org-map");
  $done = 0;
  while (defined($in = <ORGMAP>) && ($done == 0)) {
    next if $in =~ /^$/;
    next if $in =~ /^#/;
    last if length ($orgcode) != 4;
    if ($in =~ /^$orgcode/) {
      $done = 1;
      chomp $in;
      @temp = split /\t/, $in;

      @straindir = split /\//, $temp[1];
      $accession = pop @straindir;
      $straindir = join '/', @straindir;

      # change format to remove $GENOMESPATH, be more flexible
      if ($straindir =~ /\$GENOMESPATH/) {
        $straindir =~ s/\$GENOMESPATH/$GENOMESPATH/;
      } elsif (-d "$GENOMESPATH/$straindir") {
        $straindir = "$GENOMESPATH/$straindir";
      }
      if (!-d $straindir) { # otherwise take the field as the directory
        die "Can't find strain directory $straindir\n";
      }
    
      $fileprefix = "$straindir/$accession";
      if ($cmd_faafile eq "") {
        $faafile = $fileprefix.'.faa';	# amino acids of ORFs
      }
      if ($cmd_ffnfile eq "") {
        $ffnfile = $fileprefix.'.ffn';	# nucleotides of ORFs
      }
      if ($cmd_fnafile eq "") {
        $fnafile = $fileprefix.'.fna';	# nucleotides of complete genome
      }
      if ($cmd_pttfile eq "") {
        $pttfile = $fileprefix.'.ptt';	# gene-list type file
      }
      $gidfield = 3;			# hard-code GID field
      $geneformat = $temp[2];
      $genefield = $temp[3];
      $descfields = $temp[4];		# fields from .ptt file to
					# concatenate to get a description

      $orgname = $temp[5];		# Organism species name
      $subname = $temp[6];		# Secondary genome name
      $genbanklink = $temp[7];		# GenBank gi number
      $topology = $temp[8];		# 0 = circular, 1 = linear


    } 
  }
  if ($done == 0) { die "Invalid ORG-CODE\n"; }
  else { shift @ARGV; }
  close ORGMAP;
}

sub read_sequence {
  open (IN, $fnafile);
  my $line;
  $sequence = "";
  while ($line = <IN>) {
    next if $line =~ /^>/;	# get rid of fasta header
    chomp $line;
    $sequence .= $line;
  }
  $seqlength = length ($sequence);
  close IN;
}

sub get_desc {
  my ($line) = @_;
  chomp $line;
  my @t = split /\t/, $line;
  my @f = split /,/, $descfields;
  my $temp = '';
  my $fieldnum;
  foreach $fieldnum (@f) {
    if (defined $t[$fieldnum]) {
      if ($temp eq '') { $temp = $t[$fieldnum]; }
      else { $temp = $temp.' '.$t[$fieldnum]; }
    }
  }
  return $temp;
}

# input is a line from a ptt file again.  Put a +/- in front of it also.
sub get_genename {
  my ($line) = @_;
  my @t;
  @t = split /\t/, $line;
  $t[1] =~ s/\s//g;
  return ($t[1].$t[$genefield]);
}

sub subseq {
  my ($instart, $inlength) = @_;
  my $length;
  my $start;
  my $strand;
  my $wrapstart;
  my $out;
  my $outlength;
  my $revseq;
  if ($seqlength == 0) {
    &read_sequence;
  }

  if (!defined($instart) || !defined($inlength)) { return; }
  $length = abs ($inlength);
  if (($instart == 0) || ($length > $seqlength) || ($instart > $seqlength)) {
    print STDOUT ">Out_of_range:$inlength"."_bases_at_pos_$instart"."_in_$orgcode\n";
    return;
  }
  if ((($instart > 0) && ($inlength < 0)) ||
    (($instart < 0) && ($inlength > 0))) {
    $start = abs($instart) - $length + 1;
    $strand = '-';
  }
  else { $start = abs($instart); $strand = '+'; }

  if ($start <= 0) {
    if ($topology == 0) {
      $wrapstart = $seqlength + $start - 1;
      $out = substr ($sequence, $wrapstart, $seqlength - $wrapstart);
      $out .= substr ($sequence, 0, $length + $start - 1);
    } else {
      $out = substr ($sequence, 0, abs($instart));
    }
  }
  elsif ($start + $length - 1 > $seqlength) {
    if ($topology == 0) {
      $out = substr ($sequence, $start-1, $seqlength - $start + 1);
      $out .= substr ($sequence, 0, $length + $start - $seqlength - 1);
    } else {
      $out = substr ($sequence, $start-1, $seqlength - $start + 1);
    }
  }
  else {
    $out = substr ($sequence, $start-1, $length);
  }
  
  $outlength = length($out);
  if ($inlength < 0) { $outlength = -$outlength; }
  if ($strand eq '+') {
    return $out;
  }
  else {
    $revseq = revcomp ($out);
    return $revseq;
  }
}

sub revcomp {
  my ($inline) = $_[0];
  my $outline = reverse ($inline);
  $outline =~ tr/ABCDGHKMNRSTVWXYabcdghkmnrstvwxy/TVGHCDMKNYSABWXRtvghcdmknysabwxr/;
  return $outline;
}


# need to return true to make Perl's require statement happy
1;
