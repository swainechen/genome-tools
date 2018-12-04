#!/usr/bin/perl 

use warnings;
use strict;
use Orgmap qw($LIBPATH $SBINPATH $GENOMESPATH);
use Getopt::Long;
use File::Temp;
&Getopt::Long::Configure("pass_through");

my $lsCmd = `which ls`;		# ls needed - assuming Unix (usually)
chomp($lsCmd);
my $wgetCmd = `which wget`;	# wget needed to download files
chomp($wgetCmd);
my $response;			# generic standard input variable
my @orgmap;			# holds contents of current org-map
my %orgcodes;			# holds all known orgcodes so we don't repeat
my $orgmapLoc = "$LIBPATH/org-map";
my $urlBase = 'ftp://ftp.ncbi.nih.gov/genomes/Bacteria';
my @dlExts = ('.faa', '.ffn', '.fna', '.gbk', '.ptt');
				# Extensions of genome files we wish to download
my @directories;		# directories to download, from cmdline or file
my $ncbiDirName;		# variable to hold individual directory name
my @errors;			# stores directories which had errors
my $infile = '';
my $batch = -1;
my $all = 0;			# the -all option overrides all other options
my $help = 0;			# except for -help, which overrides -all
my $tempdir = File::Temp::tempdir( CLEANUP => 1 );
my $in;
my $i;
my @f;
my $dummy_geneformat = "NUL####";
my $default_genecol = 5;
my $default_desccols = "4,8";
my $download_new;

GetOptions ('infile=s' => \$infile,
            'batch' => \$batch,
            'all' => \$all,
            'help' => \$help);

if ($help) { &PrintUsage; }

if ($all) {
  $batch = 1;
  $infile = '';
} else {
  if ($infile eq '' || !-f $infile) {
    @directories = @ARGV;
    if ($batch == -1) { $batch = 0; }	# if directories on command line,
					# default to interactive
  } else {
    open (IN, $infile) || die "Cannot open $infile";
    @directories = <IN>;
    close IN;
    if ($batch == -1) { $batch = 1; }	# if a file is given, presume multiple
					# directories requested, default batch
  }
}

# make sure org-map file exists
if (-f $orgmapLoc) {
  open (ORGMAP, $orgmapLoc) || die "Could not read $orgmapLoc";
  @orgmap = <ORGMAP>;
  foreach $i (@orgmap) {
    next if $i =~ /^#/;
    next if $i =~ /^$/;
    @f = split /\t/, $i;
    $orgcodes{$f[0]} = 1;
  }
  open (ORGMAP, ">>$orgmapLoc") || die "Could not open $orgmapLoc for writing";
} else {
  if ($batch) {
    $response = 'y';
  } else {
    print "I cannot find your org-map file.\nWould you like me to make one for you? (Y/n) ";
    $response = <STDIN>;
  }
  if ($response !~ m/^y/i && $response !~ /^$/) { exit (1); }
  @orgmap = ();
  open (ORGMAP, ">$orgmapLoc") || die "Could not create file $orgmapLoc for writing";
  print ORGMAP join ("\t", "# orgcode", "directory/accession", "geneformat", "gene field", "annotation fields", "genus/species", "strain", "orgID", "topology (0=circular)"), "\n";
}
close ORGMAP;

# If this is a fresh system with no genomes, make sure $GENOMESPATH exists
if (-d $GENOMESPATH) { chdir $GENOMESPATH; }
else {
  mkdir $GENOMESPATH;
  chdir $GENOMESPATH;
}

# if doing this in batch mode we need to know the org-map lines
# since we're going to download from NCBI, I'm assuming internet access
if ($all && scalar @directories == 0) {
  chdir $tempdir;
  system "wget -q -np $urlBase/";
  open LIST, "index.html";
  while ($in = <LIST>) {
    next if $in !~ /\s+Directory\s+/;
    $in =~ /<a href=".*?">(.*?)<\/a>/;
    if (length $1) { push @directories, $1; }
  }
  close LIST;
  unlink "index.html";
  chdir $GENOMESPATH;
}

