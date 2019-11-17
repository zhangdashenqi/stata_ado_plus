* forestplot for cox version 1.7 SB 05May2006

* program to calculate 2*2 table for interaction and produce forest plots

program define fintplotcox

syntax varlist [if] [in], [by(varname) strata(varname)] logistic(numlist) logscale(numlist)

if `"`by'"'=="" {
	fintcoxa `0'
}
else {
	fintcoxb `0'
}

end


program fintcoxa, rclass

version 8.0

st_is 2 analysis

syntax varlist(min=2) [if] [in] [, strata(varname) logistic(numlist) logscale(numlist)]

	

quietly {

	tempname level z 
	
	local trtvar: word 1 of `varlist'
	
	tokenize `varlist'
	local n : word count `varlist'

	forvalues i = 2/`n' {
		local factorvar`i': word `i' of `varlist'
		tempname factor`i'
		egen int `factor`i'' = group(`factorvar`i'')
		replace `factor`i'' = `factor`i'' - 1
		assert `factor`i'' == 0 | `factor`i'' == 1
	}

	tempname trt
	egen int `trt' = group(`trtvar')
	replace `trt' = `trt' - 1
	assert `trt' == 0 | `trt' == 1
	
	if `"`if'`in'"'!="" {
		keep `if' `in'
	}
	
	scalar `level'=1-(100-$S_level)/200
	scalar `z'=invnorm(`level')

	* get overall hazard ratio
	tempname lnoverall overall lboverall uboverall
	stcox `trt', strata(`strata')
	scalar `lnoverall' = _b[`trt']
	scalar `overall' = exp(_b[`trt'])
	scalar `lboverall' = exp(_b[`trt'] - (`z'*_se[`trt']))
	scalar `uboverall' = exp(_b[`trt'] + (`z'*_se[`trt']))

	forval i=2/`n' {

		
		*calculation of RHR
		tempname lntau`i' tau`i' lbtau`i' ubtau`i' lnu`i' lndelta`i'0 delta`i'0 /*
		*/ ubdelta`i'0 lbdelta`i'0 lntaudeltau`i' 
		gen trt_factor`i' = `trt'*`factor`i''
		stcox `trt' `factor`i'' trt_factor`i', strata(`strata')
		scalar `lntau`i'' = _b[trt_factor`i']
		scalar `tau`i'' = exp(_b[trt_factor`i'])
		scalar `lbtau`i'' = exp(_b[trt_factor`i'] - (`z'*_se[trt_factor`i']))
		scalar `ubtau`i'' = exp(_b[trt_factor`i'] + (`z'*_se[trt_factor`i']))
		scalar `lnu`i'' = _b[`factor`i'']
		scalar `lndelta`i'0' = _b[`trt']
		scalar `delta`i'0' = exp(_b[`trt'])
		scalar `lbdelta`i'0' = exp(_b[`trt'] - (`z'*_se[`trt']))
		scalar `ubdelta`i'0' = exp(_b[`trt'] + (`z'*_se[`trt']))
		
		tempname lbdelta`i'1 ubdelta`i'1 lndelta`i'1 delta`i'1 conf
		lincom 2*_b[`factor`i''] + _b[`trt'] + _b[trt_factor`i']
		scalar `lndelta`i'1' = r(estimate)
		scalar `lbdelta`i'1' = exp(`lndelta`i'1' - (`z'*r(se)))
		scalar `ubdelta`i'1' = exp(`lndelta`i'1' + (`z'*r(se)))
		scalar `delta`i'1' = exp(`lndelta`i'1')
		
		
		drop trt_factor`i'
	}
	
	*display of 2*2 table
	
	
	forval i=2/`n' {
		noi di in gr "-> interaction with `factorvar`i''"
		noi di in gr " "
		noi di in gr "Factor" _col(20) in gr "{c |} lnHR" _col(33) in gr "HR" _col(44) in gr "[95% Conf. Interval]"
		noi di in gr _dup(19) "{c -}" _col(20) in gr "{c +}" in gr _dup(43) "{c -}"
		noi di in gr "overall HR" _col(20) in gr "{c |}" _col(21) in ye `lnoverall' _col(33) in ye `overall' _col(44) in ye `lboverall' _col(55) `uboverall'
		noi di in gr "`factorvar`i''=0" _col(20) in gr "{c |}" _col(21) in ye `lndelta`i'0' _col(33) in ye `delta`i'0' _col(44) in ye `lbdelta`i'0' _col(55) `ubdelta`i'0'
		noi di in gr "`factorvar`i''=1" _col(20) in gr "{c |}" _col(21) in ye `lndelta`i'1' _col(33) in ye `delta`i'1' _col(44) in ye `lbdelta`i'1' _col(55) `ubdelta`i'1'
		noi di in gr " "
		noi di in gr " "
		noi di in gr "Factor" _col(20) in gr "{c |} lnRHR" _col(33) in gr "RHR" _col(44) in gr "[95% Conf. Interval]"
		noi di in gr _dup(19) "{c -}" _col(20) in gr "{c +}" in gr _dup(43) "{c -}"
		noi di in gr "interaction" _col(20) in gr "{c |}" _col(21) in ye `lntau`i'' _col(33) in ye `tau`i'' _col(44) in ye `lbtau`i'' _col(55) `ubtau`i''
		noi di in gr " "
		
		if `"`strata'"'!="" {
			noi di in gr "Stratified by `strata'"
			noi di in gr " "
		}
		
		return scalar overall = `overall'
		return scalar uboverall = `uboverall'
		return scalar lboverall = `lboverall'
		return scalar delta`i'0 = `delta`i'0'
		return scalar ubdelta`i'0 = `ubdelta`i'0'
		return scalar lbdelta`i'0 = `lbdelta`i'0'
		return scalar delta`i'1 = `delta`i'1'
		return scalar ubdelta`i'1 = `ubdelta`i'1'
		return scalar lbdelta`i'1 = `lbdelta`i'1'
		return scalar tau`i' = `tau`i''
		return scalar ubtau`i' = `ubtau`i''
		return scalar lbtau`i' = `lbtau`i''
		
		*parameters for graphics
	
		if `logscale'==0 {

		preserve
		drop _all
		qui set obs 1
		gen ftau`i' =7
		gen ptaumin`i'=`lbtau`i''
		gen ptau50`i'=`tau`i''
		gen ptaumax`i'=`ubtau`i''
			

		gen foverall = 10
		gen poverallmin = `lboverall'
		gen poverall50 = `overall'
		gen poverallmax = `uboverall'

		gen fhr1`i' = 8
		gen phr1min`i' = `lbdelta`i'1'
		gen phr150`i' = `delta`i'1'
		gen phr1max`i' = `ubdelta`i'1'

		gen fdelta`i' = 9
		gen pdeltamin`i' = `lbdelta`i'0'
		gen pdelta50`i' = `delta`i'0'
		gen pdeltamax`i' = `ubdelta`i'0'

		gen f1 = 1
		gen high = 11
		gen low = 6.5
		
		gen cut = 2.4
		
		set scheme cycle
		
		
		*forestplot graphic generation
		twoway (rcap ptaumin`i' ptaumax`i' ftau`i' if ptaumax`i' <= 2.4, hor blcolor(dknavy) legend(off)) ///
			(rcap ptaumin`i' cut ftau`i' if ptaumax`i' > 2.4, hor blcolor(dknavy) legend(off)) ///
			(rscatter cut cut ftau`i' if ptaumax`i' > 2.4, hor mcolor(white) msymbol(smsquare) msize(vlarge) legend(off)) ///
			(rscatter ptau50`i' ptau50`i' ftau`i' if ptau50`i' <= 2.4, hor mcolor(red) msymbol(smcircle) msize(vlarge) legend(off)) ///
		 	(rcap poverallmin poverallmax foverall if poverallmax <= 2.4, hor blcolor(dknavy) legend(off)) ///
		 	(rcap poverallmin cut foverall if poverallmax > 2.4, hor blcolor(dknavy) legend(off)) ///
		 	(rscatter cut cut foverall if poverallmax > 2.4, hor mcolor(white) msymbol(smsquare) msize(vlarge) legend(off)) ///
		 	(rscatter poverall50 poverall50 foverall if poverall50 <= 2.4, hor mcolor(red) msymbol(smdiamond) msize(vlarge) legend(off)) ///
		 	(rcap phr1min`i' phr1max`i' fhr1`i' if phr1max`i' <= 2.4, hor blcolor(dknavy) legend(off)) ///
		 	(rcap phr1min`i' cut fhr1`i' if phr1max`i' > 2.4, hor blcolor(dknavy) legend(off)) ///
		 	(rscatter cut cut fhr1`i' if phr1max`i' > 2.4, hor mcolor(white) msymbol(smsquare) msize(vlarge) legend(off)) ///
		 	(rscatter phr150`i' phr150`i' fhr1`i' if phr150`i' <= 2.4, hor mcolor(red) msymbol(smsquare) msize(vlarge) legend(off)) ///
		 	(rcap pdeltamin`i' pdeltamax`i' fdelta`i' if pdeltamax`i' <= 2.4, hor blcolor(dknavy) legend(off)) ///
		 	(rcap pdeltamin`i' cut fdelta`i' if pdeltamax`i' > 2.4, hor blcolor(dknavy) legend(off)) ///
		 	(rscatter cut cut fdelta`i' if pdeltamax`i' > 2.4, hor mcolor(white) msymbol(smsquare) msize(large) legend(off)) ///
		 	(rscatter pdelta50`i' pdelta50`i' fdelta`i' if pdelta50`i' <= 2.4, hor mcolor(red) msymbol(smsquare) msize(vlarge) legend(off)) ///
		 	(rspike high low f1, blcolor(dknavy) legend(off)), ///
				text(7 2.75 "interaction", place(n)) ///
				text(10 2.75 "overall HR", place(n)) ///
				text(9 2.75 "`factorvar`i''=0", place(n)) ///
				text(8 2.75 "`factorvar`i''=1", place(n)) ///
				ylabel(none) ///
				xlabel(0 0.5 1 1.5 2 2.5 3) ///
				ytitle(" ") ///
				xtitle("HR / RHR") ///
				title("`trtvar' with `factorvar`i''") ///
				saving(g`i', replace)
		
		}
		else {
		
		preserve
		drop _all
		qui set obs 1
		gen ftau`i' =7
		if ln(`lbtau`i'') > -2.5 {
			gen ptaumin`i'=ln(`lbtau`i'') 
		}
		else {
			gen ptaumin`i'=-2.5
		}
		gen ptau50`i'=ln(`tau`i'')
		gen ptaumax`i'=ln(`ubtau`i'')
			

		gen foverall = 10
		if ln(`lboverall') > -2.5 {
			gen poverallmin = ln(`lboverall')
		}
		else {
			gen poverallmin = -2.5
		}
		gen poverall50 = ln(`overall')
		gen poverallmax = ln(`uboverall')

		gen fhr1`i' = 8
		if ln(`lbdelta`i'1') > -2.5 {
			gen phr1min`i' = ln(`lbdelta`i'1')
		}
		else {
			gen phr1min`i' = -2.5
		}
		gen phr150`i' = ln(`delta`i'1')
		gen phr1max`i' = ln(`ubdelta`i'1')

		gen fdelta`i' = 9
		if ln(`lbdelta`i'0') > -2.5 {
			gen pdeltamin`i' = ln(`lbdelta`i'0')
		}
		else {
			gen pdeltamin`i' = -2.5
		}
		gen pdelta50`i' = ln(`delta`i'0')
		gen pdeltamax`i' = ln(`ubdelta`i'0')

		gen f1 = 0
		gen high = 11
		gen low = 6.5
		
		gen cut = 2.2
		gen cut2 = -2.5
		
		set scheme cycle
		
		
		*forestplot graphic generation
		twoway (rcap ptaumin`i' ptaumax`i' ftau`i' if ptaumax`i' <= 2.2, hor blcolor(dknavy) legend(off)) ///
			(rcap ptaumin`i' cut ftau`i' if ptaumax`i' > 2.2, hor blcolor(dknavy) legend(off)) ///
			(rscatter cut cut ftau`i' if ptaumax`i' > 2.2, hor mcolor(white) msymbol(smsquare) msize(vlarge) legend(off)) ///
			(rscatter cut2 cut2 ftau`i' if ptaumin`i'<= -2.5, hor mcolor(white) msymbol(smsquare) msize(vlarge) legend(off)) ///
			(rscatter ptau50`i' ptau50`i' ftau`i' if ptau50`i' <= 2.2 & ptau50`i' > -2.5, hor mcolor(red) msymbol(smcircle) msize(vlarge) legend(off)) ///
		 	(rcap poverallmin poverallmax foverall if poverallmax <= 2.2, hor blcolor(dknavy) legend(off)) ///
		 	(rcap poverallmin cut foverall if poverallmax > 2.2, hor blcolor(dknavy) legend(off)) ///
		 	(rscatter cut cut foverall if poverallmax > 2.2, hor mcolor(white) msymbol(smsquare) msize(vlarge) legend(off)) ///
		 	(rscatter cut2 cut2 foverall if poverallmin<=-2.5, hor mcolor(white) msymbol(smsquare) msize(vlarge) legend(off)) ///
		 	(rscatter poverall50 poverall50 foverall if poverall50 <= 2.2 & poverall50 > -2.5, hor mcolor(red) msymbol(smdiamond) msize(vlarge) legend(off)) ///
		 	(rcap phr1min`i' phr1max`i' fhr1`i' if phr1max`i' <= 2.2, hor blcolor(dknavy) legend(off)) ///
		 	(rcap phr1min`i' cut fhr1`i' if phr1max`i' > 2.2, hor blcolor(dknavy) legend(off)) ///
		 	(rscatter cut cut fhr1`i' if phr1max`i' > 2.2, hor mcolor(white) msymbol(smsquare) msize(vlarge) legend(off)) ///
		 	(rscatter cut2 cut2 fhr1`i' if phr1min`i'<=-2.5, hor mcolor(white) msymbol(smsquare) msize(vlarge) legend(off)) ///
		 	(rscatter phr150`i' phr150`i' fhr1`i' if phr150`i' <= 2.2 & phr150`i' > -2.5, hor mcolor(red) msymbol(smsquare) msize(vlarge) legend(off)) ///
		 	(rcap pdeltamin`i' pdeltamax`i' fdelta`i' if pdeltamax`i' <= 2.2, hor blcolor(dknavy) legend(off)) ///
		 	(rcap pdeltamin`i' cut fdelta`i' if pdeltamax`i' > 2.2, hor blcolor(dknavy) legend(off)) ///
		 	(rscatter cut cut fdelta`i' if pdeltamax`i' > 2.2, hor mcolor(white) msymbol(smsquare) msize(large) legend(off)) ///
		 	(rscatter cut2 cut2 fdelta`i' if pdeltamin`i'<=-2.5, hor mcolor(white) msymbol(smsquare) msize(large) legend(off)) ///
		 	(rscatter pdelta50`i' pdelta50`i' fdelta`i' if pdelta50`i' <= 2.2 & pdelta50`i' > -2.5, hor mcolor(red) msymbol(smsquare) msize(vlarge) legend(off)) ///
		 	(rspike high low f1, blcolor(dknavy) legend(off)), ///
				text(7 3 "interaction", place(n)) ///
				text(10 3 "overall HR", place(n)) ///
				text(9 3 "`factorvar`i''=0", place(n)) ///
				text(8 3 "`factorvar`i''=1", place(n)) ///
				ylabel(none) ///
				xlabel(-2.5 -1.5 -0.5 0 0.5 1.5 2.5 3.5) ///
				ytitle(" ") ///
				xtitle("HR / RHR") ///
				title("`trtvar' with `factorvar`i''") ///
				saving(g`i', replace)
		}
		
		local gphs `gphs' g`i'.gph
		restore
	}
	
	if `n' > 2{
		graph combine `gphs', title("Forest plot for interactions with `trtvar'") 
	}
	else {
		graph combine `gphs', title("Forest plot for interaction with `trtvar'") ycommon xcommon
	}
	
	noi di as text " "
	noi di as text "Analysed using Cox proportional hazards model"
	noi di as text " "
		
}
	
end





program define fintcoxb, rclass

version 8.0

st_is 2 analysis

syntax varlist(min=2 max=2) [if] [in] [, by(varname) strata(varname) logistic(numlist) logscale(numlist)]


quietly {

	tempname level z 
	
	local trtvar: word 1 of `varlist'
	local factorvar: word 2 of `varlist'
	
	if `"`if'`in'"'!="" {
		keep `if' `in'
	}

	tempname trt
	egen int `trt' = group(`trtvar')
	replace `trt' = `trt' - 1
	assert `trt' == 0 | `trt' == 1
	
	tempname factor
	egen `factor' = group(`factorvar')
	replace `factor' = `factor' - 1
	assert `trt' == 0 | `trt' == 1
	
	tempvar byvar
	egen int `byvar' = group(`by')
	sum `byvar'
	local nby = r(max)
	
	scalar `level'=1-(100-$S_level)/200
	scalar `z'=invnorm(`level')
	
	forval b=1/`nby' {
	
		* get overall hazard ratio
		tempname lnoverall`b' overall`b' lboverall`b' uboverall`b'
		stcox `trt' if `byvar'==`b', strata(`strata')
		scalar `lnoverall`b'' = _b[`trt']
		scalar `overall`b'' = exp(_b[`trt'])
		scalar `lboverall`b'' = exp(_b[`trt'] - (`z'*_se[`trt']))
		scalar `uboverall`b'' = exp(_b[`trt'] + (`z'*_se[`trt']))

		*calculation of RHR
		tempname lntau`b' tau`b' lbtau`b' ubtau`b' lnu`b' lndelta`b'0 delta`b'0 /*
		*/ ubdelta`b'0 lbdelta`b'0 lntaudeltau`b' 
		gen trt_factor = `trt'*`factor'
		stcox `trt' `factor' trt_factor if `byvar'==`b', strata(`strata')
		scalar `lntau`b'' = _b[trt_factor]
		scalar `tau`b'' = exp(_b[trt_factor])
		scalar `lbtau`b'' = exp(_b[trt_factor] - (`z'*_se[trt_factor]))
		scalar `ubtau`b'' = exp(_b[trt_factor] + (`z'*_se[trt_factor]))
		scalar `lnu`b'' = _b[`factor']
		scalar `lndelta`b'0' = _b[`trt']
		scalar `delta`b'0' = exp(_b[`trt'])
		scalar `lbdelta`b'0' = exp(_b[`trt'] - (`z'*_se[`trt']))
		scalar `ubdelta`b'0' = exp(_b[`trt'] + (`z'*_se[`trt']))
		
		tempname lbdelta`b'1 ubdelta`b'1 lndelta`b'1 delta`b'1
		lincom 2*_b[`factor'] + _b[`trt'] + _b[trt_factor]
		scalar `lndelta`b'1' = r(estimate)
		scalar `lbdelta`b'1' = exp(r(estimate)-(`z'*r(se)))
		scalar `ubdelta`b'1' = exp(r(estimate)+(`z'*r(se)))
		scalar `delta`b'1' = exp(`lndelta`b'1')
		
		drop trt_factor
	}
	
	*display of 2*2 table
	
	
	forval b=1/`nby' {
		noi di in gr "-> for `by'==`b'"
		noi di in gr " "
		noi di in gr "Factor" _col(20) in gr "{c |} lnHR" _col(33) in gr "HR" _col(44) in gr "[95% Conf. Interval]"
		noi di in gr _dup(19) "{c -}" _col(20) in gr "{c +}" in gr _dup(43) "{c -}"
		noi di in gr "overall HR" _col(20) in gr "{c |}" _col(21) in ye `lnoverall`b'' _col(33) in ye `overall`b'' _col(44) in ye `lboverall`b'' _col(55) `uboverall`b''
		noi di in gr "`factorvar'=0" _col(20) in gr "{c |}" _col(21) in ye `lndelta`b'0' _col(33) in ye `delta`b'0' _col(44) in ye `lbdelta`b'0' _col(55) `ubdelta`b'0'
		noi di in gr "`factorvar'=1" _col(20) in gr "{c |}" _col(21) in ye `lndelta`b'1' _col(33) in ye `delta`b'1' _col(44) in ye `lbdelta`b'1' _col(55) `ubdelta`b'1'
		noi di in gr " "
		noi di in gr " "
		noi di in gr "Factor" _col(20) in gr "{c |} lnRHR" _col(33) in gr "RHR" _col(44) in gr "[95% Conf. Interval]"
		noi di in gr _dup(19) "{c -}" _col(20) in gr "{c +}" in gr _dup(43) "{c -}"
		noi di in gr "interaction" _col(20) in gr "{c |}" _col(21) in ye `lntau`b'' _col(33) in ye `tau`b'' _col(44) in ye `lbtau`b'' _col(55) `ubtau`b''
		noi di as text " "
		if `"`strata'"'!="" {
			noi di in gr "Stratified by `strata'"
			noi di in gr " "
		}

		return scalar overall = `overall`b''
		return scalar uboverall = `uboverall`b''
		return scalar lboverall = `lboverall`b''
		return scalar delta`i'0 = `delta`b'0'
		return scalar ubdelta`i'0 = `ubdelta`b'0'
		return scalar lbdelta`i'0 = `lbdelta`b'0'
		return scalar delta`i'1 = `delta`b'1'
		return scalar ubdelta`i'1 = `ubdelta`b'1'
		return scalar lbdelta`i'1 = `lbdelta`b'1'
		return scalar tau`i' = `tau`b''
		return scalar ubtau`i' = `ubtau`b''
		return scalar lbtau`i' = `lbtau`b''
	
	
		*parameters for graphics
	
		if `logscale'==0 {

		preserve
		drop _all
		qui set obs 1
		gen ftau`b' =7
		gen ptaumin`b'=`lbtau`b''
		gen ptau50`b'=`tau`b''
		gen ptaumax`b'=`ubtau`b''
			

		gen foverall`b' = 10
		gen poverallmin`b' = `lboverall`b''
		gen poverall50`b' = `overall`b''
		gen poverallmax`b' = `uboverall`b''

		gen fhr1`b' = 8
		gen phr1min`b' = `lbdelta`b'1'
		gen phr150`b' = `delta`b'1'
		gen phr1max`b' = `ubdelta`b'1'

		gen fdelta`b' = 9
		gen pdeltamin`b' = `lbdelta`b'0'
		gen pdelta50`b' = `delta`b'0'
		gen pdeltamax`b' = `ubdelta`b'0'

		gen f1 = 1
		gen high = 11
		gen low = 6.5
		
		gen cut = 2.4
		
		set scheme cycle
		
		
		*forestplot graphic generation
		twoway (rcap ptaumin`b' ptaumax`b' ftau`b' if ptaumax`b' <= 2.4, hor blcolor(dknavy) legend(off)) ///
			(rcap ptaumin`b' cut ftau`b' if ptaumax`b' > 2.4, hor blcolor(dknavy) legend(off)) ///
			(rscatter cut cut ftau`b' if ptaumax`b' > 2.4, hor mcolor(white) msymbol(smsquare) msize(vlarge) legend(off)) ///
			(rscatter ptau50`b' ptau50`b' ftau`b' if ptau50`b' <= 2.4, hor mcolor(red) msymbol(smcircle) msize(vlarge) legend(off)) ///
		 	(rcap poverallmin`b' poverallmax`b' foverall`b' if poverallmax`b' <= 2.4, hor blcolor(dknavy) legend(off)) ///
		 	(rcap poverallmin`b' cut foverall`b' if poverallmax`b' > 2.4, hor blcolor(dknavy) legend(off)) ///
		 	(rscatter cut cut foverall`b' if poverallmax`b' > 2.4, hor mcolor(white) msymbol(smsquare) msize(vlarge) legend(off)) ///
		 	(rscatter poverall50`b' poverall50`b' foverall`b' if poverall50`b' <= 2.4, hor mcolor(red) msymbol(smdiamond) msize(vlarge) legend(off)) ///
		 	(rcap phr1min`b' phr1max`b' fhr1`b' if phr1max`b' <= 2.4, hor blcolor(dknavy) legend(off)) ///
		 	(rcap phr1min`b' cut fhr1`b' if phr1max`b' > 2.4, hor blcolor(dknavy) legend(off)) ///
		 	(rscatter cut cut fhr1`b' if phr1max`b' > 2.4, hor mcolor(white) msymbol(smsquare) msize(vlarge) legend(off)) ///
		 	(rscatter phr150`b' phr150`b' fhr1`b' if phr150`b' <= 2.4, hor mcolor(red) msymbol(smsquare) msize(vlarge) legend(off)) ///
		 	(rcap pdeltamin`b' pdeltamax`b' fdelta`b' if pdeltamax`b' <= 2.4, hor blcolor(dknavy) legend(off)) ///
		 	(rcap pdeltamin`b' cut fdelta`b' if pdeltamax`b' > 2.4, hor blcolor(dknavy) legend(off)) ///
		 	(rscatter cut cut fdelta`b' if pdeltamax`b' > 2.4, hor mcolor(white) msymbol(smsquare) msize(large) legend(off)) ///
		 	(rscatter pdelta50`b' pdelta50`b' fdelta`b' if pdelta50`b' <= 2.4, hor mcolor(red) msymbol(smsquare) msize(vlarge) legend(off)) ///
		 	(rspike high low f1, blcolor(dknavy) legend(off)), ///
				text(7 2.75 "interaction", place(n)) ///
				text(10 2.75 "overall HR", place(n)) ///
				text(9 2.75 "`factorvar'=0", place(n)) ///
				text(8 2.75 "`factorvar'=1", place(n)) ///
				ylabel(none) ///
				xlabel(0 0.5 1 1.5 2 2.5 3) ///
				ytitle(" ") ///
				xtitle("HR / RHR") ///
				title("for `by'==`b'") ///
				saving(g`b', replace)
		
		}
		else {
		
		preserve
		drop _all
		qui set obs 1
		gen ftau`b' =7
		if ln(`lbtau`b'') > -2.5 {
			gen ptaumin`b'=ln(`lbtau`b'')
		}
		else {
			gen ptaumin`b'=-2.5
		}
		gen ptau50`b'=ln(`tau`b'')
		gen ptaumax`b'=ln(`ubtau`b'')
			

		gen foverall`b' = 10
		if ln(`lboverall`b'')>-2.5 {
			gen poverallmin`b' = ln(`lboverall`b'')
		}
		else {
			gen poverallmin`b'=-2.5
		}
		gen poverall50`b' = ln(`overall`b'')
		gen poverallmax`b' = ln(`uboverall`b'')

		gen fhr1`b' = 8
		if ln(`lbdelta`b'1') > -2.5 {
			gen phr1min`b' = ln(`lbdelta`b'1')
		}
		else {
			gen phr1min`b'=-2.5
		}
		gen phr150`b' = ln(`delta`b'1')
		gen phr1max`b' = ln(`ubdelta`b'1')

		gen fdelta`b' = 9
		if ln(`lbdelta`b'0') > -2.5 {
			gen pdeltamin`b' = ln(`lbdelta`b'0')
		} 
		else {
			gen pdeltamin`b' = -2.5
		}
		gen pdelta50`b' = ln(`delta`b'0')
		gen pdeltamax`b' = ln(`ubdelta`b'0')

		gen f1 = 0
		gen high = 11
		gen low = 6.5
		
		gen cut = 2.2
		gen cut2 = -2.5
		
		set scheme cycle
		
		
		*forestplot graphic generation
		twoway (rcap ptaumin`b' ptaumax`b' ftau`b' if ptaumax`b' <= 2.2, hor blcolor(dknavy) legend(off)) ///
			(rcap ptaumin`b' cut ftau`b' if ptaumax`b' > 2.2, hor blcolor(dknavy) legend(off)) ///
			(rscatter cut cut ftau`b' if ptaumax`b' > 2.2, hor mcolor(white) msymbol(smsquare) msize(vlarge) legend(off)) ///
			(rscatter cut2 cut2 ftau`b' if ptaumin`b'<=-2.5, hor mcolor(white) msymbol(smsquare) msize(vlarge) legend(off)) ///
			(rscatter ptau50`b' ptau50`b' ftau`b' if ptau50`b' <= 2.2 & ptau50`b' > -2.5, hor mcolor(red) msymbol(smcircle) msize(vlarge) legend(off)) ///
		 	(rcap poverallmin`b' poverallmax`b' foverall`b' if poverallmax`b' <= 2.2, hor blcolor(dknavy) legend(off)) ///
		 	(rcap poverallmin`b' cut foverall`b' if poverallmax`b' > 2.2, hor blcolor(dknavy) legend(off)) ///
		 	(rscatter cut cut foverall`b' if poverallmax`b' > 2.2, hor mcolor(white) msymbol(smsquare) msize(vlarge) legend(off)) ///
		 	(rscatter cut2 cut2 foverall`b' if poverallmin`b'<=-2.5, hor mcolor(white) msymbol(smsquare) msize(vlarge) legend(off)) ///
		 	(rscatter poverall50`b' poverall50`b' foverall`b' if poverall50`b' <= 2.2 & poverall50`b' > -2.5, hor mcolor(red) msymbol(smdiamond) msize(vlarge) legend(off)) ///
		 	(rcap phr1min`b' phr1max`b' fhr1`b' if phr1max`b' <= 2.2, hor blcolor(dknavy) legend(off)) ///
		 	(rcap phr1min`b' cut fhr1`b' if phr1max`b' > 2.2, hor blcolor(dknavy) legend(off)) ///
		 	(rscatter cut cut fhr1`b' if phr1max`b' > 2.2, hor mcolor(white) msymbol(smsquare) msize(vlarge) legend(off)) ///
		 	(rscatter cut2 cut2 fhr1`b' if phr1min`b'<=-2.5, hor mcolor(white) msymbol(smsquare) msize(vlarge) legend(off)) ///
		 	(rscatter phr150`b' phr150`b' fhr1`b' if phr150`b' <= 2.2 & phr150`b' > -2.5, hor mcolor(red) msymbol(smsquare) msize(vlarge) legend(off)) ///
		 	(rcap pdeltamin`b' pdeltamax`b' fdelta`b' if pdeltamax`b' <= 2.2, hor blcolor(dknavy) legend(off)) ///
		 	(rcap pdeltamin`b' cut fdelta`b' if pdeltamax`b' > 2.2, hor blcolor(dknavy) legend(off)) ///
		 	(rscatter cut cut fdelta`b' if pdeltamax`b' > 2.2, hor mcolor(white) msymbol(smsquare) msize(large) legend(off)) ///
		 	(rscatter cut2 cut2 fdelta`b' if pdeltamin`b'<=-2.5, hor mcolor(white) msymbol(smsquare) msize(large) legend(off)) ///
		 	(rscatter pdelta50`b' pdelta50`b' fdelta`b' if pdelta50`b' <= 2.2 & pdelta50`b' > -2.5, hor mcolor(red) msymbol(smsquare) msize(vlarge) legend(off)) ///
		 	(rspike high low f1, blcolor(dknavy) legend(off)), ///
				text(7 3 "interaction", place(n)) ///
				text(10 3 "overall HR", place(n)) ///
				text(9 3 "`factorvar'=0", place(n)) ///
				text(8 3 "`factorvar'=1", place(n)) ///
				ylabel(none) ///
				xlabel(-2.5 -1.5 -0.5 0 0.5 1.5 2.5 3.5) ///
				ytitle(" ") ///
				xtitle("lnHR / lnHRH") ///
				title("for `by'==`b'") ///
				saving(g`b', replace)
		}
		
		local gphs `gphs' g`b'.gph
		restore
		}
	graph combine `gphs', title("Forest plot with interaction for `trtvar' and `factorvar'") ycommon xcommon
	
	}
	noi di as text " "
	noi di as text "Analysed using Cox proportional hazards model"
	noi di as text " "
	
end




	



	

