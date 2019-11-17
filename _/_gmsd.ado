*! version 1.1.2  07Nov2003
capture program drop _gmsd
program define _gmsd, sortpreserve

	version 7.0
	syntax newvarname(gen) =/exp [if] [in] [, lag(numlist integer min=1 max=1) lead(numlist integer min=1 max=1) BY(string)]

	if `"`by'"' != "" {
		_egennoby msd() `"`by'"'
		/* NOTREACHED */
	}

		if `"`lag'"' == "" & `"`lead'"' == "" {
			di as err "You must specify lag() or lead()"
			exit 198
		}

		if `"`lag'"' != "" & `"`lead'"' != "" {
			di as err "lag() and lead() are mutually exclusive"
			exit 198
		}

	qui {

		

***************************************LAG************************************************	
		
		if "`lag'" != "" {
							
			
   **********************if contains nothing***********************


			if "`if'" == ""{
		

		*****in contains nothing********	
				
				if "`in'" == "" {
					
					local obs = _N	
					local stop = `lag' + 1	
	
					forvalues start = 1/`obs'{													
							
						if `stop' <= `obs' {
							sum `exp' in `start'/`stop'
							replace `varlist' = r(sd) in `stop'	
						}
						local stop = `stop' + 1
					}
				
				}

		****in contains something**********
				
				else {
	
					local slash = index("`in'","/")

					if `slash' == 0 {
						di as err "The in option must contain more than one observation"
						exit 198
			      		} 
 					
                   			local startrange = substr("`in'", 3, index("`in'", "/") -3)
		        		local stoprange = substr("`in'", index("`in'", "/")+1, .)
					local stop = `lag' + `startrange'	
	
					forvalues start = `startrange'/`stoprange'{													
							
						if `stop' <= `stoprange' {
							sum `exp' in `start'/`stop'
							replace `varlist' = r(sd) in `stop'
						}
						local stop = `stop' + 1
					}
				
				}
          			
			}
						
   *********************`if' contains something**********************
			
			else {
			 					
                        ****`in' contains nothing*************				
			
				if "`in'" == "" {				
	
					tempvar touse 
					gen long `touse'=_n `if' 
					sort `touse'
					tab `touse' if `touse' != .
					local obs = r(N)
					local stop =`lag' + 1					
				
 					forvalues start = 1/`obs'{
						
						if `stop' <= `obs' 	{
							sum `exp' in `start'/`stop'
							replace `varlist' = r(sd) in `stop'
						}
						local stop = `stop' + 1
					}
				
				}
				
	      ****`in' contains something**********			
				
				else {
			
					local slash = index("`in'","/")

					if `slash' == 0 {
						di as err "The in option must contain more than one observation"
						exit 198
			      		} 
					
					tempvar touse 
		       			gen long `touse'=_n `if' `in'
					sort `touse'
					tab `touse' if `touse' != .			
                   			local startrange = 1
		        		local stoprange = r(N)
					local stop = `lag' + `startrange'	
				
					forvalues start = `startrange'/`stoprange'{													
								
						if `stop' <= `stoprange' {
							sum `exp' in `start'/`stop'
							replace `varlist' = r(sd) in `stop'
						}
						local stop = `stop' + 1
					}
					
				}	

			}		
	    
*************************************LEAD**************************************************
		}
		else {
				
		if "`lead'" != "" {										
   **********************if contains nothing***********************

			if "`if'" == ""{
			
                        *****in contains nothing************
				
				if "`in'" == "" {
				
					local obs = _N	
					local stop = `lead' + 1 
					
					forvalues start = 1/`obs'{
					
						if `stop'<= `obs' {
							sum `exp' in `start'/`stop'
							replace  `varlist' = r(sd) in `start'
							local stop = `stop' + 1		
						}
					}
				
				}

			*****in contains something*************
				
				else {
				
					local slash = index("`in'","/")
					
					if `slash' == 0 {
						di as err "The in option must contain more than one observation"
						exit 198
			      		} 
 
                   			local startrange = substr("`in'", 3, index("`in'", "/") -3) 
					local stoprange = substr("`in'", index("`in'", "/") + 1, .)
					local stop = `lead' + `startrange' 
					
					forvalues start = `startrange' /`stoprange'{
					
						if `stop'<= `stoprange' {
						
							sum `exp' in `start'/`stop'
							replace  `varlist' = r(sd) in `start'
							local stop = `stop' + 1		
						}
					}	
					
				}
          			
			}

						
   **********************if contains something***********************
   
			else {
							
                        *****in contains nothing***********				
					
				if "`in'" == "" {

					tempvar touse 
					gen long `touse'=_n `if' 
					sort `touse'
					tab `touse' if `touse' != .
					local obs = r(N)
					local stop = `lead' + 1  					

 					forvalues start = 1/`obs'{
						
						if `stop' <= `obs' {
						
							sum `exp' in `start'/`stop'
							replace `varlist'= r(sd) in `start'
							local stop = `stop' + 1
						}
					}						
				}

			*****in contains something*********			
				
				else {		
				 
					local slash = index("`in'","/")
					
					if `slash' == 0 {
						di as err "The in option must contain more than one observation"
					        exit 198
	      				} 

					tempvar touse 
					gen long `touse'=_n `if' `in'
					sort `touse'
					tab `touse' if `touse' != .
                    			local startrange = 1
					local stoprange = r(N)
					local stop = `lead' + `startrange' 
					
					forvalues start = `startrange' /`stoprange'{
					
						if `stop'<= `stoprange' {
						
							sum `exp' in `start'/`stop'
							replace  `varlist' = r(sd) in `start'
							local stop = `stop' + 1		
						}
					}		

				}
				
						
					
			}
				
		}		
		
	}	
			
end




