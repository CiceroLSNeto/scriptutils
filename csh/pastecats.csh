#!/bin/tcsh
#=======================================================================
#+
# NAME:
#   pastecats.csh
#
# PURPOSE:
#   Read in a catalogue, and another catalogue, and paste them together
#
# COMMENTS:
#
#
# INPUTS:
#   cat1 cat2              two catalogues
#
# OPTIONAL INPUTS:
#   -h --help              print this header
#   -v --verbose           verbose operation
#   -o --output  outfile   output filename
#   -i --imcat             imcat format output
#   -a --asciisex          ascii sextractor type cat
#   --asciisexin           input ascii sextractor type cat
#   --clever               add name of the file to each header name 
#                          (e.g. combining two colour cats) 
#   --write-header         write a one line text header (non-imcat mode)
#   --column-name          when adding a single column, specify the name
#
# OUTPUTS:
#   outfile
#
# EXAMPLES:
#   pastecats.csh old.cat new.txt 
#
# BUGS:
#   - incomplete header documentation
#   - if input is plain text and contains text format fields (not numbers)
#     then the output imcat will be corrupted
#  
# REVISION HISTORY:
#   2006-12-01  started Marshall (UCSB)
#   2007-04-12  added input asciisex option Marusa
#-
#=======================================================================

# Options and arguments:

set help = 0
set vb = 0
set imcat = 0
set asciisex = 0
set asciisexin = 0
set output = 0
set writeheader = 0
set specialname = 0
set guesscolumnames = 0
set clever = 0
set inputs = ()

# Parse command line:

