#!/bin/tcsh
#=======================================================================
#+
# NAME:
#   Mstar.csh
#
# PURPOSE:
#   Estimate stellar mass from input absolute magnitude and/or colour[s]
#
# COMMENTS:
#   Bell and De Jong coeffs from 2001 may be dodgy - avoid V-* color input
# 
# INPUTS:
#   M                 Absolute magnitude 
#  
# OPTIONAL INPUTS:
#  -B                 Interpret M as MB Vega [def is M = MK Vega]
#  -g                 Interpret M as Mg AB [def is M = MK Vega]
#  -B-V               B-V colour (Vega, corrected)
#  -B-R               B-R colour (Vega, corrected)
#  -V-I               V-I colour (Vega, corrected)
#  -V-J               V-J colour (Vega, corrected)
#  -V-H               V-H colour (Vega, corrected)
#  -V-K               V-K colour (Vega, corrected)
#  -g-r               g-r colour (AB, corrected)
#  -g-i               g-i colour (AB, corrected)
#  -g-z               g-z colour (AB, corrected)
#  -r-i               r-i colour (AB, corrected)
#  -r-z               r-z colour (AB, corrected)
#  -B-K               B-K colour (Vega, corrected)
#
# OUTPUTS:
#   stdout            log10 Mstar/Msun
#
# EXAMPLES:
#
# BUGS:
#
# REVISION HISTORY:
#   2007-08-02  started Marshall (UCSB)
#-
#=======================================================================

# Options and arguments:

set help = 0
set vb = 0
set M = 0
set colour = 0
set colourindex = 0
set BV = 0
set Lfilter = 'K'

