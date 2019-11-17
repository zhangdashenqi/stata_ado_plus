*! Version 1.2.1  28jan2001  STB-60 sg161
program define wherext, rclass sort
	version 7

	if "`e(cmd)'" == "" {
		error 301
	}

	syntax varlist(min=2 max=2 numeric) [, eq(str) Bootstrap       /*
	 */ Rep(int 10000) Kdensity(str) Kdensity2 Level(int $S_level) /*
	 */ Seed(str) SAVING(passthru) ]

	* ==============================================================
	* extract information from saved results
	* ==============================================================

	tempname b bv bw dbv dbw est qa qb s touse v2 V VARvw

	mat `b' = e(b)
	mat `V' = e(V)
	gen byte `touse' = e(sample)

	* check that v and w occur in last model

	local v : word 1 of `varlist'
	local w : word 2 of `varlist'

	if "`eq'" != "" {
		local eq `"`eq':"'
	}
	else {
		local ceq : coleq `b'
		local ceq : word 1 of `ceq'
		if "`ceq'" != "_" {
			local eq "`ceq':"
		}
	}

	capt matrix `bv' = `b'[1,"`eq'`v'"]
	if _rc {
		di as err "`eq'`v' not in last estimated model"
		exit 198
	}
	capt matrix `bw' = `b'[1,"`eq'`w'"]
	if _rc {
		di as err "`eq'`w' not in last estimated model"
		exit 198
	}

	* ==============================================================
	* check that w is a quadratic function of v
	* ==============================================================

	capt bys `v' (`w') : assert `w' == `w'[1]
	if _rc {
		di as err "`w' is not a function of `v'"
		di as err "(i.e., `w' is not constant within `v')"
		exit 198
	}
	estimate hold `est'
	gen double `v2' = `v'*`v'
	qui regress `w' `v' `v2' if `touse'
	if (_b[`v2'] == .) | (_b[`v2'] == .) | (`e(r2)' < .999) {
		di as err "`w' is not quadratic in `v'"
		exit 198
	}
	scalar `qa' = _b[`v2']
	scalar `qb' = _b[`v']
	est unhold `est'

	scalar `bv' = `bv'[1,1]
	scalar `bw' = `bw'[1,1]

	mat `VARvw' = ( `V'["`eq'`v'","`eq'`v'"] , `V'["`eq'`v'","`eq'`w'"] \ /*
	           */   `V'["`eq'`w'","`eq'`v'"] , `V'["`eq'`w'","`eq'`w'"] )

	* ==============================================================
	*  compute extreme in bv*v + bw*w in v and its s.e. via the
	*  delta method
	* ==============================================================

	if `qa'*`bw' > 0 {
		return local extreme minimum
	}
	else 	return local extreme maximum

	return scalar argext = - (`bv' + `bw'*`qb') / (2*`bw'*`qa')

	scalar `dbv' = -1 / (2*`qa'*`bw')
	scalar `dbw' = `bv' / (2*`qa'*`bw'^2)

	* variance of argext, delta method
	return scalar Vargext = `dbv'^2 * `VARvw'[1,1] + /*
	 */ 2*`dbv'*`dbw' * `VARvw'[1,2] + `dbw'^2 * `VARvw'[2,2]
	* width of CI
	scalar `s' = invnorm(.5 + `level'/200) * sqrt(return(Vargext))

	* ==============================================================
	* output
	* ==============================================================

	qui summ `v' if `touse'
	return scalar min = r(min)
	return scalar max = r(max)

	local abv = abbrev("`v'",8)
	local abw = abbrev("`w'",8)
	#del ;
	di _n as txt "range of {res:`v'} "
	 _col(48)  "= [" as res return(min) "{txt:,}" return(max) "{txt:]}" ;
	di as txt "{res:`abv'}+{res:`abw'} has {res:`return(extreme)'}"
	 " in argext{col 48}=" as res %9.0g return(argext) ;
	di as txt "Std Error of argext (delta method)"
	 "{col 48}=" as res %9.0g sqrt(return(Vargext)) ;
	di as txt "`level'% confidence interval for argext{col 48}= (" as res
	 %9.0g =return(argext)-`s' "{txt:,}"
	 %9.0g =return(argext)+`s' "{txt:)}" ;
	#del cr

	* ==============================================================
	*   "Parametric bootstrap" for argext.
	*
	*   We simulate from a multivariate normal distribution
	*   with mean (bv,bw) and variance VARvw.
	* ==============================================================

	if "`bootstrap'" != "" {
		if `"`seed'"' != "" {
			* error message by -set-
			set seed `seed'
			return scalar seed = `seed'
		}

		preserve
		tempname R

		qui drop _all
		qui set obs `rep'

		* draw from bivariate normal distribution N( (bv,bw), VARvw )
		mat `R' = cholesky(`VARvw')
		gen u1 = invnorm(uniform())
		gen u2 = invnorm(uniform())
		gen rbv = `bv' + `R'[1,1]*u1 + `R'[1,2]*u2
		gen rbw = `bw' + `R'[2,1]*u1 + `R'[2,2]*u2

		gen argext =  - (rbv + rbw * `qb') / (2 * rbw * `qa')

		if "`kdensity'`kdensity2'" != "" {
			tempname kx kdens ndens nx sd

			kdensity argext, gen(`kx' `kdens') nograph `kdensity'

			scalar `sd' = sqrt(return(Vargext))
			qui gen `nx' = (`kx' - return(argext)) / `sd'
			qui gen `ndens' = normd(`nx',`sd')

			label var `kdens' "bootstrap density"
			label var `ndens' "normal density"
			graph `kdens' `ndens' `kx', c(ll) s(..) bor `saving'
		}

		local r = return(argext)
		bstat argext, stat(`r') level(`level') /*
		 */ title("Parametric bootstrap statistics (assuming bivariate normality)")
		if "`seed'" != "" {
			di as txt "{ralign 77: seed used `seed'}"
		}
		return add
	}
end
exit