# get the directory name and see if it exists
while ($ncbiDirName = shift(@directories)) {

  next if $ncbiDirName =~ /^#/;
  chomp $ncbiDirName;
  $wgetCmd .= " -nv -r -N -l1 --no-parent -A" . join(",", @dlExts) . " -nd -P $ncbiDirName";

  # Check if this directory already has been downloaded
  if (-d $ncbiDirName) {
    if ($batch) {
      $response = 'y';
    } else {
      print "It appears the directory $ncbiDirName already exists locally.\nShould we proceed with download (overwriting older files)? (Y/n) ";
      $response = <STDIN>;
    }
    if ($response !~ m/^y/i && $response !~ m/^$/) {
      $download_new = 0;
      next;
    } else {
      $download_new = 1;
    }
  }

  if ($download_new) {
    print "Downloading files in $ncbiDirName directory on NCBI FTP site...\n";
    system "$wgetCmd $urlBase/$ncbiDirName/";
  }

  # make sure something got downloaded
  if (-d $ncbiDirName) {
    chdir $ncbiDirName;
  } else {
    push @errors, $ncbiDirName;
    print STDERR "Error no files in $ncbiDirName directory, skipping\n\n";
    next;
  }

  # Now, figure out if there are multiple replicons
  # We will use the .asn files first to get the NCBI Website ID#,
  # then we will use the .gbk files to get the NCBI Accession NC_######
  # and then name of the genome sequence.
  my @gbkFiles = `$lsCmd -1 *.gbk`;
  foreach my $replicon (@gbkFiles) {
    chomp($replicon);
    my ($accession, $projectID, $species, $definition, $linear);

    if ($replicon =~ /([\w\_\d]+)\.asn/) {
      $accession = $1;

      # Parse out the project ID, species, definition, and topology
      open(GBK, "$accession.gbk") || die "Could not open $accession.gbk file";
      while(<GBK>) {
        chomp;
        if (/^LOCUS\s+.*?\s+(circular|linear)\s+/) {
          if ($1 eq 'circular') {
            $linear = 0;
          } else {
            $linear = 1;
          }
        }
        if (/^DEFINITION\s+(\w+\s\w+)[,\s]+(.*)$/) {
          $species = $1;
          $definition = $2;
          $definition =~ s/,?\s?complete\s(genome|sequence)\.//;
        }
        if (/^DBLINK\s+Project:\s+(\d+)/) {
          $projectID = $1;
        }
      }
      close(GBK);
    }

    # Look in orgmap to see if this is already present based on directory name
    # and accession number
    # In the future this may be able to handle/fix multiple entries for the
    # same data files.  For now, though it will only look at the first match
    my @grepline = ();
    foreach my $i (0..$#orgmap) {
      my @f = split /\t/, $orgmap[$i];
      if ($f[1] eq "$ncbiDirName/$accession") {
        push @grepline, $i;
        last;
      }
    }

    my $orgmapLine;		# holds the new org-map line
    my ($code, $geneformat, $genecol, $desccols);	# org-map fields
    if (scalar @grepline) {
      if ($batch) {
        $response = 'y';
      } else {
        print "\nThere seems to be an orgmap line already for these data files:\n";
        print "-----\n$orgmap[$grepline[0]]-----\n";
        print "Is the above line correct? (Y/n) ";
        $response = <STDIN>;
      }
      if ($response !~ /^y/i && $response !~ /^$/) {
        # update the org-map line with the new values
        ($code, $geneformat, $genecol, $desccols) = PromptFields ($species, $definition, $accession);
        $orgmapLine = join ("\t", $code, "$ncbiDirName/$accession", $geneformat, $genecol, $desccols, $species, $definition, $projectID, $linear);
        $orgmap[$grepline[0]] = "$orgmapLine\n";
        open ORGMAP, ">$orgmapLoc";
        print ORGMAP @orgmap;
        close ORGMAP;
      } else {
        # don't need to modify org-map
        $orgmapLine = $orgmap[$grepline[0]];
        ($code, undef, $geneformat, $genecol, $desccols, $species, $definition, $projectID, $linear) = split /\t/, $orgmap[$grepline[0]];
      }
    } else {
      # append the new org-map line
      if ($batch) {
        # give it a default
        $orgmapLine = join ("\t", systematic_orgcode($ncbiDirName), "$ncbiDirName/$accession", $dummy_geneformat, $default_genecol, $default_desccols, $species, $definition, $projectID, $linear);
        $code = (split /\t/, $orgmapLine)[0];
        if ($orgmapLine !~ /$accession/) {
          print STDERR "Could not find standard org-map line for $ncbiDirName $accession...Skipping.\n";
          next;		# foreach $replicon
        }
      } else {
        ($code, $geneformat, $genecol, $desccols) = PromptFields ($species, $definition, $accession);
        $orgmapLine = join ("\t", $code, "$ncbiDirName/$accession", $geneformat, $genecol, $desccols, $species, $definition, $projectID, $linear);
      }
      open ORGMAP, ">>$orgmapLoc";
      print ORGMAP "$orgmapLine\n";
      close ORGMAP;
    }

    print "\n";
    print "Genome files downloaded, org-map file updated successfully.\n";

  }		# foreach $replicon

  chdir "..";

}		# while $ncbiDirName

