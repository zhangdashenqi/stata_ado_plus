*! v1.0.0 arb/dk 21oct03
* Convert HH:MM:SS string variable to elapsed time fraction
program define str2time
	version 7
	syntax varlist(string), [Generate(string) replace force SEParator(string) LIst]
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
	tempvar hour min sec tmp
	foreach v of varlist `varlist' {
		if missing("`replace'") {
			gettoken newv generate : generate
		}
		gen byte `hour'=real(substr(`v',1,index(`v',`"`separator'"')-1))
		* Check whether seconds are present
		cap assert index(substr(`v',index(`v',`"`separator'"')+1,.),`"`separator'"')==0
		if _rc {
			* At least some times have seconds
			#delimit ;
			gen byte `min' =	real(
									substr(
										`v',
										index(`v',`"`separator'"')+1,
										index(substr(`v',index(`v',`"`separator'"')+1,.),`"`separator'"')-1
									)
								);
			replace `min' = real(substr(`v',index(`v',`"`separator'"')+1,.)) if missing(`min');
			gen byte `sec' =	real(
									substr(
										`v',
										index(`v',`"`separator'"')+index(substr(`v',index(`v',`"`separator'"')+1,.),`"`separator'"')+1,
										.
									)
								) if index(substr(`v',index(`v',`"`separator'"')+1,.),`"`separator'"')>0;
			#delimit cr
			replace `sec'=0 if missing(`sec')
			gen double `tmp'=(`hour' + (`min'/60) + (`sec'/3600))/24 if inrange(`hour',0,23) & inrange(`min',0,59) & inrange(`sec',0,59)
		}
		else {
			gen byte `min'=real(substr(`v',index(`v',`"`separator'"')+1,.))
			gen double `tmp'=(`hour' + (`min'/60))/24 if inrange(`hour',0,23) & inrange(`min',0,59)
		}
		* Check for loss of information
		cap assert missing(`v')==missing(`tmp')
		if _rc & missing("`force'") {
			nois disp "{text}`v' contains invalid times; not converted" _c
			if missing("`list'") {
				nois disp ". Use -list- option to see invalid observations"
			}
			else {
				nois list `v' if missing(`v')!=missing(`tmp')
			}
		}
		else {
			if missing("`replace'") {
				gen double `newv'=`tmp'
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
