*! finddate -- display dates for which data are available
*! Sean Becketti, July 1989
*! version 3.0.0
/*----------------------------------------------------------------------------
	Note: finddate assumes that the data set is sorted in the order of 
	      the date variables.
----------------------------------------------------------------------------*/
program define finddate
	version 3.0
	local varlist "opt ex"
	local if "opt"
	local in "opt"
	local options "Date(str) Nobs" 
	parse "`*'"
	if "`if'"!="" {local if "`if' &"}
	else {local if "if"}
        local sfn "$S_FN"
        tempfile user
	quietly save `user'
	capture {
/*
	Record the original observation numbers so series length and
	gaps can be recorded later.
*/
        	if ("`nobs'"!="") {
			tempvar obs
			gen long `obs' = _n
		}
/*
	Parse and process the date variables.
*/
        	if "`date'"=="" {		/* no datevars specified */
                	local ndates = 1
                	local ylabel "`obs'"
			local yname "Obs"
        	}
		else {				/* datevars specified */
                	_parsevl "`date'"
                	parse "$S_1", parse(" ")
                	if "`4'"!="" {
                        	noi di in re "No more than three date variables allowed"
                        	error 99
                	}
                	local ndates = cond("`2'"=="",1,cond("`3'"=="",2,3))
                	local year  "`1'"
                	local yname : var l `year'
			if ("`yname'"=="") {local yname "`year'"}
                	local month "`2'"
                	cap local mname : var l `month'
			if ("`mname'"=="") {local mname "`month'"}
                	local day   "`3'"
                	cap local dname : var l `day'
			if ("`dname'"=="") {local dname "`day'"}
/*
	If the date variables are labeled, use their labels; otherwise
	use their values.
*/
                	tempvar ylabel mlabel dlabel
                	cap decode `year', gen(`ylabel')
                	if _rc {
				local type : type `year'
				gen `type' `ylabel' = `year'
			}
                	if (`ndates'>1) {
                        	cap decode `month', gen(`mlabel')
                        	if _rc {
					local type : type `month'
					gen `type' `mlabel' = `month'
				}
                	}
                	if (`ndates'>2) {
                        	cap decode `day', gen(`dlabel')
                        	if _rc {
					local type : type `day'
					gen `type' `dlabel' = `day'
				}
                	}
        	}
/*
	Date variable processing is finished.  Now display the header.
*/
        	if (`ndates'==1) {
                	noi di in gr _col(11) "First" _col(22) "Last"
                	noi di in gr _col(11) "`yname'" _col(22) "`yname'"
                	noi di in gr "------------------------------"
        	}
        	if (`ndates'==2) {
                	noi di in gr _col(16) "First" _col(41) "Last"
                	noi di in gr _col(11) "`yname'" _col(22) "`mname'" /*
*/                       	_col(36) "`yname'" _col(47) "`mname'"
                	noi di in gr "-------------------------------------------------------"
        	}
        	if (`ndates'==3) {
                	noi di in gr _col(22) "First" _col(58) "Last"
                	noi di in gr _col(11) "`yname'" _col(22) "`mname'" _col(33) "`dname'" /*
*/                       	_col(47) "`yname'" _col(58) "`mname'" _col(69) "`dname'"
                	noi di in gr "-----------------------------------------------------------------------------"
        	}
/*
	Loop through the variables and display the beginning and
	ending dates for each one.
*/
		tempfile temp
		quietly save `temp'
        	parse "`varlist'", parse(" ")
        	while "`1'"!="" {
                	use `temp', clear
                	keep if `1'!=. `in'
/*
	Record the number of non-missing observations, the number of
	observations in the original data set from the first to the 
	last non-missing observation of this series, and the number
	of breaks in the series.
*/
                	if "`nobs'"!="" {
                        	local n = _N
                        	local N = `obs'[_N] - `obs'[1] + 1
                        	count if `obs'-`obs'[_n-1]>1 in 2/l
                        	local tag = _result(1)
                        	local tag "(`n'/`N'/`tag')"
                	}
                	if (`ndates'==1) {
                        	noi di in gr "`1'" in ye _col(11) `ylabel'[1] /*
*/                         	_col(22) `ylabel'[_N] "    `tag'"
                	}
                	if (`ndates'==2) {
                        	noi di in gr "`1'" in ye _col(11) `ylabel'[1] /*
*/                         	_col(22) `mlabel'[1] _col(36) `ylabel'[_N] /*
*/                         	_col(47) `mlabel'[_N] "    `tag'"
                	}
                	if (`ndates'==3) {
                        	noi di in gr "`1'" in ye _col(11) `ylabel'[1] /*
*/                         	_col(22) `mlabel'[1] _col(33) `dlabel'[1] /*
*/                         	_col(47) `ylabel'[_N] _col(58) `mlabel'[_N] /*
*/                         	_col(69) `dlabel'[_N] "    `tag'"
                	}
                	mac shift
        	}
	}	/* end of capture block */
	local rc = _rc
	quietly use `user', clear
        mac def S_FN "`sfn'"
	cap erase `temp'
        erase `user'
	error `rc'
end        
