* forestplot logistic 2*k version 1.1 SB 05May2006

* program to calculate table for interaction and produce forest plots

program define fintplotklog, rclass

version 8.0

syntax varlist(min=3) [if] [in] [, logistic(numlist) logscale(numlist)]


quietly {

	tempname level z 
	
	local respvar: word 1 of `varlist'
	local trtvar: word 2 of `varlist'
	
	tokenize `varlist'
	local n : word count `varlist'

	forvalues i = 3/`n' {
		local factorvar`i': word `i' of `varlist'
		tempname factor`i'
		egen int `factor`i'' = group(`factorvar`i'')
		replace `factor`i'' = `factor`i'' - 1
	}

	tempname trt
	egen int `trt' = group(`trtvar')
	replace `trt' = `trt' - 1
	assert `trt' == 0 | `trt' == 1
	
	tempname resp
	egen int `resp' = group(`respvar')
	replace `resp' = `resp' - 1
	assert `resp' == 0 | `resp' == 1
	
	if `"`if'`in'"'!="" {
		keep `if' `in'
	}
	
	scalar `level'=1-(100-$S_level)/200
	scalar `z'=invnorm(`level')

	* get overall odds ratio
	tempname lnoverall overall lboverall uboverall
	logistic `resp' `trt'
	scalar `lnoverall' = _b[`trt']
	scalar `overall' = exp(_b[`trt'])
	scalar `lboverall' = exp(_b[`trt'] - (`z'*_se[`trt']))
	scalar `uboverall' = exp(_b[`trt'] + (`z'*_se[`trt']))

	forval i=3/`n' {

		*calculation of ROR
		tempname lntau`i' tau`i' lbtau`i' ubtau`i' 
		gen trt_factor = `trt'*`factor`i''
		logistic `resp' `trt' `factor`i'' trt_factor
		scalar `lntau`i'' = _b[trt_factor]
		scalar `tau`i'' = exp(_b[trt_factor])
		scalar `lbtau`i'' = exp(_b[trt_factor] - (`z'*_se[trt_factor]))
		scalar `ubtau`i'' = exp(_b[trt_factor] + (`z'*_se[trt_factor]))
		
		drop trt_factor
	}
	
	
	*display of 2*2 table
	
	noi di in gr "Response variable: `respvar'"
	noi di as text " "
	noi di as text "OVERALL ODDS RATIO"
	noi di as text " "
	noi di in gr "Factor" _col(20) in gr "{c |} lnOR" _col(33) in gr "OR" _col(44) in gr "[95% Conf. Interval]"
	noi di in gr _dup(19) "{c -}" _col(20) in gr "{c +}" in gr _dup(43) "{c -}"
	noi di in gr "overall OR" _col(20) in gr "{c |}" _col(21) in ye `lnoverall' _col(33) in ye `overall' _col(44) in ye `lboverall' _col(55) `uboverall'
	noi di as text " "
	noi di as text "INTERACTIONS WITH `trtvar'"
	noi di as text " "
	noi di in gr "Factor" _col(20) in gr "{c |} lnROR" _col(33) in gr "ROR" _col(44) in gr "[95% Conf. Interval]"
	noi di in gr _dup(19) "{c -}" _col(20) in gr "{c +}" in gr _dup(43) "{c -}"
	
	forval i=3/`n' {
				noi di in gr "`factorvar`i''" _col(20) in gr "{c |}" _col(21) in ye `lntau`i'' _col(33) in ye `tau`i'' _col(44) in ye `lbtau`i'' _col(55) `ubtau`i''
	}
	noi di as text " "
	noi di as text "Analysed using logistic regression"
		
	forval i=3/`n' {
		return scalar overall = `overall'
		return scalar uboverall = `uboverall'
		return scalar lboverall = `lboverall'
		return scalar tau`i' = `tau`i''
		return scalar ubtau`i' = `ubtau`i''
		return scalar lbtau`i' = `lbtau`i''
	
	
		*parameters for graphics
	
		if `logscale'==0 {

		preserve
			drop _all
			qui set obs 1
			gen foverall = 10
			gen poverallmin = `lboverall'
			gen poverall50 = `overall'
			gen poverallmax = `uboverall'
			forval i=3/`n' {
				gen lbtau`i' = `lbtau`i''
				gen tau`i' = `tau`i''
				gen ubtau`i' = `ubtau`i''
			}
			
			if `n'<7 {
			local n1 = `n'+1
				forval i=`n1'/7 {
					gen lbtau`i'= -100001
					gen tau`i' = -100001
					gen ubtau`i'= -100001
				}
			}
			

			gen f1 = 1
			gen high = 10.5
		
			gen cut = 2.4
	
			gen ftau3=9.5
			gen ftau4=9
			gen ftau5=8.5
			gen ftau6=8
			gen ftau7=7.5
			
			if `n' < 6{
				gen low = 8
			}
			else {
				gen low = 7
			}
				
			set scheme cycle
		
		*forestplot graphic generation
		twoway (rcap lbtau3 ubtau3 ftau3 if ubtau3 <= 9, hor blcolor(dknavy) legend(off)) ///
			(rcap lbtau3 cut ftau3 if ubtau3 > 9, hor blcolor(dknavy) legend(off)) ///
			(rscatter cut cut ftau3 if ubtau3 > 9, hor mcolor(white) msymbol(smsquare) msize(vlarge) legend(off)) ///
			(rscatter tau3 tau3 ftau3 if tau3 <= 9, hor mcolor(red) msymbol(smcircle) msize(vlarge) legend(off)) ///
			(rcap lbtau4 ubtau4 ftau4 if ubtau4 <= 9 & tau4 > -100000, hor blcolor(dknavy) legend(off)) ///
			(rcap lbtau4 cut ftau4 if ubtau4 > 9 & tau4 > -100000, hor blcolor(dknavy) legend(off)) ///
			(rscatter cut cut ftau4 if ubtau4 > 9 & tau4 > -100000, hor mcolor(white) msymbol(smsquare) msize(vlarge) legend(off)) ///
			(rscatter tau4 tau4 ftau4 if tau4 <= 9 & tau4 > -100000, hor mcolor(red) msymbol(smcircle) msize(vlarge) legend(off)) ///
			(rcap lbtau5 ubtau5 ftau5 if ubtau5 <= 9 & tau5 > -100000, hor blcolor(dknavy) legend(off)) ///
			(rcap lbtau5 cut ftau5 if ubtau5 > 9 & tau5 > -100000, hor blcolor(dknavy) legend(off)) ///
			(rscatter cut cut ftau5 if ubtau5 > 9 & tau5 > -100000, hor mcolor(white) msymbol(smsquare) msize(vlarge) legend(off)) ///
			(rscatter tau5 tau5 ftau5 if tau5 <= 9 & tau5 > -100000, hor mcolor(red) msymbol(smcircle) msize(vlarge) legend(off)) ///
			(rcap lbtau6 ubtau6 ftau6 if ubtau6 <= 9 & tau6 > -100000, hor blcolor(dknavy) legend(off)) ///
			(rcap lbtau6 cut ftau6 if ubtau6 > 9 & tau6 > -100000, hor blcolor(dknavy) legend(off)) ///
			(rscatter cut cut ftau6 if ubtau6 > 9 & tau6 > -100000, hor mcolor(white) msymbol(smsquare) msize(vlarge) legend(off)) ///
			(rscatter tau6 tau6 ftau6 if tau6 <= 9 & tau6 > -100000, hor mcolor(red) msymbol(smcircle) msize(vlarge) legend(off)) ///
			(rcap lbtau7 ubtau7 ftau7 if ubtau7 <= 9 & tau7 > -100000, hor blcolor(dknavy) legend(off)) ///
			(rcap lbtau7 cut ftau7 if ubtau7 > 9 & tau7 > -100000, hor blcolor(dknavy) legend(off)) ///
			(rscatter cut cut ftau7 if ubtau7 > 9 & tau7 > -100000, hor mcolor(white) msymbol(smsquare) msize(vlarge) legend(off)) ///
			(rscatter tau7 tau7 ftau7 if tau7 <= 9 & tau7 > -100000, hor mcolor(red) msymbol(smcircle) msize(vlarge) legend(off)) ///
		 	(rcap poverallmin poverallmax foverall if poverallmax <= 9, hor blcolor(dknavy) legend(off)) ///
		 	(rcap poverallmin cut foverall if poverallmax > 9, hor blcolor(dknavy) legend(off)) ///
		 	(rscatter cut cut foverall if poverallmax > 9, hor mcolor(white) msymbol(smsquare) msize(vlarge) legend(off)) ///
		 	(rscatter poverall50 poverall50 foverall if poverall50 <= 9, hor mcolor(red) msymbol(smdiamond) msize(vlarge) legend(off)) ///
		 	(rspike high low f1, blcolor(dknavy) legend(off)), ///
				text(9.5 10 "`factorvar3'", place(n)) ///
				text(9 10 "`factorvar4'", place(n)) ///
				text(8.5 10 "`factorvar5'", place(n)) ///
				text(8 10 "`factorvar6'", place(n)) ///
				text(7.5 10 "`factorvar7'", place(n)) ///
				text(10 10 "overall OR", place(n)) ///
				ylabel(none) ///
				xlabel(0 1 3 5 7 9 11) ///
				ytitle(" ") ///
				xtitle("OR / ROR") ///
				title("Forest plot for interaction with `trtvar'") ///
				saving(g`i', replace)
		
		}
		else {
		
		preserve
		drop _all
		set scheme cycle
		qui set obs 1
		forval i=3/`n' {
			if ln(`lbtau`i'') > -2.5 {
				gen lbtau`i'=ln(`lbtau`i'') 
			}
			else {
				gen lbtau`i'=-2.5
			}
			gen tau`i'=ln(`tau`i'')
			gen ubtau`i'=ln(`ubtau`i'')
		}
		
		if `n'<7 {
			local n1 = `n'+1
			forval i=`n1'/7 {
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
		
		gen ftau3=9.5
		gen ftau4=9
		gen ftau5=8.5
		gen ftau6=8
		gen ftau7=7.5
			
		if `n' < 5{
			gen low = 8
		}
		else {
			gen low = 7
		}
			
		*forestplot graphic generation
		twoway (rcap lbtau3 ubtau3 ftau3 if ubtau3 <= 2.2, hor blcolor(dknavy) legend(off)) ///
			(rcap lbtau3 cut ftau3 if ubtau3 > 2.2, hor blcolor(dknavy) legend(off)) ///
			(rscatter cut cut ftau3 if ubtau3 > 2.2, hor mcolor(white) msymbol(smsquare) msize(vlarge) legend(off)) ///
			(rscatter cut2 cut2 ftau3 if lbtau3<= -2.5, hor mcolor(white) msymbol(smsquare) msize(vlarge) legend(off)) ///
			(rscatter tau3 tau3 ftau3 if tau3 <= 2.2 & tau3 >-2.5, hor mcolor(red) msymbol(smcircle) msize(vlarge) legend(off)) ///
			(rcap lbtau4 ubtau4 ftau4 if ubtau4 <= 2.2 & tau4 > -100000, hor blcolor(dknavy) legend(off)) ///
			(rcap lbtau4 cut ftau4 if ubtau4 > 2.2 & tau4 > -100000, hor blcolor(dknavy) legend(off)) ///
			(rscatter cut cut ftau4 if ubtau4 > 2.2 & tau4 > -100000, hor mcolor(white) msymbol(smsquare) msize(vlarge) legend(off)) ///
			(rscatter cut2 cut2 ftau4 if lbtau4<= -2.5 & tau4 > -100000, hor mcolor(white) msymbol(smsquare) msize(vlarge) legend(off)) ///
			(rscatter tau4 tau4 ftau4 if tau4 <= 2.2 & tau4 >-2.5 & tau4 > -100000, hor mcolor(red) msymbol(smcircle) msize(vlarge) legend(off)) ///
			(rcap lbtau5 ubtau5 ftau5 if ubtau5 <= 2.2 & tau5 > -100000, hor blcolor(dknavy) legend(off)) ///
			(rcap lbtau5 cut ftau5 if ubtau5 > 2.2 & tau5 > -100000, hor blcolor(dknavy) legend(off)) ///
			(rscatter cut cut ftau5 if ubtau5 > 2.2 & tau5 > -100000, hor mcolor(white) msymbol(smsquare) msize(vlarge) legend(off)) ///
			(rscatter cut2 cut2 ftau5 if lbtau5<= -2.5 & tau5 > -100000, hor mcolor(white) msymbol(smsquare) msize(vlarge) legend(off)) ///
			(rscatter tau5 tau5 ftau5 if tau5 <= 2.2 & tau5 >-2.5 & tau5 > -100000, hor mcolor(red) msymbol(smcircle) msize(vlarge) legend(off)) ///
			(rcap lbtau6 ubtau6 ftau6 if ubtau6 <= 2.2 & tau6 > -100000, hor blcolor(dknavy) legend(off)) ///
			(rcap lbtau6 cut ftau6 if ubtau6 > 2.2 & tau6 > -100000, hor blcolor(dknavy) legend(off)) ///
			(rscatter cut cut ftau6 if ubtau6 > 2.2 & tau6 > -100000, hor mcolor(white) msymbol(smsquare) msize(vlarge) legend(off)) ///
			(rscatter cut2 cut2 ftau6 if lbtau6<= -2.5 & tau6 > -100000, hor mcolor(white) msymbol(smsquare) msize(vlarge) legend(off)) ///
			(rscatter tau6 tau6 ftau6 if tau6 <= 2.2 & tau6 >-2.5 & tau6 > -100000, hor mcolor(red) msymbol(smcircle) msize(vlarge) legend(off)) ///
			(rcap lbtau7 ubtau7 ftau7 if ubtau7 <= 2.2 & tau7 > -100000, hor blcolor(dknavy) legend(off)) ///
			(rcap lbtau7 cut ftau7 if ubtau7 > 2.2 & tau7 > -100000, hor blcolor(dknavy) legend(off)) ///
			(rscatter cut cut ftau7 if ubtau7 > 2.2 & tau7 > -100000, hor mcolor(white) msymbol(smsquare) msize(vlarge) legend(off)) ///
			(rscatter cut2 cut2 ftau7 if lbtau7<= -2.5 & tau7 > -100000, hor mcolor(white) msymbol(smsquare) msize(vlarge) legend(off)) ///
			(rscatter tau7 tau7 ftau7 if tau7 <= 2.2 & tau7 >-2.5 & tau7 > -100000, hor mcolor(red) msymbol(smcircle) msize(vlarge) legend(off)) ///
		 	(rcap poverallmin poverallmax foverall if poverallmax <= 2.2, hor blcolor(dknavy) legend(off)) ///
		 	(rcap poverallmin cut foverall if poverallmax > 2.2, hor blcolor(dknavy) legend(off)) ///
		 	(rscatter cut cut foverall if poverallmax > 2.2, hor mcolor(white) msymbol(smsquare) msize(vlarge) legend(off)) ///
		 	(rscatter cut2 cut2 foverall if poverallmin<=-2.5, hor mcolor(white) msymbol(smsquare) msize(vlarge) legend(off)) ///
		 	(rscatter poverall50 poverall50 foverall if poverall50 <= 2.2 & poverall50 > -2.5, hor mcolor(red) msymbol(smdiamond) msize(vlarge) legend(off)) ///
		 	(rspike high low f1, blcolor(dknavy) legend(off)), ///
				text(9.5 3 "`factorvar3'", place(n)) ///
				text(9 3 "`factorvar4'", place(n)) ///
				text(8.5 3 "`factorvar5'", place(n)) ///
				text(8 3 "`factorvar6'", place(n)) ///
				text(7.5 3 "`factorvar7'", place(n)) ///
				text(10 3 "overall lnOR", place(n)) ///
				ylabel(none) ///
				xlabel(-2.5 -1.5 -0.5 0 0.5 1.5 2.5 3.5) ///
				ytitle(" ") ///
				xtitle("lnOR / lnROR") ///
				title("Forest plot for interaction with `trtvar'") ///
				saving(g`i', replace)
		}
		
		restore
	}
		
}
	
end