close(ORGMAP);
if (scalar @errors) {
  print STDERR "There were errors encountered for the following directories (perhaps check for\n";
  print STDERR "spelling or capitalization errors?):\n";
  print STDERR join ("\n", @errors);
  print STDERR "\n";
}

sub systematic_orgcode {
  # format will be aaaa, aaab, aaac, etc.
  # check against %orgcodes
  # try to use strain info if possible
  my ($directory) = @_;
  my @f = split /_/, $directory; 
  my $field = 2;
  my $candidate = "";
  while (defined $f[$field]) {
    if ($f[$field] eq "ATCC") { $field++; };
    if ($f[$field] =~ /^uid/) { $candidate = ""; }
  }
  if ($candidate eq "" || defined $orgcodes{$candidate}) {
    $candidate = 'aaaa';
    while (defined $orgcodes{$candidate}) {
      $candidate++;
    }
  }
  return $candidate;
}

sub PromptFields {
  # Now we will prompt for the things we need to get by hand:
  # orgcode, geneformat, genefields, descfields
  my ($species, $definition, $accession) = @_;
  print "Please enter the orgcode for $species $definition\n";
  my $code = <STDIN>;
  chomp($code);
  print "\n";
  print "Some lines from the .ptt file are shown below.\n\n";
  system "head -n 9 $accession.ptt | tail -n 3";
  print "\n";
  print "Usually there is a systematic gene name for each gene, which consists of a\n";
  print "prefix plus a few numbers - for the systematic gene name format, please type in\n";
  print "the prefix followed by as many pound (#) symbols as there are numbers.\n";
  print "For example, if the systematic gene names are CC0001, CC0002, etc. then the\n";
  print "format should be 'CC####' (do not type the quotes).\n";
  print "Based on the .ptt lines above, what is the systematic gene name format?($dummy_geneformat)\n";
  my $geneformat = <STDIN>;
  chomp($geneformat);
  if (length($geneformat) < 1) { $geneformat = $dummy_geneformat; }
  print "Now, I will show you the column numbers (0-based) for the fields of the last\n.ptt line shown above.\n\n";
  my @f = split /\t/, `head -n 9 $accession.ptt | tail -n 1`;
  print "Column\tField\n";
  print "------\t-----\n";
  foreach my $i (0..$#f) {
    print "$i\t$f[$i]\n";
  }
  print "Use the above column numbers to answer the following questions.\n";
  print "What is the column number containing the systematic gene name? ($default_genecol)\n";
  my $genecol = <STDIN>;
  chomp($genecol);
  if (length($genecol) < 1) { $genecol = $default_genecol; }
  print "What is the comma-deliminated list of columns for the gene description? ($default_desccols)\n";
  my $desccols = <STDIN>;
  chomp($desccols);
  if (length($desccols) < 1) { $desccols = $default_desccols; }
  return ($code, $geneformat, $genecol, $desccols);
}

sub PrintUsage {
format =
Usage:
  update-genome.pl [-b] <NCBIdir> [ <NCBIdir2> [ <NCBIdir3> [...] ] ]
  update-genome.pl [-b] -i <file>
  update-genome.pl -all
  update-genome.pl --help

-b 	indicates batch mode, response to all questions will default to "yes"
	(which usually means to overwrite local files).  For all data files
	downloaded, it will look first in your current org-map, and if it finds
	an org-map line for the data files (based on accession number) then it
	will keep that line.  If it can't find a line which matches the
	accession number, it will look in a "standard" org-map file located
	at "http://genome-tools.sourceforge.net/org-map.standard".  If it still
	can't find it there, then it will skip processing those data files.
	You will need to run update-genome.pl in interactive mode (without the
	-b option) to get it to prompt you for the org-map data fields.  It is
        probably best to try to run in batch mode when you can, but it's
        a little safer to run interactively, which is why the default behavior
        is to run interactively.

<NCBIdir> indicates the directory containing files to be downloaded.  The
	program will download ftp://ftp.ncbi.nih.gov/genomes/Bacteria/<dir>.
	Do not type the brackets (<>).  For a list of directories which are
        valid, you can check
        http://genome-tools.sourceforge.net/org-map.directories

-i <file> tells the program to look in <file> for a list of directories to
	download data from.  Batch mode (the -b option) is assumed when you
	use the -i <file> option, so be careful, this will automatically
	overwrite any local versions of files that it comes across.  The file
	containing the directories should have one directory per line.  Lines
	beginning with the pound sign (#) will be skipped.

-all	will download all the curated prokaryotic genomes from GenBank.  The
	list of genomes will come from a "standard" list which corresponds
	to the "standard" org-map file mentioned above.

--help	Prints this help screen.

.
write;
exit (-1);
}
