/*******************************************************************************

							  Stata Weaver Package
					   Developed by E. F. Haghish (2014)
			  Center for Medical Biometry and Medical Informatics
						University of Freiburg, Germany
						
						  haghish@imbi.uni-freiburg.de

		
                  The Weaver Package comes with no warranty    	
				  
	Ketchup version 1.0  July, 2014
	Ketchup version 1.1  August, 2014
	Ketchup version 1.2  August, 2014
	Ketchup version 1.3  September, 2014 	
	Ketchup version 1.4  October, 2014 
*******************************************************************************/

	/* ----     markdocversion    ---- */
	program define ketchupversion
        version 11
		
		*> make sure that Stata does not repeat this every time
		if "$thenewestmarkdocversion" == "" {
				
				cap qui do "http://www.stata-blog.com/packages/update.do"
				
				}
		
		global ketchupversion 1.4

		if "$thenewestketchupversion" > "$ketchupversion" {
				
				di _n(4)
				
				di "  _   _           _       _                __  " _n ///
				" | | | |_ __   __| | __ _| |_ ___       _  \ \ " _n ///
				" | | | | '_ \ / _` |/ _` | __/ _ \     (_)  | |" _n ///
				" | |_| | |_) | (_| | (_| | ||  __/      _   | |" _n ///
				"  \___/| .__/ \__,_|\__,_|\__\___|     (_)  | |" _n ///
				"       |_|                                 /_/ "  _n ///


				di as text "{p}{bf: Ketchup} has a new update available! Please click on " ///
				`"{ul:{bf:{stata "adoupdate ketchup, update":Update Ketchup Now}}} "' ///
				"or alternatively type {ul: {bf: adoupdate ketchup, update}} to update the package"
				
				di as text "{p}For more information regarding the new " ///
				"features of Ketchup, " ///
				`"see the {browse "http://www.haghish.com/statistics/stata-blog/reproducible-research/ketchup.php":{it:http://haghish.com/ketchup}}"'
				
				}
	
	end