while ( $#argv > 0 )
   switch ($argv[1])
   case -h:       
      shift argv
      set help = 1
      breaksw
   case --{help}:   
      shift argv
      set help = 1
      breaksw
   case -v:       
      shift argv
      set vb = 1
      breaksw
   case --{verbose}:   
      shift argv
      set vb = 1
      breaksw
   case -i:       
      shift argv
      set imcat = 1
      breaksw
   case --{imcat}:   
      shift argv
      set imcat = 1
      breaksw
   case -a:       
      shift argv
      set asciisex = 1
      breaksw
   case --{asciisex}:       
      shift argv
      set asciisex = 1
      breaksw
   case --{asciisexin}:       
      shift argv
      set asciisexin = 1
      breaksw
   case --{clever}:       
      shift argv
      set clever = 1
      breaksw
   case --{write-header}:   
      shift argv
      set writeheader = 1
      breaksw
   case -o:       
      shift argv
      set output = $argv[1]
      shift argv
      breaksw
   case --{output}:
      shift argv
      set output = $argv[1]
      shift argv
      breaksw
   case --{column-name}:
      shift argv
      set specialname = $argv[1]
      shift argv
      breaksw
   case *:         
      set inputs = ( $inputs $argv[1] )
      shift argv
      breaksw
   endsw
end

if ($help) then
  print_script_header.csh $0
  goto FINISH
endif
if ($#inputs < 2 ) then
  echo "${0:t}: need at least two catalogues"
  goto FINISH
endif


#-----------------------------------------------------------------------
SETUP:

if ($vb) echo "${0:t}: Pasting $#inputs catalogues together"

if ( $specialname != 0 ) then
  if ($vb) echo "${0:t}: first new column of catalogue will be named $specialname"
endif 

if ($imcat) then
  set fail = `which lc | grep "Command not found" | wc -l`
  if ($fail) then
    echo "${0:t}: lc command not found, install imcat"
    goto FINISH
  endif
  set ext = "cat"
else
  set ext = "txt"
endif  

if ($output == 0) then
  set output = "$inputs[1]:r"
  foreach k ( `seq 2 $#inputs` )
    set output = "${output}+${inputs[$k]:r}"
  end
  set output = "${output}.${ext}" 
endif
if ($vb) echo "${0:t}: output catalogue will be called $output"
if ( -e $output && $vb) echo "${0:t}: WARNING: output file will be clobbered"

#-----------------------------------------------------------------------
# Research inputs:

set headers = ( )
set bodies = ( )
set comments = ( )
set contents = ( )
set alphabet = ( a b c d e f g h i j k l m n o p q r s t u v w x y z )
set columnnames = ( )

foreach k ( `seq $#inputs` )
      
  set input = $inputs[$k]
  if ($vb) echo "${0:t}: researching input file $input:t"

# Check for existence:
  if ( ! -e $input ) then
    echo "${0:t}: file not found"
    goto FINISH
  endif  

# Check header for imcat format:
  set myfileisimcat = `grep "format catalogue file --- do not edit manually" $input | wc -l` 
  if ($myfileisimcat) then
    if ($vb) echo "${0:t}: file format is imcat"
    set myfileisbinary = `grep "binary format catalogue file --- do not edit manually" $input | wc -l` 
    if ($myfileisbinary) then
      echo "${0:t}: cannot cope with binary imcat files - aborting"
      goto FINISH
    endif
  else
    if ($vb) echo "${0:t}: file format is assumed to be plain text"
  endif
  
  set hdr = $input:r.hdr
  if ( -e $hdr ) then
    if ($vb) echo "${0:t}: WARNING: clobbering header file $hdr:t"
  endif
  grep -e '#' $input >! $hdr
  
  set body = $input:r.body
  if ( -e $body ) then
    if ($vb) echo "${0:t}: WARNING: clobbering body file $body:t"
  endif
  
  if ($myfileisimcat && $imcat) then
    lc -o < $input >! $body
  else  
    grep -v '#' $input >! $body
  endif

  set nhdr = `cat $hdr | wc -l`
  set nbody = `cat $body | wc -l`
  if ($k == 1) set n = $nbody

  set guesscolumnnames = 0
  if ( $nhdr == 0 ) then
    if ($vb) echo "${0:t}: no header lines detected, making up column names"
    set guesscolumnnames = 1
  else
    if ($vb) echo "${0:t}: $nhdr header lines detected, reading column names from last line"
  endif

  if ($vb) echo "${0:t}: $nbody data lines detected"
  if ( $nbody == 0 ) then
    goto FINISH
  else if ( $nbody != $n ) then
    if ($vb) echo "${0:t}: this is different from first file value $n, aborting"
    goto FINISH
  endif

  set bodyline = `head -1 $body`    
  if ($vb) echo "${0:t}: detected $#bodyline data columns"
  if ($guesscolumnnames == 0) then
    if ( $asciisexin ) then
      set hdrline = `seq $nhdr`
      foreach i ( `seq $nhdr` )
        set hdrline[$i] = `head -$i $hdr| tail -1 | cut -c 7-20` 
      end
    else
      set hdrline = `tail -1 $hdr | sed s/\#//g`  
      if ($vb) echo "${0:t}: detected $#hdrline column names"
    endif
  endif  
  
  if ($clever) then
    foreach i ( `seq $#hdrline` )
      if ($vb) echo "${0:t}: detected column $hdrline[$i]"
	set hdrline[$i] = ${hdrline[$i]}_${inputs[$k]:r}       	
    end	
    if ( $#bodyline != $#hdrline ) then
      if ($vb) echo "${0:t}: WARNING: column names are corrupted, making them up instead"
      set guesscolumnnames = 1
    endif
  endif

  set thesecolumnnames = ( )
  if ($guesscolumnnames) then
    foreach j ( `seq 1 $#bodyline` )
#   Set first column name to be the special name:
      if ($j == 1 && $specialname != 0) then
        set columnname = "${specialname}"
        set specialname = 0
      else
        set columnname = "${alphabet[$k]}${j}"
      endif
      set thesecolumnnames = ( $thesecolumnnames $columnname )
    end  
    set columnnames = ( "${columnnames}" "${thesecolumnnames}" )
  else
    set columnnames = ( "$columnnames" "$hdrline" )
    if ($vb) echo "${0:t}: $columnnames"
  endif

# A bit more work with imcat - need comments and contents to construct new header:

  if ($imcat) then

    set com = $input:r.comments
    if ( -e $com ) then
      if ($vb) echo "${0:t}: WARNING: clobbering comments file $com:t"
    endif
    grep -e '# comment' $input >! $com

    set con = $input:r.contents
    if ( -e $con ) then
      if ($vb) echo "${0:t}: WARNING: clobbering contents file $con:t"
    endif
    grep -e '# number' -e '# text' $input | grep -v "do not edit manually" >! $con

# If input was plain text, we need to make our own contents file:
# BUG: text columns not accounted for!
    set ncon = `cat $con | wc -l`
    if ($ncon == 0) then
      foreach columnname ( $thesecolumnnames )
        echo "# number   1 1         $columnname" >> $con
      end  
    endif

    set comments = ( $comments $com )
    set contents = ( $contents $con )

  endif
  
  set headers = ( $headers $hdr )
  set bodies = ( $bodies $body )
 
end

#-----------------------------------------------------------------------
# Now, do the pasting!
# echo "Starting pasting" 
# Clobbering the output here allows replacement of input file
\rm -f $output

if ($imcat) then
# ---- IMCAT FORMAT ----

# Construct header by hand:
  if ($vb) echo "${0:t}: constructing imcat header"
  
  echo "# text format catalogue file --- do not edit manually, use 'lc'" >! $output
  echo "# header:" >> $output
  
# Add history of all input files:
  foreach input ( $inputs )
    echo "# comment: history of input file ${input:t}:" >> $output
    set com = $input:r.comments
    cat $com >> $output
  end
  echo "# comment: history of current file:" >> $output
  
# New number of columns - easiest to get it from all contents files:
  foreach input ( $inputs )
    set con = $input:r.contents
    cat $con >> pastecats.junk
  end
  set ncolumns = `cat pastecats.junk | wc -l`
  \rm pastecats.junk
  echo "# contents: $ncolumns" >> $output
  
# imcat contents list:
  foreach input ( $inputs )
    set con = $input:r.contents
    cat $con >> $output
  end
  
# The usual header line - spacing is bad, but will fix with final lc below
  
  set string = "#        "
  foreach par ( `echo "$columnnames"` )
    set string = "${string}${par}         "
  end  
  echo "${string}" >> $output

else if ( $asciisex ) then
# ---- ASCII SEXTRACTOR FORMAT ----

 if ($vb) echo "${0:t}: constructing asciisex header"
 set j = 0
 foreach name ( $columnnames )
    if ($j < 10) then
	echo "#   $j $name                 Description [units]" >> $output  
    else 
    	echo "#  $j $name                  Description [units]" >> $output  
    endif
    @ j++;
 end
 
else 
# ---- TEXT FORMAT ----

  if ($writeheader) echo "# $columnnames" >! $output

endif

paste $bodies >> $output

# Pipe through lc to get formatting right:
if ($imcat) then
  lc -x < $output > pastecats.junk
  mv -f pastecats.junk $output
endif

#-----------------------------------------------------------------------
# Clean up:

\rm -f $headers $bodies 
if ($imcat) then
  \rm -f $comments $contents 
endif

if ($vb) echo "${0:t}: all done: output file is $output"

FINISH:

#=======================================================================
