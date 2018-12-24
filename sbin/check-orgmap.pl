#!/usr/bin/perl
#
# do some sanity checks on org-map
#
use warnings;
use strict;
use Orgmap;

my $orgmapfile = "$Orgmap::LIBPATH/org-map";
my @orgcodes = ();
my @badorgs = ();
my @f;
my $org;
my $i;
my $backup;
my $orgmap;
my $response;

open O, $orgmapfile;
while (<O>) {
  chomp;
  next if /^$/;
  next if /^#/;
  @f = split /\t/, $_;
  push @orgcodes, $f[0];
}
close O;

foreach $org (@orgcodes) {
  eval { &read_orgmap($org) };
  if (!-d $Orgmap::straindir || !-f $Orgmap::fnafile) {
    push @badorgs, $org;
  }
}

if (scalar @badorgs) {
  print "Can't find data for the following orgcodes:\n";
  print join ("\n", @badorgs), "\n";
  print "Comment these out? (Y/n) ";
  $response = <STDIN>;
  if ($response =~ /^y/ || $response =~ /^$/) {
    $i = 0;
    $backup = "$orgmapfile.bak.$i";
    while (-f $backup) {
      $i++;
      $backup = "$orgmapfile.bak.$i";
    }
    rename ("$orgmapfile", $backup);
    open O, $backup;
    open NEW, ">$orgmapfile";
    while (<O>) {
      foreach $org (@badorgs) {
        print NEW "# " if /^$org\t/;
      }
      print NEW;
    }
    close O;
    close NEW;
  }
} else {
  print "No errors found.\n";
}
