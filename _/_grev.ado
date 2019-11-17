*! 1.1.0 NJC 11 June 1999 STB-50 dm70
* 1.0.0 17 June 1997
program define _grev
        version 6.0
	gettoken type 0 : 0
        gettoken g 0 : 0
        gettoken eqs 0 : 0
        syntax varname [if] [in] [ , by(varlist) ]  
	local type : type `varlist' /* ignore `type' passed from -egen- */ 
	tempvar touse order 
        mark `touse' `if' `in' 
	gen long `order' = _n
	sort `touse' `by' `order' 
        qui by `touse' `by' : /*
	*/ gen `type' `g' = `varlist'[_N - _n + 1] if `touse'
end
