*! version 3.0 Apr 2012 by LQ
*! Version 2.0 Feb 2001 by JJAV
*! Version 1.0 Jul 1999 by JJAV

*! This program sends to the HTML file the output of a Stata command
*! Disclaimer: This program is provided "AS IS".
*! Authors are not responsible of any kind of damage, derived from the use of this program.

program define htlog
version 8
	
	if "$HTfile" == "" {
		di as err "no HTML file open"
		exit 111
	}	
	else confirm file `"$HTfile"'

	tempname handle loghand
	tempfile templog

	/* Save previous log status and close it */
	quietly log
	local logname = r(filename)
	if "`logname'" != "." {
		local logname = r(filename)
		local logstat = r(status)
		local logtyp = r(type)
		local logline : set linesize
		quietly log close
	}
	else local logname ""
	
	/* Open new log, run command and close log */
	set linesize 250
	set more off	
	quietly log using `templog', replace text	
	noisily `0'
	quietly log close
			
	/* Open previous log */
	if `"`logname'"' != "" {
		set linesize `logline'
		quietly log using `"`logname'"', append `logtyp'
		if "`logstat'" != "on" quietly log `logstat'
	}
	
	/* Specific commands for this file */
	file open `handle' using `"$HTfile"', write text append	
	file write `handle' "<PRE>"

    file open `loghand' using `templog', read
	file read `loghand' line
	while r(eof)==0 {
		file write `handle' `"`line' "' _n	
		file read `loghand' line
	}
	file write `handle' "</PRE>"
end
