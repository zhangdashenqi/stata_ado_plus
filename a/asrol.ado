*! Attaullah Shah 2.1.0 31Aug2015
*! Attaullah Shah 2.0.0 June 2015
*Email: attaullah.shah@imsciences.edu.pk
cap prog drop asrol
prog def asrol, sortpreserve
	version 11
	
	syntax varname(ts) [in] [if], Generate(str) Stat(str) [ Window(int 2) Nomiss MINimum(real 0)] 
	
	marksample touse
	qui tsset 
	local id `r(panelvar)'
	local timevar `r(timevar)'
	loc min `r(tmin)'
	loc N `r(tmax)'
	loc nmiss : word count `nomiss'
	loc cid  "`id'"
	if "`cid'"==""{
	loc idexist " "
	}
	if "`cid'"!=""{
	loc idexist "bys `id': "
	}
	if `window' < 2 {
       di as err "Rolling window length must be at least 2"
	exit 198
	}
	
	if `window' >= `N' {
       di as err "Rolling window length should be less than total number of periods"
	exit 198
	}
		
	local nstats : word count `stat'
	if `nstats' > 1 { 
		di as error "Only one statistic allowed"
	exit 0 
	} 	
	local gen "`generate'" 
	confirm new variable `gen'
	
	

	local upper = `window' - 1
	tsrevar L(1/`upper').`varlist'
	local varlags `r(varlist)'

	egen `gen' = row`stat'(`varlist' `varlags') if `touse'
	
	if `minimum' > 0 {	
		tempvar NONM
		egen `NONM' = rownonmiss(`varlist' `varlags')
		qui replace `gen' = . if `NONM' < `minimum'
	}
	
	
	if `nmiss'==0{
	qui `idexist' replace `gen'=. if _n<`window'
	}
	dis as txt "Desired statistics successfully generated"
	
end






