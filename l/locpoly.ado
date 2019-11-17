*! version 2.1.3  20nov2006               (SJ3-4: st0053; SJ6-4: st0053_3)
*! with Stata plugin
program locpoly, rclass sortpreserve
	version 8

	syntax varlist(min=2 max=2 numeric)	///
		[if] [in] [,			///
		noGraph				///
		noScatter			///
		GENerate(string)		///
		AT(varname)			///
		N(integer 50)			///
		Degree(integer 0)		///
		Width(real 0.0)			///
		BIweight			///
		COSine				///
		EPanechnikov			///
		GAUssian			///	
		PARzen				///
		RECtangle			///
		TRIangle			///
		ADOonly				///
		*				/// graph opts
	]

	_get_gropts , graphopts(`options') gettwoway	///
		getallowed(rlopts plot)
	local options `"`s(graphopts)'"'
	local rlopts `"`s(rlopts)'"'
	local twopts `"`s(twowayopts)'"'
	local plot `"`s(plot)'"'
	_check4gropts rlopts, opt(`rlopts')

	local kernel `biweight' `cosine' `epanechnikov' `gaussian'  ///
		     `parzen' `rectangle' `triangle' 
	local k : word count `kernel'
	if `k' > 1 {
		di as err "only one kernel may be specified"
		exit 198
	}
	if `k' == 0 {
		local kernel epanechnikov
	}

	tokenize `generate'	
	local k : word count `generate'
	if `k' { 
		if `k' == 1 {
			if "`at'" == "" {
di as err "at() must be specified for generate() to work with one variable"
				error 198
			}
			confirm new var `1'
			local yname `"`1'"'
			local xname `"`at'"'
			local nsave 1
		}
		else {
			if `k' != 2 {
di as err "generate(): two new variables required"
				error 198
			}
			confirm new var `1'	
			confirm new var `2'
			local xname `"`1'"'
			local yname `"`2'"'
			local nsave 2
		}
	}

	marksample touse

	tokenize `varlist'
	local y `1'
	local x `2'

	local bw = `width'
	if `bw' <= 0.0 {
		qui sum `x' if `touse', detail
		local bw = min( r(sd), (r(p75)-r(p25))/1.349 )
		if `bw' <= 0.0 {
			local bw = r(sd)
		}
		local bw = 0.9*`bw'/(r(N)^.20)
	}

	tempvar xgrid yhat
	qui gen double `xgrid' = .
	qui gen double `yhat' = .	

	if `"`at'"' != `""' {
		qui count if `at' < .
		local n = r(N)
		qui replace `xgrid' = `at'
		tempvar obssrt
		gen `obssrt' = _n	
		sort `xgrid' `obssrt'	
	}

	else {
		if `n' <= 1 {
			local n = 50
		}
		if `n' > _N {
			local n = _N
			noi di in gr "(n() set to " `n' ")"
		}
		qui summ `x' if `touse'
		tempname delta
		scalar `delta' = (r(max)-r(min))/(`n'-1)
		qui replace `xgrid' = r(min)+(_n-1)*`delta' in 1/`n'
	}
	
	if "`adoonly'" == "" {
		capture plugin call _lpwork `y' `x' `xgrid' `yhat' ///
			if `touse',  `n' `bw' `degree' `kernel'
		if _rc==199 {
			di as err "plugin not loaded or not available:  " _c
			di as err "use the " as inp "adoonly " as err "option"
			exit 199
		}
	}
	else {
		Lpwork `y' `x' if `touse', xgrid(`xgrid') yhat(`yhat') ///
			n(`n') h(`bw') p(`degree') k(`kernel')		
	}

	qui count if `yhat' < . 
	local ngrid = r(N)
	
	/* Graph (if required) */
	if "`graph'" == "" { 
		local title title("Local polynomial smooth")
		local subttl1 subtitle(`"Degree: `degree'"')
		local yttl : var label `y'
		if `"`yttl'"' == "" {
			local yttl `y'
		}
		local xttl : var label `x'
		if `"`xttl'"' == "" {
			local xttl `x'
		}
		label var `yhat' "locpoly smooth: `yttl'"
		local titles				///
			`title'				///
			`subttl1'			///
			// blank

		if "`scatter'" == "" {
			local scat (scatter `y' `x' if `touse')
		}
		graph twoway				///
		`scat'					///
		(line `yhat' `xgrid',			///
			sort				///
			pstyle(p1)			///
			`titles'			///
			ytitle(`"`yttl'"')		///	
			xtitle(`"`xttl'"') 		///
			`rlopts'			///
			`twopts'			///
			`options'			///
		)					///
		|| `plot'				///
		// blank
	}
	
	ret local kernel `"`kernel'"'
	ret scalar width = `bw'
	ret scalar ngrid = `ngrid'
	ret scalar degree = `degree'
		
	if `"`nsave'"' != "" {
		label var `yhat' `"locpoly smooth: `y'"'
		rename `yhat' `yname'
		if `nsave' == 2 {
			rename `xgrid' `xname'
			label var `xname' `"locpoly smoothing grid"'
		}
	}
end

capture program _lpwork, plugin using("locpoly.plugin")

program Lpwork
	syntax varlist(min=2 max=2 numeric)	///
		[if],  				///
		xgrid(varname) 			///
		yhat(varname)			///
		n(integer)			///
		[ p(integer 0)			///
		h(real 0.0)			///
		k(string) ]

	tokenize `varlist'	
	local y `1'
	local x `2'

	marksample touse
	
	tempvar arg karg
	forvalues j = 1/`p' {
		tempvar x`j'
		qui gen double `x`j'' = .
		local xs `xs' `x`j''
	}
	qui gen double `arg' = .
	qui gen double `karg' = .
	forvalues i = 1/`n' {
		qui replace `arg' = (`x' - `xgrid'[`i'])/`h' if `touse'
		GetK `arg' `karg' `k' `touse'
		forvalues j = 1/`p' {
			qui replace `x`j'' = (`h'*`arg')^`j' if `touse'	
		}	
		capture regress `y' `xs' [iw = `karg'] if `touse'
		if !_rc {
			if _b[_cons] < . {
				qui replace `yhat' = _b[_cons] in `i'
			}
		}
	}		
