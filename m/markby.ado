*! 1.0.0  09mar1999  jw/ics
program define markby
	version 6.0
	
	syntax newvarname [if/] , by(varlist) /*
		*/ [ IFby(str) Always Ever Cases(numlist) INby(str) /*
		*/	  Markout(varlist) Strok ]
		
	tokenize `by'		
	local nby : word count `by'
	while "`1'" ~= "" {
		capt assert `1' ~= .
		if _rc {
			di in re "variable `1' in by() has missing values"
			exit 198
		}
		mac shift
	}	
	
	tempvar touse
	gen byte `touse' = 1
	
	/*
		by-group selection via ifby and {always|ever}
	*/
	
	if `"`ifby'"' ~= "" {
		if "`always'" ~= "" & "`ever'" ~= ""  {
			di in re "at most one of { always | ever } allowed"
			exit 198
		}			
		
		qui replace `touse' = `touse' & ((`ifby') ~= 0)
		sort `by' `touse'
		if "`always'" ~= "" {
			qui by `by' : replace `touse' = `touse'[1]
		}
		else if "`ever'" ~= "" {
			qui by `by': replace `touse' = `touse'[_N]
		}
		else {
			capt by `by': assert `touse'[1] == `touse'[_N]
			if _rc {
				di in re "ifby() violates by-group boundaries"
				di in re "change ifby() or specify option {always|ever}"
				exit 198
			}
		}	
	}

	/*
		by-group selection via cases(), i.e., values of by-variable
	*/		
		
	if "`cases'" ~= "" {
		if `nby' > 1 { 
			di in re "cases() allowed only with a single numeric by-variable"
			exit 198
		}
		confirm numeric var `by'
		
		tempvar touse2
		gen byte `touse2' = 0
		tokenize `cases'
		while "`1'" ~= "" {
			qui replace `touse2' = 1 if float(`by') == float(`1')
			mac shift
		}
		qui replace `touse' = `touse' & `touse2'
	} 

	/*
		by-group selection via inby(), relative to sorted order on by-variables
	*/		
	
	if "`inby'" ~= "" {
		tempvar n
		sort `by'
		qui by `by': gen `n' = _n==1
		qui replace `n' = sum(`n')
		local max = `n'[_N]

		tokenize "`inby'", parse(" /")
		if "`2'" == "" {
			ElRange "`1'" `max'
			local n1 `r(el)'
		   qui replace `touse' = `touse' & `n'==`n1'
		}
		else if "`2'" == "/" {
			ElRange "`1'" `max'
			local n1 `r(el)'
			ElRange "`3'" `max'
			local n2 `r(el)'
		   qui replace `touse' = `touse' & (`n'>=`n1') & (`n'<=`n2')			
		}
	}
	
	/*
		select level-1 units ; here by-group boundaries may be violated
	*/

	if "`if'" ~= "" {
		qui replace `touse' = 0 if ~(`if')
	}
	if "`markout'" ~= "" {
		markout `touse' `markout', `strok'
	}	
	
	qui gen byte `varlist' = `touse'
end

program define	ElRange, rclass	
	args n max
	if "`n'" == "f" {
		return local el 1
	}	
	else if "`n'" == "l" {
		return local el `max'
	}
	else {
		capt confirm integer number `n'
		if _rc~=0 | `n'==0 {
			di in re "`n' invalid obs number"
			exit 198
		}
		return local el = cond(`n'<0, `max' + `n' + 1, `n')	 
	}		
end	
exit
