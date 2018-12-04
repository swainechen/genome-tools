#!/usr/bin/perl
#
# Script to upgrade genome-tools package
#
# Basically, do the same thing as setup script except look for the config
# file to do the installation, and don't ask so many questions.
# If we can't find a config file, then we're not going to do anything.
# We're not going to look for user-directory specific config files either.
#
use warnings;
use strict;
use Getopt::Long;
use File::Copy;
use vars qw($ROOTPATH $GENOMESPATH $BINPATH $LIBPATH $SBINPATH $default_orgcode);

my $config_file = "";
my $log_file = "upgrade.log";
my $help = 0;
my $have_conf;
my @conffiles;
my $conffile;
my $orgmap_path;
my $path;
my $dir;
my $dest;
my $file;
my @parts;
my $fulldest;

GetOptions ("config=s" => \$config_file,
            "log=s" => \$log_file,
            "help" => \$help);

if ($help) { &print_usage; exit; }

$have_conf = 0;
if (length $config_file && -f $config_file) {
  $have_conf = 1;
  do $config_file;
} else {
  @conffiles = ("/etc/genome-tools.conf", "/usr/etc/genome-tools.conf", "/usr/local/etc/genome-tools.conf");
  foreach $conffile (@conffiles) {
    if (-f $conffile) {
      $have_conf = 1;
      do $conffile;
      $config_file = $conffile;
    }
  }
}

if (!$have_conf) {
  print STDERR "Cannot find a valid genome-tools configuration file\n";
  &print_use_setup;
  exit;
}

# check for all the variables we need
# $ROOTPATH, $GENOMESPATH, $BINPATH, $LIBPATH, $SBINPATH, and $default_orgcode
# we'll have to go look for the $orgmap_path in @INC
if (!$ROOTPATH) {
  print STDERR "Cannot find \$ROOTPATH in $config_file\n";
  &print_use_setup;
  exit;
}
if (!$GENOMESPATH) {
  print STDERR "Cannot find \$GENOMESPATH in $config_file\n";
  &print_use_setup;
  exit;
}
if (!$BINPATH) {
  print STDERR "Cannot find \$BINPATH in $config_file\n";
  &print_use_setup;
  exit;
}
if (!$LIBPATH) {
  print STDERR "Cannot find \$LIBPATH in $config_file\n";
  &print_use_setup;
  exit;
}
if (!$SBINPATH) {
  print STDERR "Cannot find \$SBINPATH in $config_file\n";
  &print_use_setup;
  exit;
}

$orgmap_path = "";
foreach $path (@INC) {
  if (-f "$path/Orgmap.pm" && $path ne ".") {
    $orgmap_path = $path;
    last;
  }
}
if (!$orgmap_path) {
  print STDERR "Cannot find Orgmap.pm in \@INC\n";
  print STDERR "Orgmap.pm needs to be in a directory included in \@INC for genome-tools to work\n";
  &print_use_setup;
  exit;
}

# Do all the copying
# This is just copied from setup.pl
open LOG, ">$log_file";

# bin
$dest = $BINPATH;
$dir = "bin";
&install_path($dir, $dest);

# lib
$dest = $LIBPATH;
$dir = "lib";
&install_path($dir, $dest);

# sbin
$dest = $SBINPATH;
$dir = "sbin";
&install_path($dir, $dest);

# copy Orgmap.pm to the right location
print "Copying lib/Orgmap.pm to $orgmap_path...";
if (copy ("lib/Orgmap.pm", $orgmap_path)) {
  print LOG "Copy lib/Orgmap.pm to $orgmap_path\n";
  print "done!\n";
} else {
  print LOG "Error copying lib/Orgmap.pm to $orgmap_path\n";
  print "Error!\n";
}
close LOG;

print "\n\nNOTE: A log of all the files created/copied by this upgrade script\n";
print "is stored in $log_file, in case you need to uninstall later.\n";
print "\nYou probably also want to update your genome data files as well,\n";
print "using the update-genome.pl script in $SBINPATH\n";
print "You can get help by running\n";
print "  > update-genome.pl --help\n";
print "\nGood luck, and I hope genome-tools helps you.\n";


sub print_usage {
  print "Usage: $0 [-help] [-config <config_file>] [-log <log_file>]\n";
  print "Upgrades genome-tools package (binaries and perl module, but not org-map file)\n";
  print "  -help prints this message\n";
  print "  -config specifies the genome-tools configuration file to use\n";
  print "  -log specifies the log file to generate upon upgrading\n";
}

sub print_use_setup {
  print "It seems there is some error finding or reading your genome-tools\n";
  print "configuration file.  Please use the setup.pl installation script\n";
  print "which will generate a new genome-tools.conf configuration file for\n";
  print "you.\n"
}

sub install_path {
  my ($dir, $dest) = @_;
  my $file;
  my @parts;
  my $fulldest;
  foreach $file (glob ("$dir/*")) {
    chomp $file;
    @parts = split /\//, $file;
    next if $parts[$#parts] =~ /org-map/;
    $fulldest = "$dest/$parts[$#parts]";
    print "Copying $file to $fulldest...";
    if (copy ($file, $dest)) {
      print LOG "Copy $file to $fulldest\n";
      print "done!\n";
      if ($dir =~ /bin/) {
        if (!-x $fulldest && $fulldest !~ /README/ && $fulldest !~ /txt$/) {
          chmod (0755, $fulldest);
        }
      }
    } else {
      print LOG "Error copying $file to $dest\n";
      print "Error copying $file to $dest\n";
    }
  }
}