while ( $#argv > 0 )
   switch ($argv[1])
   case -h:
      set help = 1
      shift argv
      breaksw
   case --help:
      set help = 1
      shift argv
      breaksw
   case -v:        
      set vb = 1
      shift argv
      breaksw
   case --{verbose}:
      set vb = 1
      shift argv
      breaksw
   case -K:        
      set Lfilter = 'K'
      shift argv
      breaksw
   case -g:        
      set Lfilter = 'g'
      shift argv
      breaksw
   case -B:        
      set Lfilter = 'B'
      shift argv
      breaksw
   case -{B-V}:
      shift argv
      set colourindex = 1
      set colour = $argv[1]
      shift argv
      breaksw
   case -{B-R}:
      shift argv
      set colourindex = 2
      set colour = $argv[1]
      shift argv
      breaksw
   case -{V-I}:
      shift argv
      set colourindex = 3
      set colour = $argv[1]
      shift argv
      breaksw
   case -{V-J}:
      shift argv
      set colourindex = 4
      set colour = $argv[1]
      shift argv
      breaksw
   case -{V-H}:
      shift argv
      set colourindex = 5
      set colour = $argv[1]
      shift argv
      breaksw
   case -{V-K}:
      shift argv
      set colourindex = 6
      set colour = $argv[1]
      shift argv
      breaksw
   case -{g-r}:
      shift argv
      set colourindex = 7
      set colour = $argv[1]
      shift argv
      breaksw
   case -{g-i}:
      shift argv
      set colourindex = 8
      set colour = $argv[1]
      shift argv
      breaksw
   case -{g-z}:
      shift argv
      set colourindex = 9
      set colour = $argv[1]
      shift argv
      breaksw
   case -{r-i}:
      shift argv
      set colourindex = 10
      set colour = $argv[1]
      shift argv
      breaksw
   case -{r-z}:
      shift argv
      set colourindex = 11
      set colour = $argv[1]
      shift argv
      breaksw
   case -{B-K}:
      shift argv
      set colourindex = 12
      set colour = $argv[1]
      shift argv
      breaksw
   case *:
      if ($M == 0) set M = $argv[1]
      shift argv
      breaksw
   endsw
end

#-----------------------------------------------------------------------

# Catch stupidities, set up variables:

if ($help) then
  print_script_header.csh $0
  goto FINISH
endif

if ($M == 0) then
  echo "${0:t}: no absolute magnitude provided, aborting"
  goto FINISH
endif  
if ($Lfilter == 'B' && $colourindex > 6 && $colourindex < 12) then
  echo "${0:t}: with B-band absolute magnitude, must use Johnson Vega colour"
  goto FINISH
endif  

if ($vb) echo "${0:t}: Estimating stellar mass using recipe from"
if ($vb) echo "${0:t}:   Bell & De Jong (2003), Table 7, or"
if ($vb) echo "${0:t}:   Bell & De Jong (2001), Table 1"
if ($vb) echo "${0:t}:   (where scaled Salpeter IMF \\approx Kroupa IMF)"
if ($Lfilter == 'B') then
  if ($vb) echo "${0:t}: given the B-band absolute Vega magnitude M_B = $M"
else if ($Lfilter == 'g') then
  if ($vb) echo "${0:t}: given the g-band absolute AB magnitude M_g = $M"
else 
  if ($vb) echo "${0:t}: given the K-band absolute Vega magnitude M_K = $M"
endif

if ($colourindex == 0) then
  if ($vb) echo "${0:t}: WARNING: no colour information provided, winging it"
endif  

#-----------------------------------------------------------------------
# Get M/L ratio:

# Data from Table 7 from Bell et al (2003), Bell & De Jong (2001): 

set colourname = (\
'B-V'\
'B-R'\
'V-I'\
'V-J'\
'V-H'\
'V-K'\
'g-r'\
'g-i'\
'g-z'\
'r-i'\
'r-z'\
'B-K'\
)

# Coeefficients for use with B or g band luminosity:

set aB = (\
'-0.942'\
'-0.976'\
'-1.919'\
'-1.903'\
'-2.181'\
'-2.156'\
'-0.499'\
'-0.379'\
'-0.367'\
'-0.106'\
'-0.124'\
)

set bB = (\
'1.737'\
'1.111'\
'2.214'\
'1.138'\
'0.978'\
'0.895'\
'1.519'\
'0.914'\
'0.698'\
'1.982'\
'1.067'\
)

# Coeefficients for use with K band luminosity:
# NOTE - big difference between 2001 and 2003 for B-R, B-V here!

set aK = (\
'-0.206'\
'-0.264'\
'-1.027'\
'-1.005'\
'-1.100'\
'-1.087'\
'-0.209'\
'-0.211'\
'-0.138'\
'-0.186'\
'-0.092'\
)

set bK = (\
'0.135'\
'0.138'\
'0.800'\
'0.402'\
'0.345'\
'0.314'\
'0.197'\
'0.137'\
'0.047'\
'0.349'\
'0.019'\
)

# Choose which type -and set the default MLratio.
# g-r for an E spectrum (Kennicutt 1992) is 0.77 (Fukugita et al 1995)
# B-V for an E spectrum (Kennicutt 1992) is 0.96 (Fukugita et al 1995)
# Then *this code* would give the following:

if ($Lfilter == 'K') then
  set a = ( $aK )
  set b = ( $bK )
  set MLratio = 0.88
else if ($Lfilter == 'g') then
  set a = ( $aB )
  set b = ( $bB )
  set MLratio = 4.7
else if ($Lfilter == 'B') then
  set a = ( $aB )
  set b = ( $bB )
  set MLratio = 5.3
endif

# ie these default ML ratios are internally consistent, at least for early type
# galaxies.



# Now, compute new coefficients for non-standard colour:

# Let  a1 + b1*x = c
#      a2 + b2*y = c
#      a3 + b3*z = c  ; what are a3 and b3 if z = x+y?
#
# Answer:  b3 = b1*b2/(b1+b2) (reduced mass)
#          a3 = (b2*a1 + b1*a2)/(b1+b2)  (linear interpolation)
#             = b3*(a1/b1 + a2/b2)

if ($colourindex == 12) then

  set a = ( $aB 0 )
  set b = ( $bB 0 )
  # (B-K) = (B-V) + (V-K)  (colourindex 1, 6)
  set i = 1
  set j = 6

  set b3 = `echo "$b[$i] * $b[$j] / ($b[$i] + $b[$j])" | bc -l`
  set c = `echo $b3 | cut -c1`
  if ($c == '.') set b3 = "0$b3"
  set a3 = `echo "$b3 * ( $a[$i]/$b[$i] + $a[$j]/$b[$j])" | bc -l`
  set c = `echo $a3 | cut -c1` ; set cc = `echo $a3 | cut -c1-2`
  if ($c == '.') set a3 = "0$a3"
  if ($cc == '-.') set a3 = "-0"`echo $a3 | cut -c2-`

  set a[$colourindex] = $a3
  set b[$colourindex] = $b3

  if ($vb) echo "${0:t}: and new coefficients calculated for $colourname[$colourindex] colour:"
  if ($vb) echo "${0:t}:   a = $a[$colourindex]   b = $b[$colourindex]"

endif


# Now compute log10MLratio

if ($colourindex == 0) then
# Guessed M/L ratio!
  if ($vb) then
    echo "${0:t}: WARNING: M/L ratio guessed to be $MLratio based on colors for" 
    echo "${0:t}: E spectrum galaxies (Kennicutt 1992) worked out by Fukugita et al 1995"
  endif
  set log10MLratio = `echo "l($MLratio)/l(10.0)" | bc -l`

else 
# Compute log M/L ratio from recipe:
  if ($vb) then
    echo "${0:t}: and the $colourname[$colourindex] colour provided ($colour):"
    echo "${0:t}: log10MLratio = $a[$colourindex] + $b[$colourindex] * $colourname[$colourindex]"
  endif
  set log10MLratio = \
    `echo "$a[$colourindex] + $b[$colourindex] * $colour" | bc -l`
  
endif

set c = `echo $log10MLratio | cut -c1` ; set cc = `echo $log10MLratio | cut -c1-2`
if ($c == '.') set log10MLratio = "0$log10MLratio"  
if ($cc == '-.') set log10MLratio = "-0"`echo $log10MLratio | cut -c2-`  

set MLratio = `echo "e($log10MLratio * l(10.0))" | bc -l | cut -c1-5`

set c = `echo $MLratio | cut -c1`
if ($c == '.') set MLratio = "0$MLratio"  

if ($vb) echo "${0:t}: log10 M/L = $log10MLratio"
if ($vb) echo "${0:t}:       M/L = $MLratio"


#-----------------------------------------------------------------------
# Convert M/L ratio in to stellar mass:

# Solar absolute magnitude tabulated here:
#   http://www.ucolick.org/~cnaw/sun.html

if ($Lfilter == 'K') then
  set Msun = 3.28
else if ($Lfilter == 'g') then
  set Msun = 5.33
else if ($Lfilter == 'B') then
  set Msun = 5.45
endif

set log10L = `echo "-0.4 * ( $M - $Msun )" | bc -l`

set c = `echo $log10L | cut -c1` ; set cc = `echo $log10L | cut -c1-2`
if ($c == '.') set log10L = "0$log10L"  
if ($cc == '-.') set log10L = "-0"`echo $log10L | cut -c2-`  

if ($vb) echo "${0:t}: log10 L/Lsun = $log10L"

# And now add to MLratio to get M*:

set log10Mstar = `echo "$log10MLratio + $log10L" | bc -l`

if ($vb) then
  echo "${0:t}: log10 M*/Msun = $log10Mstar"
else
  echo "$log10Mstar"
endif

#-----------------------------------------------------------------------------

# Clean up:

FINISH:

#=============================================================================
# Example text from Gallo et al 2008, describing the use of this script in the
# AMUSE-Virgo project:
# 
# Published measurements by the ACSVCS group (F06) were used to estimate the
# total B-band luminosity and stellar mass of the host galaxies. Synthetic
# Vega B-band magnitudes (hereafter B) were obtained from the total (i.e. as
# obtained from model fitting) g0 and z0 band AB magnitudes, using a broad
# range of stellar population models (Bruzual & Charlot 2003) to compute the
# transformation to first order in the color term [B = g0 + 0.193 + 0.026 (g0
# - z0)]. Since the B band is close in wavelength to the g0 band, the
# transformation introduces only a minimal uncertainty of order 0.01-0.02
# mags. The resulting B magnitudes listed here supercede the photographic BT
# magnitudes (see Cote et al. 2004, and references therein) and will be used
# throughout this series (although for VCC1030 and VCC1535, the BT magnitudes
# are retained since HST photometry was not available). 
# 
# For all the objects with HST photometry, stellar masses were estimated from
# the g0 and z0 band AB  model magnitudes using the recipe of Bell et al
# (2003):
# 
#   log_10 (M*/L_g) = 0.698*(g0-z0) - 0.367
# 
# This recipe -- and its use of the HST photometry -- was found to be more
# robust than similar ones that use the 2MASS K-band data listed in F06,
# perhaps due to the difficulty of measuring fluxes of the lowest mass
# galaxies, or with matching the measurement apertures between different types
# of observation.  For the two objects with no HST photometry, we use BT and
# K-band magnitudes  and the coefficients provided in Bell et al (2001) to
# compute
# 
#   log_10 (M*/L_B) = 0.591*(B-K) - 1.743
# 
# which in these cases gives stellar masses that sit well with objects of
# comparable luminosity and measured with HST. As noted by Bell et al, the
# mass to light ratios calculated with these recipes have systematic
# uncertainties of some 0.2 dex arising from the assumed initial mass function
# (a Salpeter IMF was used in the derivation of the coefficients used here),
# and that the scatter in the mass to light ratios obtained is $\sim 0.1$ dex.
# 
#=======================================================================
