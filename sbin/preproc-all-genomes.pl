#!/usr/bin/perl
#
# preproc-all-genomes.pl
# ----------------------
# Script that runs preproc-new-genome.pl on all genomes listed
# in org-map and directs log files appropriately.
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

use Orgmap qw(:DEFAULT $LIBPATH $SBINPATH $GENOMESPATH);

my @orgmap;
my $org;
my @orgLine;
my @genomeDir;
my $genomeDir;
my $accession;

open(ORGMAP, "$LIBPATH/org-map") || die "Could not open org-map file.";
@orgmap = <ORGMAP>;
close(ORGMAP);

foreach $org (@orgmap) {
  chomp($org);
  @orgLine = split /\t/, $org;

  @genomeDir = split /\//, $orgLine[1];
  $accession = pop @genomeDir;
  shift @genomeDir;
  $genomeDir = join '/', @genomeDir;

  chdir "$GENOMESPATH/$genomeDir" || die "Could not chdir to $GENOMESPATH/$genomeDir.";
  print "*** Running preproc-new-genome on $orgLine[0] ***\n";
  system "rm -f *.trna-stats";
  system "rm -f *.marginal-codons";
  system "$SBINPATH/preproc-new-genome.pl $orgLine[0] 2>&1 | tee $accession.preproc.log";
}
