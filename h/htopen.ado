*! version 4.1 Jun 2012 by LQ
*! version 4.0 Apr 2012 by LQ
*! version 3.0 Aug 2003 by JJAV
*! version 2.0 Feb 2001 by JJAV
*! version 1.0 Jul 1999 by JJAV

*! This program opens an HTML file
*! Disclaimer: This program is provided "AS IS".
*! Authors are not responsible of any kind of damage, derived from the use of this program.

program define htopen
	version 8
	syntax using/, [append|replace noTAG]
	
	if "$HTfile" != "" {
		mata:errprintf("$HTfile is in use, type {stata htclose} to close it\n")
		exit 110
	}				
	if "`append'" != "" & "`replace'" != "" {
		di as err "options append and replace not allowed simultaneously"
		exit 198
	}	
		
	if (!regexm(`"`using'"',".htm$") & !regexm(`"`using'"',".html$") & !regexm(`"`using'"',".css$")) local using `"`using'.html"'
    
	tempname handle	
	cap file open `handle' using `"`using'"', write text `replace' `append'
	if _rc == 602 { /* using exist */
		di as err "HTML file `using' already exists, use replace or append"
		exit 602
	}
	
    if "`append'" == "" & "`tag'" == "" {
			file write `handle' `"<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN""' _n
			file write `handle' `""http://www.w3.org/TR/html4/loose.dtd">"' _n
			file write `handle' "<HTML>" _n
    }
    global HTfile `"`using'"'   
end
