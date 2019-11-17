*! version 6.0.0	29dec1998	(www.stata.com/users/becketti/tslib)
*! _ts_gdat -- format a date value for a given observation
* version 1.0.0     Sean Becketti     September 1993           STB-15: sts4
/*
	_ts_gdat obsnum [, date(varname)]
*/
program define _ts_gdat
	version 3.1
	local obs "`1'"
/*
        Make sure the comma isn't absorbed in the obsnum.
*/
        local i = index("`obs'",",")
        if `i' { 
                local obs = substr("`obs'",1,`i'-1) 
                local 1 = substr("`1'",`i',.)
        }
	else { mac shift }
	conf integer n `obs'
        if (`obs'<1) | (`obs'>_N) { exit 198 }
	local options "Date(str)"
	parse "`*'"
/*
	Grab the date variable(s) and try to format them into a macro.  Until
	Stata gets date formats, we have to do this as an inelegant case 
	statement.
*/
        if "`date'"=="" { local date "$S_D_date" }
	parse "`date'", parse(" ")
        local ndates : word count `*'
        if `ndates'==0 {
                global S_1 `obs'
                exit
        }
        conf var `date'
        if `ndates'==1 {   /* Is this a pre-formatted string variable? */
                local type : type `date'
                local type = substr("`type'",1,3)
                if ("`type'"=="str") { 
                        global S_1 = `date' in `obs'
                        exit
                }
        }
/*
        There is at least one date variable and it is not a string variable.
*/
	qui period
	local period "$S_2"
        local mnames "January February March April May June July August September October November December"
	if (("`period'"=="annual") & (`ndates'==1)) {
		local dstr = `date'[`obs']
	}
	else if (("`period'"=="quarterly") & (`ndates'==2)) {
		local year=`1'[`obs']
		local quarter=`2'[`obs']
		local dstr "`year':`quarter'"
	}
	else if (("`period'"=="monthly") & (`ndates'==2)) {
		local year=`1'[`obs']
		tempvar mlabel
		cap decode `2', gen(`mlabel')
		if (_rc) {
			local month=`2'[`obs']
                        local month : word `month' of `mnames'
		}
		else { local month=`mlabel'[`obs'] }
		if "`month'"!="" { local dstr "`month', `year'" }
	}
	else if (("`period'"=="daily") & (`ndates'==3)) {
		local year=`1'[`obs']
		local day=`3'[`obs']
		tempvar mlabel
		cap decode `2', gen(`mlabel')
		if (_rc) {
			local month=`2'[`obs']
                        local month : word `month' of `mnames'
		}
		else { local month=`mlabel'[`obs'] }
		if "`month'"!="" { local dstr "`month' `day', `year'" }
	}
	else { local dstr "`obs'" }
	mac def S_1 "`dstr'"
end
