*! v1.0.0 arb 21oct03
* Convert elapsed time fraction to HH:MM string variable
program define time2str
	version 7
	syntax varlist(numeric), [Generate(string) replace SEParator(string) SEConds force LIst]
	if missing("`generate'") & missing("`replace'") {
		disp "{error}must specify either generate or replace option"
		exit 198
	}
	if missing("`replace'") {
		confirm new variable `generate'
		local w1 : word count `varlist'
		local w2 : word count `generate'
		if `w1'!=`w2' {
			error 102
		}
	}
	if missing(`"`separator'"') {
		local separator ":"
	}
	qui {
	foreach v of varlist `varlist' {
		if missing("`replace'") {
			gettoken newv generate : generate
		}
		local conv 1
		sum `v'
		if r(min)<0 | r(max)>1 {
			nois disp "{error}`v' contains values outside expected range (0,1). Check time variable is fraction of day"
			exit 451
		}
		tempvar hour min sec tmp
		gen byte `hour'=int(`v'*24)
		if missing("`seconds'") {
			gen byte `min'=int(round(60*(`v'*24-`hour'),0.000001))
			gen str5 `tmp'=string(`hour',"%02.0f") + `"`separator'"' + string(`min',"%02.0f") if !missing(`hour') & !missing(`min')
			sum `min', meanonly
			if (r(min)<0 | r(max)>59) & missing("`force'") {
				nois disp "{text}`v' contains invalid elapsed times; not converted" _c
				local conv 0
				if missing("`list'") {
					nois disp ". Use -list- option to see invalid observations"
				}
				else {
					nois list `v' `tmp' if (`min'<0 | `min'>59) & !missing(`min')
				}
			}		
		}
		else {
			gen byte `min'=int(round(60*(`v'*24-`hour'),0.000001))
			gen byte `sec'=int(round(60*(60*(`v'*24-`hour')-`min'),0.000001))
			gen str8 `tmp'=string(`hour',"%02.0f") + `"`separator'"' + string(`min',"%02.0f") + `"`separator'"' + string(`sec',"%02.0f") if !missing(`hour') & !missing(`min') & !missing(`sec')
			sum `sec', meanonly
			if (r(min)<0 | r(max)>59) & missing("`force'") {
				nois disp "{text}`v' contains invalid times; not converted" _c
				local conv 0
				if missing("`list'") {
					nois disp ". Use -list- option to see invalid observations"
				}
				else {
					nois list `v' `tmp' if (`sec'<0 | `sec'>59) & !missing(`sec')
				}
			}		
		}
		if `conv' {
			if missing("`replace'") {
				gen str8 `newv' = `tmp'
				compress `newv'
			}
			else {
				local varlab : variable label `v'
				move `tmp' `v'
				drop `v'
				rename `tmp' `v'
				label variable `v' `"`varlab'"'
			}
		}
		drop `hour' `min'
		cap drop `sec'
		cap drop `tmp'
	}
	} /* end quietly */
end

