#!/usr/local/bin/perl -w
# ======================================================================
#+
$usage = "

NAME
        sex2imcat.pl

PURPOSE
        Convert a SExtractor catalogue into imcat format.

USAGE
        sex2imcat.pl [flags] [options] input.scat

FLAGS
        -u        print this message
        -v        Verbose output

INPUTS
        input.scat      ASCII_HEAD catalogue from SExtractor, this version
                        will figure out all the variables itself

OPTIONAL INPUTS
        -o file         write output to \"file\" (def=STDOUT)
        -f file         corresponding image fits file (def=input.fits)
        -z magzero      photometric zero point used by SExtractor

OUTPUTS
        STDOUT          Filtered catalogue

COMMENTS

EXAMPLES

BUGS

REVISION HISTORY:
  2003-05-??  Started Marshall (MRAO)
  2005-12-21  Added pat format.
  2006-06-19  Generalized to any numeric-only catalogue Bradac (KIPAC)

\n";
#-
# ======================================================================

$sdir = $ENV{'SCRIPTUTILS_DIR'};
require($sdir."/perl/esystem.pl");
require($sdir."/perl/trimwhitespace.pl");
$doproc = 1;

use Getopt::Long;
GetOptions("o=s", \$outfile,
           "f=s", \$fitsfile,
           "z=f", \$zp,
           "v", \$vb,       
           "u", \$help       
           );

(defined($help)) and die "$usage\n";
$num=@ARGV;
($num>0) or die "$usage\n";

if (defined($vb)){
$vb = 1;
} else {
$vb = 0;
}

$flush=0;
(defined($outfile)) or ($flush = 1);
$sensible=0;
(defined($fitsfile)) or ($sensible = 1);
$getzp=0;
(defined($zp)) or ($getzp = 1);

($vb) and print STDERR "Doing checks...\n";
# Check for imcat environment:

(defined($ENV{"IMCAT_DIR"})) or die "Imcat environment undefined.\n";

# Check for existence of catalogue:

$scatfile = shift @ARGV;
(-e $scatfile) or die "sex2imcat: $scatfile not found.\n";
($vb) and print STDERR "Using SExtractor catalogue file $scatfile\n";

# Set fits file name if required:

if ($sensible == 1) {
  $fitsfile = $scatfile;
  $fitsfile =~ s/(.*)\..*/$1\.fits/;
  ($fitsfile ne $scatfile) or die "Input file extension must be .scat\n";
}

# Check for existence of fits file, and use it!:

if (-e $fitsfile) {
  ($vb) and print STDERR "Using fits file $fitsfile\n";
# Extract image size:
  $fitsline = " ";
  if (-e $fitsfile) {
  ($vb) and print STDERR "Extracting image size...\n";
  chomp($xs = `stats -v N1 < $fitsfile`);
  chomp($ys = `stats -v N2 < $fitsfile`);
  ($vb) and print STDERR "...file is $xs by $ys.\n";
# Extract photometric zero point:
  ($vb) and print STDERR "Sorting out zero point...\n";
  if ($getzp == 1) {
    chomp($zp = `/u/ki/pjm/imcat/bin/linux/imhead -v PHOTOZP < $fitsfile`);
  }
  ($vb) and print STDERR "...zero point is $zp.\n";
  $fitsline =  "-H 'fits_name = {$fitsfile}' -H 'fits_size = $xs $ys 2 vector' -H 'has_sky = 0' -H 'magzero = $zp'" 
  }
} else {
  ($vb) print  STDERR "$fitsfile not found, skipping this feature\n";
}

# Do imcat conversion:

($vb) and print STDERR "Cranking up imcat and figuring out which variables to use...\n";

  open (IN, $scatfile) or die "$scatfile: $!";
@keywords =();
$keys = 1;
$imcatline = "";
while (defined($inline = <IN>) and ($keys)) {
    if ($inline =~ /^\#/){
	chomp($inline);
	$ls=length($inline);
	$rest=$ls - 70;
	(($ls > 5) and ($id = trimwhitespace(substr($inline, 3, 2)))) or ($id = 0);
	(($ls > 21) and ($name = trimwhitespace(substr($inline, 6, 15)))) or ($name = " ");
	(($ls > 69) and ($desc = trimwhitespace(substr($inline, 21, 48)))) or ($desc = " ");
	(($ls > 70) and ($units = trimwhitespace(substr($inline, 70, $rest)))) or ($units = " ");
	print STDERR "$id $name $units $desc\n";
	push @keywords,{id => $id, name =>  $name, desc =>  $desc, units => $units};
	$imcatline = $imcatline." -n $name "; 
    }
    else { $keys = 1;}
}

&esystem("lc -C -L 0 -x -a {history:\\ Converted\\ from\\ SExtractor\\ with\\ sex2imcat.pl}  $imcatline < $scatfile  | lc  'id = %NUMBER' 'x = %X_IMAGE %Y_IMAGE 2 vector' 'fwhm = %FWHM_IMAGE' 'star = %CLASS_STAR' 'a = %A_IMAGE' 'b = %B_IMAGE' 'th = %THETA_IMAGE' 'smag = %MAG_BEST' 'flags = %FLAGS' +all ${fitsline} | lc +all 'x = \%x 0.5 0.5 2 vector vsub' | lc -x -a history:\\ SExtractor\\ ellipticities\\ added\\ by\\ sex2imcat.pl +all 'es = \%a \%b - 0.034906585 \%th * cos * \%a \%b + / \%a \%b - 0.034906585 \%th * sin * \%a \%b + / 2 vector' > junk", $doproc, 0);



#Do output:

($vb) and print STDERR "Outputting:...\n";
if ($flush == 1) {
  &esystem("cat junk", $doproc, $vb);
  &esystem("rm junk", $doproc, $vb);
} else {
  &esystem("mv junk $outfile", $doproc, $vb);
}

# ======================================================================
sub trimwhitespace($)
{
        my $string = shift;
        $string =~ s/^\s+//;
        $string =~ s/\s+$//;
        return $string;
}
# ======================================================================
