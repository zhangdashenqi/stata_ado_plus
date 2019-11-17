*! version 3.0 Apr 2012 by LQ
*! version 2.0 Feb 2001 by JJAV
*! version 1.0 Jul 1999 by JJAV

*! This program closes an HTML file
*! Disclaimer: This program is provided "AS IS".
*! Authors are not responsible of any kind of damage, derived from the use of this program.

program define htclose
	version 8
	syntax ,[noTAG]
	
	if "$HTfile" == "" {
		di as err "no HTML file open"
		exit 111
	}	
	else {
		cap confirm file `"$HTfile"'
		
		if _rc == 0  & "`tag'" == "" {
			tempname handle		
			file open `handle' using `"$HTfile"', write text append	
    		file write `handle' _n "</HTML>" _n		
 		}
 	}
	macro drop HT*		
end