end

program GetK
	args arg karg kern touse

	qui replace `karg' = .
	if "`kern'" == "biweight" {
		local con1 = .9375
		qui replace `karg' = `con1'*(1-(`arg')^2)^2 /* 
			*/ if `touse' & abs(round(`arg',1e-8))<1 
	}
	else if "`kern'" == "cosine" {
		qui replace `karg' = (1 + cos(2*_pi*`arg')) /*
			*/ if `touse' & abs(round(`arg',1e-8))<0.5	
	}
	else if "`kern'" == "triangle" {
		qui replace `karg' = (1 - abs(`arg')) /*
			*/ if `touse' & abs(round(`arg',1e-8))<1
	}
	else if "`kern'" == "parzen" {
		local con1 = 4/3
		local con2 = 2*`con1'
		qui replace `karg' = `con1'-8*`arg'^2 + 8*abs(`arg')^3 /*
			*/ if abs(round(`arg',1e-8))<=0.5 & `touse'
		qui replace `karg' = `con2'*(1-abs(`arg'))^3 /*
			*/ if abs(round(`arg',1e-8))>.5 & /*
			*/ abs(round(`arg',1e-8))<1 & `touse'	
	}
	else if "`kern'" == "gaussian" {
		local con1 = sqrt(2*_pi)
		qui replace `karg' = exp(-0.5*((`arg')^2))/`con1' if `touse'
	}
	else if "`kern'" == "rectangle" {
		qui replace `karg' = 0.5 if abs(round(`arg',1e-8))<1 & `touse'
	}
	else { 				// epanechnikov
		local con1 = 3/(4*sqrt(5))
		local con2 = sqrt(5)
		qui replace `karg' = `con1'*(1-((`arg')^2/5)) /*
			*/ if abs(round(`arg',1e-8)) <= `con2' & `touse'	
	}
end

exit
-------------------------end locpoly.ado-------------------------------------
