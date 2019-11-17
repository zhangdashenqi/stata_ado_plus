*! NJC 2.0.0 30 January 2009 
* NJC 1.2.0 22 November 2005 
* NJC 1.1.0 21 November 2000 
program rowsort  
	version 9 
	syntax varlist [if] [in], Generate(str) [ Descending HIGHmissing ] 

	quietly {
		marksample touse, novarlist 
		count if `touse' 
		if r(N) == 0 error 2000 

		capture confirm string var `varlist' 
		if _rc {  // looks like numeric varlist only 
			capture confirm numeric var `varlist' 
			if _rc { 
				di "invalid varlist" 
				exit _rc 
			} 
			local which "numeric" 

			local type "double"
		}
		else { // is string varlist only 
			local which "string" 

			local type 1 
			foreach v of local varlist { 
				local this : type `v' 
				local this = substr("`this'", 4, .) 
				local type = max(`type', `this') 
			} 

			local type "str`type'" 
		} 

		local nvars : word count `varlist'
		local mylist "`varlist'" 
		local 0 "`generate'" 
		syntax newvarlist 
		local generate "`varlist'" 
		local ngen : word count `generate'
		local dir = cond("`descending'" == "", 1, -1) 
		local high = "`highmissing'" != ""   
		
		if `nvars' != `ngen' { 
			di as err "`nvars' variables, but `ngen' new " ///
			plural(`ngen', "name") 
			exit 198 
		}

		if `nvars' == 1 { 
			gen `generate' = `mylist' if `touse' 
			exit 0 
		} 

mata : ///
row_sort("`mylist'", "`touse'", "`generate'", "`which'", "`type'", `dir', `high') 

		compress `generate' 
	}
end 	
	
mata : 

void row_sort(  string scalar varnames, 
		string scalar tousename,
		string scalar newnames,
		string scalar which, 
		string scalar type, 
		real scalar dir, 
		real scalar high  )
{
	transmorphic matrix y 
	transmorphic colvector row 
	real scalar i, nmiss, ncols  

	if (which == "numeric") y = st_data(., tokens(varnames), tousename) 
	else y = st_sdata(., tokens(varnames), tousename) 

	if (high & 
	((which == "numeric" & dir == -1) | (which == "string" & dir == 1))) {  
		ncols = cols(y) 

		for(i = 1; i <= rows(y); i++) { 
			y[i,] = sort(y[i,]', dir)'  
			if (which == "numeric") nmiss = missing(y[i,]) 
			else nmiss = sum(y[i,] :== "") 
			if (nmiss > 0 & nmiss < ncols) {
				y[i,] = y[i, ((nmiss + 1 .. ncols), (1 .. nmiss))] 
			}
	        }
	}
	else { 
		for(i = 1; i <= rows(y); i++) { 
			y[i,] = sort(y[i,]', dir)'  
		}
        }

	(void) st_addvar(type, tokens(newnames)) 
	if (which == "numeric") st_store(., tokens(newnames), tousename, y) 
	else st_sstore(., tokens(newnames), tousename, y) 
}	

end

