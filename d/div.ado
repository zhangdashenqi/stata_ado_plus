/*******************************************************************************

							  Stata Weaver Package
					   Developed by E. F. Haghish (2014)
			  Center for Medical Biometry and Medical Informatics
						University of Freiburg, Germany
						
						  haghish@imbi.uni-freiburg.de

		
                  The Weaver Package comes with no warranty    	
				  
				  
	Weaver version 1.0  August, 2014
	Weaver version 1.1  August, 2014
	Weaver version 1.2  August, 2014
	Weaver version 1.3  September, 2014 
	Weaver version 1.4  October, 2014 
*******************************************************************************/
	
	/* ----     div     ---- */
	
	* separates the codes from the results and shows them in separate boxes
	program define div
	version 11
		
		set linesize $width
		
		if "$weaver" != "" cap confirm file `"$weaver"' 

        tempname canvas needle
        tempfile memo
		
        /* open new log, run command and close log */
		set linesize $width  
        set more off    
        
		
		/* saving the results in `memo' */
		cap log c
		quietly log using `memo', replace text
		`0'
		cap quietly log close
                        
						
        /* Using existing log */
        if `"`r(filename)'"' != "" {
                set linesize $width
                cap quietly log using r(filename), append r(type)
                if r(status) != "on" quietly log r(status)
				}
        
        /* open the canvas and print the Stata codes in the code tag */
        cap file open `canvas' using `"$weaver"', write text append 
*		cap file write `canvas' "<code>"`"`0'"'"</code>"
		cap file write `canvas' `"<code>`macval(0)'</code>"'
		
		
		/* openning the results tag */
		cap file write `canvas' "<results>"
		
		/* reading the results from the log file */
		cap file open `needle' using `memo', read
        cap file read `needle' line
		
		/* writing the results to the html file */
        while r(eof)==0 {
                cap file write `canvas' `"`macval(line)'"' _n      
                cap file read `needle' line
				}
		
		/* closing the results tag */
		cap file write `canvas' "</results>"
		
		
		/* give a notice if Weaver not in use, but not an error */
		if "$weaver" == "" {
				di _newline
				di  _dup(17) "-"
                di as text " Nothing to {help weave}!"
				di _newline(2)
				}    
		
	end
