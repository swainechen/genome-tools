#!/usr/bin/perl
#
# make a circular map
# mark off beginning and end
# label in the middle
# mark specified locations with tick marks, in color
# positive marks to outside, negative to inside
# can specify color with number after location
# default colors are red on outside, cyan on inside (negative)
# if a line starts with "label" then the next field will be taken as
#   a text label, and it will be written below the genome name in the
#   center with the hue specified by the third field of that line
#
use warnings;
use strict;
use Orgmap qw(:DEFAULT read_sequence $sequence $topology $orgname $subname $pttfile $genefield);
&read_orgmap;
&read_sequence;

# variables
my $genome_length;
my @ptt;
my $line;
my $center;
my @f;
my %ptt;
my $size;
my $outfile;

$genome_length = length($sequence);
open PTT, $pttfile;
@ptt = <PTT>;
close PTT;
foreach $line (@ptt) {
  if ($line =~ m/^\s*(\d+)\.\.(\d+)\s/) {
    $center = ($1 + $2)/2;
    @f = split /\t/, $line;
    $f[1] =~ s/\s+//;	# strand
    $ptt{$f[$genefield]} = $f[1].$center;
  }
}
use Getopt::Long;
&Getopt::Long::Configure("pass_through");
$size = 10;
$outfile = '';
GetOptions ('size=i' => \$size,
            'outfile=s' => \$outfile);
if ($outfile !~ m/\.ps$/) { $outfile .= '.ps'; }

my $ticklength = 0.5;
my $label_increment = 0.2;
my $positive_hue = 0;
my $negative_hue = 0.5;
my $hue = -1;
my $pi = 3.14159265359;
my $radius = $size/2;
my $x_off = $radius + $ticklength;
my $y_off = $radius + $ticklength;
my $text_x = $x_off;
my $text_y = $y_off;
my $text_off = $radius/10;
my ($x1, $y1, $x2, $y2);
my $text_label;
my $text_hue;
my $coordinate;
my $negative;

open GRI, "| gri -nowarn_offpage -batch -output $outfile";
if ($topology == 0) {
  print GRI "draw circle with radius $radius at $x_off $y_off\n";
  print GRI "draw label \"$orgname genome, $genome_length bp\" centered at $x_off $y_off cm\n";
  ($x1, $y1) = cartesian($radius + 1, 0);
  ($x2, $y2) = cartesian($radius - 1, 0);
  print GRI "draw line from $x1 $y1 to $x2 $y2 cm\n";
  $x1 += $label_increment;
  print GRI "draw label \"1\" at $x1 $y1 cm\n";
  $x1 -= 2*$label_increment;
  print GRI "draw label \"$genome_length\" rightjustified at $x1 $y1 cm\n";
  while (<>) {
    next if /^#/;
    chomp;
    if ($_ =~ m/^label/i) {
      @f = split /\s+/, $_;
      $text_label = join " ", @f[1..($#f-1)];
      $text_hue = $f[$#f];
      $text_y -= $text_off;
      if ($text_hue < 0) {
       print GRI "set color hsb 0 0 0\n";
      } else {
        print GRI "set color hsb $text_hue 1 1\n";
      }
      print GRI "draw label \"$text_label\" centered at $text_x $text_y cm\n";
      next;
    }
    if ($_ =~ m/^\s*(\d+)\.\.(\d+)\s*(.*?)$/) {
      $coordinate = ($1 + $2)/2;
      if ($1 > $2) { $negative = 1; } else { $negative = 0; }
      if (defined $3 && $3 ne '' && $3 >= 0) {
        $hue = $3;
        while ($hue > 1) { --$hue; }
      }
    } elsif ($_ =~ m/^\s*([-+]?\d+)\s*(.*?)$/) {
      if ($1 < 0) { $negative = 1; } else { $negative = 0; }
      $coordinate = abs($1);
      if (defined $2 && $2 ne '' && $2 >= 0) {
        $hue = $2;
        while ($hue > 1) { --$hue; }
      }
    } else {
      @f = split /\s+/, $_;
      $f[0] =~ s/^[-+]//;
      if (defined $ptt{$f[0]}) {
        $coordinate = abs ($ptt{$f[0]});
        if ($ptt{$f[0]} < 0) { $negative = 1; } else { $negative = 0; }
        if (defined $f[1] && $f[1] ne '' && $f[1] >= 0) {
          $hue = $f[1];
          while ($hue > 1) { --$hue; }
        }
      } else {
        next;
      }
    }
    ($x1, $y1) = cartesian($radius, $coordinate/$genome_length);
    if (!$negative) {
      ($x2, $y2) = cartesian($radius+$ticklength, $coordinate/$genome_length);
      if ($hue == -1) { $hue = $positive_hue; }
    } else {
      ($x2, $y2) = cartesian($radius-$ticklength, $coordinate/$genome_length);
      if ($hue == -1) { $hue = $negative_hue; }
    }
    print GRI "set color hsb $hue 1 1\n";
    print GRI "draw line from $x1 $y1 to $x2 $y2 cm\n";
    $hue = -1;
  }
}

sub cartesian {		# a little different because start 0 rad at (0,1)
			# go clockwise as radians increase
			# actually don't use radians, but relative distance
			# around the circle, i.e. 1 is all the way around again
  my ($r, $theta) = @_;
  my $x = $r * sin(2*$pi*$theta) + $x_off;
  my $y = $r * cos(2*$pi*$theta) + $y_off;
  return ($x, $y);
}
