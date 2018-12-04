#!/usr/bin/perl
#
# first set up configuration file
# then, copy over all the files to the right locations #
use warnings;
use strict;
use Getopt::Long;
use File::Copy;

my $config_file = "/etc/genome-tools.conf";
my $log_file = "setup.log";
my $response;
my $root_ok;
my $ROOTPATH;
my $genomes_ok;
my $GENOMESPATH;
my $binpath_ok;
my $BINPATH;
my $sbinpath_ok;
my $SBINPATH;
my $libpath_ok;
my $LIBPATH;
my $orgmap_ok;
my $orgmap_path;
my $orgcode_ok;
my $orgcode;
my $path;
my $dir;
my $dest;
my $file;
my @parts;
my $fulldest;

GetOptions ('config=s' => \$config_file,
            'log=s' => \$log_file);
die "No configuration file specified\n" if $config_file eq "";

if (-f $config_file) {
  print "It seems that $config_file exists already.  Overwrite this file? (y/N) ";
  $response = <>;
  if ($response !~ /^y/i) { die "Aborting setup...\n"; }
}
open CONF, ">$config_file" || die "Cannot open $config_file for writing.  Aborting.\n";
open LOG, ">$log_file";

# we need to set 4 variables, and another optional variable.
print '
$ROOTPATH is the top directory where the files will be installed.
Typical choices for this variable would be /usr/local or /usr.
(Please don\'t use the root directory, /).

';
$root_ok = 0;
while (!$root_ok) {
  print "Enter value for \$ROOTPATH: (/usr/local) ";
  $ROOTPATH = <>;
  $ROOTPATH = notrail($ROOTPATH);
  if ($ROOTPATH eq "") { $ROOTPATH = "/usr/local"; }
  $root_ok = checkpath ($ROOTPATH);
  if (!$root_ok) { print "Invalid value $ROOTPATH for \$ROOTPATH.\n"; }
}

print '
$GENOMESPATH is the directory where all the genome data files will be stored.
Typical choices for this variable would be /usr/local/lib/Genomes or
/usr/lib/Genomes.

';
$genomes_ok = 0;
while (!$genomes_ok) {
  print "Enter value for \$GENOMESPATH: (/usr/local/lib/Genomes) ";
  $GENOMESPATH = <>;
  $GENOMESPATH = notrail($GENOMESPATH);
  if ($GENOMESPATH eq "") { $GENOMESPATH = "/usr/local/lib/Genomes"; }
  $genomes_ok = checkpath ($GENOMESPATH);
  if (!$genomes_ok) { print "Invalid value $GENOMESPATH for \$GENOMESPATH.\n"; }
}

print '
The next few path variables should probably be left as their defaults.
You can accept the defaults (shown in parentheses) by just hitting <Enter>.

$BINPATH is the directory where the regular user programs are.
$LIBPATH is the directory where the org-map database file is.
$SBINPATH is the directory where the administrative programs are.

';
$binpath_ok = 0;
while (!$binpath_ok) {
  print "Enter value for \$BINPATH: ($ROOTPATH/bin) ";
  $BINPATH = <>;
  $BINPATH = notrail($BINPATH);
  if ($BINPATH eq "") { $BINPATH = "$ROOTPATH/bin"; }
  $binpath_ok = checkpath ($BINPATH);
}
$libpath_ok = 0;
while (!$libpath_ok) {
  print "Enter value for \$LIBPATH: ($ROOTPATH/lib) ";
  $LIBPATH = <>;
  $LIBPATH = notrail($LIBPATH);
  if ($LIBPATH eq "") { $LIBPATH = "$ROOTPATH/lib"; }
  $libpath_ok = checkpath ($LIBPATH);
}
$sbinpath_ok = 0;
while (!$sbinpath_ok) {
  print "Enter value for \$SBINPATH: ($ROOTPATH/sbin) ";
  $SBINPATH = <>;
  $SBINPATH = notrail($SBINPATH);
  if ($SBINPATH eq "") { $SBINPATH = "$ROOTPATH/sbin"; }
  $sbinpath_ok = checkpath ($SBINPATH);
}

print '
Perl needs to be able to find the Orgmap.pm file.  Looking at your
configuration, it seems that perl will look in the directories listed below.
It is difficult for me to recommend which one to use, but you should hopefully
be able to pick a reasonable choice from the following options
(do not choose "."):

';
print join ("\n", @INC), "\n\n";
$orgmap_ok = 0;
while (!$orgmap_ok) {
  print "Enter the path to copy Orgmap.pm to: ";
  $orgmap_path = <>;
  $orgmap_path = notrail($orgmap_path);
  foreach $path (@INC) {
    if ($path eq $orgmap_path) { $orgmap_ok = 1; }
  }
  if ($orgmap_path eq ".") { $orgmap_ok = 0; }
  if (!$orgmap_ok) {
    print "Invalid value $orgmap_path for location of Orgmap.pm.\n";
  }
}

print '
Last question.  This can be left blank.  You may specify a default orgcode
to use if there is none specified on the command line.
If you don\'t know what to use here, you can leave it blank now and later
edit the generated configuration file manually.
Remember, an orgcode should be the 4-letter abbreviation found in the first
column of an org-map line.

';
$orgcode_ok = 0;
while (!$orgcode_ok) {
  print "Enter default orgcode: () ";
  $orgcode = <>;
  chomp $orgcode;
  if ($orgcode eq "" || length($orgcode) == 4) { $orgcode_ok = 1; }
  if (!$orgcode_ok) { print "Invalid value for \$orgcode.\n"; }
}
print "\n";

# write out the config file

print "Writing $config_file...";
print CONF '#
# genome-tools.conf - configuration file for genome-tools package
#
# The syntax for this file is standard Perl syntax
# The following variables must be set in this file, (default setup values shown:
#
#   $ROOTPATH = "/usr/local";
#   $GENOMESPATH = "/usr/local/lib/Genomes";
#   $BINPATH = "/usr/local/bin";
#   $LIBPATH = "/usr/local/lib";
#   $SBINPATH = "/usr/local/sbin";
#   $default_orgcode = "";
#
';
print CONF "\$ROOTPATH = \"$ROOTPATH\";\n";
print CONF "\$GENOMESPATH = \"$GENOMESPATH\";\n";
print CONF "\$BINPATH = \"$BINPATH\";\n";
print CONF "\$LIBPATH = \"$LIBPATH\";\n";
print CONF "\$SBINPATH = \"$SBINPATH\";\n";
print CONF "\$default_orgcode = \"$orgcode\";\n";
print "done!\n";
print LOG "Created $config_file\n";

# make all the appropriate directories

foreach $path ($ROOTPATH, $GENOMESPATH, $BINPATH, $LIBPATH, $SBINPATH, $orgmap_path) {
  if (!-d $path) { mkdir ($path); }
}

# copy all the files over
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

print "\n\nNOTE: A log of all the files created/copied by this setup script\n";
print "is stored in $log_file, in case you need to uninstall later.\n";
print "\nYou will still need to install genome data files, probably easiest\n";
print "using the update-genome.pl script which is now installed in $SBINPATH\n";
print "You can get help by running\n";
print "  > update-genome.pl --help\n";
print "\nGood luck, and I hope genome-tools helps you.\n";

sub notrail {
  my ($path) = @_;
  chomp $path;
  if ($path eq "/") { return $path; }
  if ($path =~ /\/$/) { $path =~ s/\/$//; }
  return ($path);
}

sub checkpath {
# make sure that if the path exists, that it's a directory (and not a file)
# also ok if it doesn't exist
# not ok if it is the root directory
  my ($path) = @_;
  if (-e $path && !-d $path) { return (0); }
  if ($path eq "/") { return (0); }
  else { return (1) };
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
