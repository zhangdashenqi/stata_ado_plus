/*******************************************************************************

							  Stata Weaver Package
					   Developed by E. F. Haghish (2014)
			  Center for Medical Biometry and Medical Informatics
						University of Freiburg, Germany
						
						  haghish@imbi.uni-freiburg.de

		
                  The Weaver Package comes with no warranty    	
				  
	Weaver version 1.0  July, 2014
	Weaver version 1.1  August, 2014
	Weaver version 1.2  August, 2014
	Weaver version 1.3  September, 2014 	
	Weaver version 1.4  October, 2014 
*******************************************************************************/

	/* ----     weaverversion    ---- */
	program define weaverversion
        version 11
		
		*> make sure that Stata does not repeat this every time
		if "$thenewestweaverversion" == "" {
				
				cap qui do "http://www.stata-blog.com/packages/update.do"
				
				}
		
		global weaverversion 1.4

		if "$thenewestweaverversion" > "$weaverversion" {
				
				di _n(4)
				
				di "  _   _           _       _                __  " _n ///
				" | | | |_ __   __| | __ _| |_ ___       _  \ \ " _n ///
				" | | | | '_ \ / _` |/ _` | __/ _ \     (_)  | |" _n ///
				" | |_| | |_) | (_| | (_| | ||  __/      _   | |" _n ///
				"  \___/| .__/ \__,_|\__,_|\__\___|     (_)  | |" _n ///
				"       |_|                                 /_/ "  _n ///


				di as text "{p}{bf: Weaver} has a new update available! Please click on " ///
				`"{ul:{bf:{stata "adoupdate weaver, update":Update Weaver Now}}} "' ///
				"or alternatively type {ul: {bf: adoupdate weaver, update}} to update the package"
				
				di as text "{p}For more information regarding the new features of Weaver, " ///
				`"visit {browse "http://www.haghish.com/statistics/stata-blog/reproducible-research/weaver.php":{it:http://haghish.com/weaver}}"'
				
				
				}
	
	end
