*! 2.5.0 NJC 15 Sept 2008 
* 2.4.1 NJC 10 June 2007 
* 2.4.0 NJC 14 April 2005 
* 2.3.1 NJC 6 February 2001 
* 2.3.0 NJC 22 November 2000 
* 2.2.0 NJC 21 November 2000 
* 2.1.0 NJC 27 October 2000 
* 2.0.0 NJC 22 April 1999 
* 1.1.0 NJC 5 Feb 1997
* drop variables (optionally observations) with all (optionally any) 
* values missing
program dropmiss
	version 8 
/* 
	allowed syntax 
	either 
		dropmiss [varlist] [if] [in], Obs [ Trim Piasm any force ]  
	or 
		dropmiss [varlist], [ Trim Piasm any force ]  
*/       
	capture syntax [varlist] [if] [in] , Obs [ Trim Piasm any force ] 
	if _rc syntax [varlist] [, Trim Piasm any force ] 

	if "`force'" == "" { 
		if c(changed) { 
			di as err ///
	"{p}no; dataset has been changed and {cmd:force} option was not specified{p_end}" 
			exit 198 
		}
	} 
				    
	tokenize `varlist' 
	local nvars : word count `varlist'
    
	quietly { 
	        if "`obs'" == "obs" {
			marksample touse, novarlist  
			tempvar nmiss	
			gen `nmiss' = 0
			forval i = 1/`nvars' { 
				if "`piasm'" != "" { 
					local or `" | `trim'(``i'') == ".""' 
				} 	
				capture confirm string variable ``i'' 
				
				if _rc replace `nmiss' = ///
					`nmiss' + missing(``i'') 
				else   replace `nmiss' = /// 
					`nmiss' + (missing(`trim'(``i'')) `or') 
		        }
			if "`any'" == "" replace `nmiss' = `nmiss' == `nvars'
			noi drop if `nmiss' & `touse' 
	        } 
        	else { 
	        	forval i = 1/`nvars' {
				capture confirm string variable ``i'' 
				if "`piasm'" != "" { 
					local or `" | `trim'(``i'') == ".""' 
				} 	
				if _rc count if missing(``i'') 
				else   count if missing(`trim'(``i'')) `or'  
				 	
				local drop = ///
					cond("`any'" != "", r(N), r(N) == _N) 
        		        if `drop' { 
					local dropped `dropped' ``i'' 
					drop ``i'' 
				}
			} 
			if "`dropped'" != "" {
				noi di as txt "{p}({res:`dropped'} dropped){p_end}" 
			}	
        	}
	}	
end
