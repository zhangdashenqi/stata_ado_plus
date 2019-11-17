/*******************************************************************************

					   Developed by E. F. Haghish (2014)
			  Center for Medical Biometry and Medical Informatics
						University of Freiburg, Germany
						
						  haghish@imbi.uni-freiburg.de
								   
                       * MarkDoc comes with no warranty *
				   
	
	MarkDoc version 1.0  July, 2014 
	MarkDoc version 1.1  August, 2014 
	MarkDoc version 1.2  August, 2014
	MarkDoc version 1.3  September, 2014 
	MarkDoc version 1.4  September, 2014 
	MarkDoc version 1.5  October, 2014 
	MarkDoc version 1.6  October, 2014 
	MarkDoc version 2.0  November, 2014

*******************************************************************************/
				  
	/* ----     txt    ---- */
	
	* The txt command writes dynamic text in MarkDoc 
	
	cap program drop txt
	program define txt
        version 11
		
		
		
		*If the logfile is on, use the logfile to paste text in it. 
       if r(status) == "on" {
						
			*	confirm file `r(filename)'
			*	tempname canvas
			*	file open `canvas' using `r(filename)', write text append
			*	file write `canvas' `"`0'"'	_n
				
				display as txt `"{p}> `0'"'
				}
	
		/* give a notice if Weaver not in use, but not an error */
		if r(status) ~= "on" {
				di _newline
                di as text " Logfile is off! See {help markdoc}"
				di  _dup(28) "-"
				di _newline(2)
				}    
	end
