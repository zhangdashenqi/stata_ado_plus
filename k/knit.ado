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
				  
	/* ----     knit    ---- */
	
	* knit prints a text paragraph in <p> "text" </p> html format
	cap program drop knit
	program define knit
        version 11
		
        if "$weaver" != "" {
				cap confirm file `"$weaver"'

				tempname canvas
				cap file open `canvas' using `"$weaver"', write text append
		
				cap file write `canvas' "<p>" 
				cap file write `canvas' `"`0'"'		
				cap file write `canvas' "</p>" _n
				}
		
		/* give a notice if Weaver not in use, but not an error */
		if "$weaver" == "" {
				noisily display "     "
				noisily display ">"
				noisily display `">knitted: `macval(0)'"'
				}    
	end
