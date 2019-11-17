*! datevars -- set or display datevars
*! version 1.0.2     Sean Becketti     January 1995
*  version 1.0.1     Sean Becketti     November 1993
*  version 1.0.0     Sean Becketti     September 1993           STB-15: sts4
*  Update history:
*       1.0.2    1/19/95        clear the final S_# macro
*	1.0.1	11/18/93	accept any legal variable names, even not existing
*
program define datevars
	version 3.1
	qui period
	local period "$S_2"
	local ndates : word count `*'
	if `ndates' { 
		cap _parsevl `*'
		if !_rc { parse "$S_1", parse(" ") }
		else { conf new variable `*' }
	}
	if `ndates'==0 {
		if "$S_D_date"=="" { di in gr "No date variables defined" }
		else { di "$S_D_date" }
	}
	else if `ndates'==1 { global S_D_date "`*'" }
	else if ("`period'"=="quarterly") & (`ndates'==2) { global S_D_date "`*'" }
	else if ("`period'"=="monthly") & (`ndates'==2) { global S_D_date "`*'" }
	else if ("`period'"=="daily") & (`ndates'==3) { global S_D_date "`*'" }
	else { 
		global S_D_date
		global S_1
		error 98 
	}
	parse "$S_D_date", parse(" ")
	local i 1
	while "``i''"!="" {
		global S_`i' ``i''
		local i = `i' + 1
	}
        global S_`i'
end
