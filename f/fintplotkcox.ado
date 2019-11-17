* forestplot for cox 2*k version 1.1 SB 05May2006

program fintplotkcox, rclass

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
		tempname lntau`i' tau`i' lbtau`i' ubtau`i'
		gen trt_factor`i' = `trt'*`factor`i''
		stcox `trt' `factor`i'' trt_factor`i', strata(`strata')
		scalar `lntau`i'' = _b[trt_factor`i']
		scalar `tau`i'' = exp(_b[trt_factor`i'])
		scalar `lbtau`i'' = exp(_b[trt_factor`i'] - (`z'*_se[trt_factor`i']))
		scalar `ubtau`i'' = exp(_b[trt_factor`i'] + (`z'*_se[trt_factor`i']))
		
		drop trt_factor`i'
	}
	
	*display of 2*2 table
	
	noi di as text "OVERALL HAZARD RATIO"
	noi di as text " "
	noi di in gr "Factor" _col(20) in gr "{c |} lnHR" _col(33) in gr "HR" _col(44) in gr "[95% Conf. Interval]"
	noi di in gr _dup(19) "{c -}" _col(20) in gr "{c +}" in gr _dup(43) "{c -}"
	noi di in gr "overall HR" _col(20) in gr "{c |}" _col(21) in ye `lnoverall' _col(33) in ye `overall' _col(44) in ye `lboverall' _col(55) `uboverall'
	noi di as text " "
	noi di as text "INTERACTIONS WITH `trtvar'"
	noi di as text " "
	noi di in gr "Factor" _col(20) in gr "{c |} lnRHR" _col(33) in gr "RHR" _col(44) in gr "[95% Conf. Interval]"
	noi di in gr _dup(19) "{c -}" _col(20) in gr "{c +}" in gr _dup(43) "{c -}"

	forval i=2/`n' {
		noi di in gr "`factorvar`i''" _col(20) in gr "{c |}" _col(21) in ye `lntau`i'' _col(33) in ye `tau`i'' _col(44) in ye `lbtau`i'' _col(55) `ubtau`i''
	}
		noi di as text " "
		noi di as text "Analysed using Cox proportional hazards model"
		noi di as text " "
		if `"`strata'"'!="" {
			noi di in gr "Stratified by `strata'"
			noi di in gr " "
		}
	forval i=2/`n' {
		
		return scalar overall = `overall'
		return scalar uboverall = `uboverall'
		return scalar lboverall = `lboverall'
		return scalar tau`i' = `tau`i''
		return scalar ubtau`i' = `ubtau`i''
		return scalar lbtau`i' = `lbtau`i''
		
	}

		*parameters for graphics
	
		if `logscale'==0 {
		
			preserve
			drop _all
			qui set obs 1
			gen foverall = 10
			gen poverallmin = `lboverall'
			gen poverall50 = `overall'
			gen poverallmax = `uboverall'
			forval i=2/`n' {
				gen lbtau`i' = `lbtau`i''
				gen tau`i' = `tau`i''
				gen ubtau`i' = `ubtau`i''
			}
			
			if `n'<6 {
			local n1 = `n'+1
				forval i=`n1'/6 {
					gen lbtau`i'= -100001
					gen tau`i' = -100001
					gen ubtau`i'= -100001
				}
			}
			

			gen f1 = 1
			gen high = 10.5
		
			gen cut = 2.4
	
			gen ftau2=9.5
			gen ftau3=9
			gen ftau4=8.5
			gen ftau5=8
			gen ftau6=7.5
			
			if `n' < 5{
				gen low = 8
			}
			else {
				gen low = 7
			}
				
			set scheme cycle
		
			*forestplot graphic generation
			twoway (rcap lbtau2 ubtau2 ftau2 if ubtau2 <= 2.4, hor blcolor(dknavy) legend(off)) ///
				(rcap lbtau2 cut ftau2 if ubtau2 > 2.4, hor blcolor(dknavy) legend(off)) ///
				(rscatter cut cut ftau2 if ubtau2 > 2.4, hor mcolor(white) msymbol(smsquare) msize(vlarge) legend(off)) ///
				(rscatter tau2 tau2 ftau2 if tau2 <= 2.4, hor mcolor(red) msymbol(smcircle) msize(vlarge) legend(off)) ///
				(rcap lbtau3 ubtau3 ftau3 if ubtau3 <= 2.4 & tau3 > -100000, hor blcolor(dknavy) legend(off)) ///
				(rcap lbtau3 cut ftau3 if ubtau3 > 2.4 & tau3 > -100000, hor blcolor(dknavy) legend(off)) ///
				(rscatter cut cut ftau3 if ubtau3 > 2.4 & tau3 > -100000, hor mcolor(white) msymbol(smsquare) msize(vlarge) legend(off)) ///
				(rscatter tau3 tau3 ftau3 if tau3 <= 2.4 & tau3 > -100000, hor mcolor(red) msymbol(smcircle) msize(vlarge) legend(off)) ///
				(rcap lbtau4 ubtau4 ftau4 if ubtau4 <= 2.4 & tau4 > -100000, hor blcolor(dknavy) legend(off)) ///
				(rcap lbtau4 cut ftau4 if ubtau4 > 2.4 & tau4 > -100000, hor blcolor(dknavy) legend(off)) ///
				(rscatter cut cut ftau4 if ubtau4 > 2.4 & tau4 > -100000, hor mcolor(white) msymbol(smsquare) msize(vlarge) legend(off)) ///
				(rscatter tau4 tau4 ftau4 if tau4 <= 2.4 & tau4 > -100000, hor mcolor(red) msymbol(smcircle) msize(vlarge) legend(off)) ///
				(rcap lbtau5 ubtau5 ftau5 if ubtau5 <= 2.4 & tau5 > -100000, hor blcolor(dknavy) legend(off)) ///
				(rcap lbtau5 cut ftau5 if ubtau5 > 2.4 & tau5 > -100000, hor blcolor(dknavy) legend(off)) ///
				(rscatter cut cut ftau5 if ubtau5 > 2.4 & tau5 > -100000, hor mcolor(white) msymbol(smsquare) msize(vlarge) legend(off)) ///
				(rscatter tau5 tau5 ftau5 if tau5 <= 2.4 & tau5 > -100000, hor mcolor(red) msymbol(smcircle) msize(vlarge) legend(off)) ///
				(rcap lbtau6 ubtau6 ftau6 if ubtau6 <= 2.4 & tau6 > -100000, hor blcolor(dknavy) legend(off)) ///
				(rcap lbtau6 cut ftau6 if ubtau6 > 2.4 & tau6 > -100000, hor blcolor(dknavy) legend(off)) ///
				(rscatter cut cut ftau6 if ubtau6 > 2.4 & tau6 > -100000, hor mcolor(white) msymbol(smsquare) msize(vlarge) legend(off)) ///
				(rscatter tau6 tau6 ftau6 if tau6 <= 2.4 & tau6 > -100000, hor mcolor(red) msymbol(smcircle) msize(vlarge) legend(off)) ///
	 			(rcap poverallmin poverallmax foverall if poverallmax <= 2.4, hor blcolor(dknavy) legend(off)) ///
	 			(rcap poverallmin cut foverall if poverallmax > 2.4, hor blcolor(dknavy) legend(off)) ///		 			(rscatter cut cut foverall if poverallmax > 2.4, hor mcolor(white) msymbol(smsquare) msize(vlarge) legend(off)) ///
		 		(rscatter poverall50 poverall50 foverall if poverall50 <= 2.4, hor mcolor(red) msymbol(smdiamond) msize(vlarge) legend(off)) ///
		 		(rspike high low f1, blcolor(dknavy) legend(off)), ///
					text(9.5 2.75 "`factorvar2'", place(n)) ///
					text(9 2.75 "`factorvar3'", place(n)) ///
					text(8.5 2.75 "`factorvar4'", place(n)) ///
					text(8 2.75 "`factorvar5'", place(n)) ///
					text(7.5 2.75 "`factorvar6'", place(n)) ///
					text(10 2.75 "overall HR", place(n)) ///
					ylabel(none) ///
					xlabel(0 0.5 1 1.5 2 2.5 3) ///
					title("Forest plot for interaction with `trtvar'") ///
					ytitle(" ") ///
					xtitle("HR / RHR") ///
					saving(g`i', replace)
			
		
		}
		else {
		
		preserve
		drop _all
		set scheme cycle
		qui set obs 1
		forval i=2/`n' {
			if ln(`lbtau`i'') > -2.5 {
				gen lbtau`i'=ln(`lbtau`i'') 
			}
			else {
				gen lbtau`i'=-2.5
			}
			gen tau`i'=ln(`tau`i'')
			gen ubtau`i'=ln(`ubtau`i'')
		}
		
		if `n'<6 {
			local n1 = `n'+1
			forval i=`n1'/6 {
				gen lbtau`i'= -100001
				gen tau`i' = -100001
				gen ubtau`i'= -100001
			}
		}
			

		gen foverall = 10
		if ln(`lboverall') > -2.5 {
			gen poverallmin = ln(`lboverall')
		}
		else {
			gen poverallmin = -2.5
		}
		gen poverall50 = ln(`overall')
		gen poverallmax = ln(`uboverall')

		gen f1 = 0
		gen high = 10.5
		
		gen cut = 2.2
		gen cut2 = -2.5
		
		gen ftau2=9.5
		gen ftau3=9
		gen ftau4=8.5
		
			
		gen ftau5=8
		gen ftau6=7.5
			
		if `n' < 5{
			gen low = 8
		}
		else {
			gen low = 7
		}
			
		*forestplot graphic generation
		twoway (rcap lbtau2 ubtau2 ftau2 if ubtau2 <= 2.2, hor blcolor(dknavy) legend(off)) ///
			(rcap lbtau2 cut ftau2 if ubtau2 > 2.2, hor blcolor(dknavy) legend(off)) ///
			(rscatter cut cut ftau2 if ubtau2 > 2.2, hor mcolor(white) msymbol(smsquare) msize(vlarge) legend(off)) ///
			(rscatter cut2 cut2 ftau2 if ubtau2<= -2.5, hor mcolor(white) msymbol(smsquare) msize(vlarge) legend(off)) ///
			(rscatter tau2 tau2 ftau2 if tau2 <= 2.2 & tau2 > -2.5, hor mcolor(red) msymbol(smcircle) msize(vlarge) legend(off)) ///
			(rcap lbtau3 ubtau3 ftau3 if ubtau3 <= 2.2 & tau3 > -100000, hor blcolor(dknavy) legend(off)) ///
			(rcap lbtau3 cut ftau3 if ubtau3 > 2.2 & tau3 > -100000, hor blcolor(dknavy) legend(off)) ///
			(rscatter cut cut ftau3 if ubtau3 > 2.2 & tau3 > -100000, hor mcolor(white) msymbol(smsquare) msize(vlarge) legend(off)) ///
			(rscatter cut2 cut2 ftau3 if ubtau3<= -2.5 & tau3 > -100000, hor mcolor(white) msymbol(smsquare) msize(vlarge) legend(off)) ///
			(rscatter tau3 tau3 ftau3 if tau3 <= 2.2 & tau3 > -2.5 & tau3 > -100000, hor mcolor(red) msymbol(smcircle) msize(vlarge) legend(off)) ///
			(rcap lbtau4 ubtau4 ftau4 if ubtau4 <= 2.2 & tau4 > -100000, hor blcolor(dknavy) legend(off)) ///
			(rcap lbtau4 cut ftau4 if ubtau4 > 2.2 & tau4 > -100000, hor blcolor(dknavy) legend(off)) ///
			(rscatter cut cut ftau4 if ubtau4 > 2.2 & tau4 > -100000, hor mcolor(white) msymbol(smsquare) msize(vlarge) legend(off)) ///
			(rscatter cut2 cut2 ftau4 if ubtau4<= -2.5 & tau4 > -100000, hor mcolor(white) msymbol(smsquare) msize(vlarge) legend(off)) ///
			(rscatter tau4 tau4 ftau4 if tau4 <= 2.2 & tau4 > -2.5 & tau4 > -100000, hor mcolor(red) msymbol(smcircle) msize(vlarge) legend(off)) ///
			(rcap lbtau5 ubtau5 ftau5 if ubtau5 <= 2.2 & tau5 > -100000, hor blcolor(dknavy) legend(off)) ///
			(rcap lbtau5 cut ftau5 if ubtau5 > 2.2 & tau5 > -100000, hor blcolor(dknavy) legend(off)) ///
			(rscatter cut cut ftau5 if ubtau5 > 2.2 & tau5 > -100000, hor mcolor(white) msymbol(smsquare) msize(vlarge) legend(off)) ///
			(rscatter cut2 cut2 ftau5 if ubtau5<= -2.5 & tau5 > -100000, hor mcolor(white) msymbol(smsquare) msize(vlarge) legend(off)) ///
			(rscatter tau2 tau2 ftau5 if tau5 <= 2.2 & tau5 > -2.5 & tau5 > -100000, hor mcolor(red) msymbol(smcircle) msize(vlarge) legend(off)) ///
			(rcap lbtau6 ubtau6 ftau6 if ubtau6 <= 2.2 & tau6 > -100000, hor blcolor(dknavy) legend(off)) ///
			(rcap lbtau6 cut ftau6 if ubtau6 > 2.2 & tau6 > -100000, hor blcolor(dknavy) legend(off)) ///
			(rscatter cut cut ftau6 if ubtau6 > 2.2 & tau6 > -100000, hor mcolor(white) msymbol(smsquare) msize(vlarge) legend(off)) ///
			(rscatter cut2 cut2 ftau6 if ubtau6<= -2.5 & tau6 > -100000, hor mcolor(white) msymbol(smsquare) msize(vlarge) legend(off)) ///
			(rscatter tau6 tau6 ftau6 if tau6 <= 2.2 & tau6 > -2.5 & tau6 > -100000, hor mcolor(red) msymbol(smcircle) msize(vlarge) legend(off)) ///
		 	(rcap poverallmin poverallmax foverall if poverallmax <= 2.2, hor blcolor(dknavy) legend(off)) ///
		 	(rcap poverallmin cut foverall if poverallmax > 2.2, hor blcolor(dknavy) legend(off)) ///
		 	(rscatter cut cut foverall if poverallmax > 2.2, hor mcolor(white) msymbol(smsquare) msize(vlarge) legend(off)) ///
		 	(rscatter cut2 cut2 foverall if poverallmin<=-2.5, hor mcolor(white) msymbol(smsquare) msize(vlarge) legend(off)) ///
		 	(rscatter poverall50 poverall50 foverall if poverall50 <= 2.2 & poverall50 > -2.5, hor mcolor(red) msymbol(smdiamond) msize(vlarge) legend(off)) ///
		 	(rspike high low f1, blcolor(dknavy) legend(off)), ///
				text(9.5 3 "`factorvar2'", place(n)) ///
				text(9 3 "`factorvar3'", place(n)) ///
				text(8.5 3 "`factorvar4'", place(n)) ///
				text(8 3 "`factorvar5'", place(n)) ///
				text(7.5 3 "`factorvar6'", place(n)) ///
				text(10 3 "overall lnHR", place(n)) ///
				ylabel(none) ///
				xlabel(-2.5 -1.5 -0.5 0 0.5 1.5 2.5 3.5) ///
				ytitle(" ") ///
				xtitle("lnHR / lnRHR") ///
				title("Forest plot for interaction with `trtvar'") ///
				saving(g`i', replace)
		}
		
		restore
		
}
	
end


