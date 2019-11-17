*! Author Attaullah Shah
*! August 8, 2015, Version 1.0.0
*! Version 1.1.0
*! September 15, 2015

cap prog drop ascol
prog define ascol
version 10
syntax varlist, [ ///
	   Returns ///
	   Prices ///
	   TOWeek ///
	   TOMonth ///
	   TOQuarter ///
	   TOYear]
*set trace on
	qui tsset
	loc panelvar `r(panelvar)'
	loc timevar `r(timevar)'
	loc returnsc : word count  `returns'
	loc pricesc : word count  `prices'
	loc optionweek : word count  `toweek'
	loc optionmonth : word count  `tomonth'
	loc optionquarter : word count  `toquarter'
	loc optionyear : word count  `toyear'
	
	
	
	if `returnsc' ==0 & `pricesc'==0{
		dis as error "Either prices or returns option has to be specified"
		dis as txt " For example {opt ascol ri, returns tomonth}"
		exit
	}
	if `returnsc' > 0 & `pricesc'> 0{
		dis as error "You have specified both prices and returns option"
		dis as txt " Only one option is allowed at a time"
		exit
	}
	
	if `optionweek'==0 & `optionmonth'==0 & `optionquarter'==0 & `optionyear'==0{
		dis as error " toweek, tomonth, toquarter, or toyear option not specified"
		dis as txt "One of these options have to be specified"
		dis as txt " For example, ascol ri, toweek returns"
		exit
	}
	if `optionweek'>0 & `optionmonth'>0 {
		dis as error "Weekly and monthly frequency cannot be specified at the same time"
		exit
	}
	
		if `optionweek'>0 & `optionquarter'>0 {
		dis as error "Weekly and quarterly frequency cannot be specified at the same time"
		exit
	}
	if `optionweek'>0 & `optionyear'>0 {
		dis as error "Weekly and year frequency cannot be specified at the same time"
		exit
	}
	if `optionquarter'>0 & `optionmonth'>0 {
		dis as error "Quarterly and monthly frequency cannot be specified at the same time"
		exit
	}
	if `optionyear'>0 & `optionmonth'>0 {
		dis as error "Yearly and monthly frequency cannot be specified at the same time"
		exit
	}

		if `optionyear'>0 & `optionquarter'>0 {
		dis as error "Weekly and monthly frequency cannot be specified at the same time"
		exit
	}

	loc period_id = ///
	cond(`optionweek'>0,"week", ///
	cond(`optionmonth'>0, "month", ///
	cond(`optionquarter'>0, "quarter", "year")))
	
	cap confirm variable `period_id'_id
	if _rc!=0{
		loc period_id `period_id'_identifier
	}
	
	if `returnsc' > 0 {
		if `optionweek' > 0 {
			gen `period_id' =yw(year(`timevar'), week(`timevar'))
			format %tw `period_id'
			collapse (sum) `varlist' , by (`panelvar' `period_id')
			tsset `panelvar' `period_id', weekly
		} //closes week

		
		if `optionmonth' > 0 {
			gen `period_id' =ym(year(`timevar'), month(`timevar'))
			format %tmMonth_CCYY `period_id'
			collapse (sum) `varlist' , by (`panelvar' `period_id')
			tsset `panelvar' `period_id', monthly
		} //closes month

		if `optionquarter' > 0 {
			gen `period_id' =yq(year(`timevar'), quarter(`timevar'))
			collapse (sum) `varlist' , by (`panelvar' `period_id')
			format %tq `period_id'
			tsset `panelvar' `period_id', quarterly
		} //closes quaerwe

		if `optionyear' > 0 {
			gen `period_id' =(year(`panelvar' `period_id')
			collapse (sum) `varlist' , by (`year')
			tsset `panelvar' `period_id', yearly
		} //closes quarter
	} 

	if `pricesc' > 0 {
			if `optionweek' > 0 {
			gen `period_id' =yw(year(`timevar'), week(`timevar'))
			bys `panelvar' `period_id' (`timevar') : keep if _n==_N
			format %tw week_id
			tsset `panelvar' `period_id', weekly

		} //closes week
		
		if `optionmonth' > 0 {
			gen `period_id' =ym(year(`timevar'), month(`timevar'))
			format %tmMonth_CCYY `period_id'
			bys `panelvar' `period_id' : keep if _n==_N
			tsset `panelvar' `period_id', monthly	
		} //closes month

		if `optionquarter' > 0 {
			gen `period_id' =yq(year(`timevar'), quarter(`timevar'))
			format %tq `period_id'
			bys `panelvar' `period_id' : keep if _n==_N
			tsset `panelvar' `period_id', quarterly

		} //closes quarter

		if `optionyear' > 0 {
			gen `period_id' =(year(`panelvar' `period_id')
			bys `panelvar' `period_id' : keep if _n==_N
			tsset `panelvar' `period_id', yearly

		} //closes quarter

	}
	
	end
