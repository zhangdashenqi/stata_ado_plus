*! version 1.0.5 17mar2006
*  Written by: Jeff Pitblado
program sim_arma
	// no version statement on purpose
	if _caller() < 8 {
		sim_arma_7 `0'
		exit
	}
	SIM_ARMA `0'
end

program SIM_ARMA, rclass
	version 8.2
	syntax newvarname [, 			///
		display				///
		et(name)			///
		Nobs(integer 0)			///
		spin(integer 0)			///
		cov				///
		time(name)			///
		ARcoef(string)			/// syntax 1 specifics
		MAcoef(string)			///
		sigma(real 1.0)			///
		arima(string)			/// syntax 2 specifics
		arma(passthru)			///
		*				/// tsset options
	]

	if `"`arma'"' != "" {
		local 0 , `arma'
		syntax [, notanoption ]
		exit 198
	}

	if `nobs' < 1 {
		if _N == 0 {
			di as err "nobs() must be greater than 0"
			exit 198
		}
		else local nobs = _N
	}

	// In either of the following mutually exclusive blocks:
	// 	arma  = a row vector containing the ARMA coefficients
	// 	sigma = a scalar containing the disturbance SE

	if `"`arima'"' != "" {

		if `"`arcoef'`macoef'"' != "" {
			di as err ///
"option arima() may not be combined with options arcoef() and macoef()"
			exit 198
		}
		tempname x arma sigma_cons
		confirm matrix `arima'
		capture mat `arma' = `arima'[1,"ARMA:"]
		if _rc {
			// no AR or MA coefficients
			local arma
		}
		scalar `sigma_cons' = `arima'[1,colnumb(`arima',"sigma:_cons")]
		if missing(`sigma_cons') {
			di as err "missing value for sigma:_cons in `arima'"
			exit 198
		}
		else if `sigma_cons' >= 0 {
			local sigma `sigma_cons'
		}
		else {
			di as errr "negative value for sigma:_cons in `arima'"
			exit 198
		}
	}
	else {
		tempname arma
		local p 0
		local q 0
		if `"`arcoef'"' != "" {
			numlist "`arcoef'"
			local arcoef `"`r(numlist)'"'
			local carcoef : subinstr local arcoef " " ",", all
			mat `arma' = `carcoef'
			local p = colsof(`arma')
			forval i = 1/`p' {
				local stripe `stripe' ARMA:l`i'.ar
			}
		}
		if `"`macoef'"' != "" {
			numlist "`macoef'"
			local macoef `"`r(numlist)'"'
			local cmacoef : subinstr local macoef " " ",", all
			mat `arma' = nullmat(`arma'),`cmacoef'
			local q = colsof(`arma')-`p'
			forval i = 1/`q' {
				local stripe `stripe' ARMA:l`i'.ma
			}
		}
		if `"`stripe'"' != "" {
			mat colnames `arma' = `stripe'
		}
		else	local arma
		if `sigma' < 0 {
			di as err "option sigma() requires non-negative values"
			exit 198
		}
	}
	if `"`display'"' != "" {
		Display "`arma'" `sigma'
	}

	tempname t
	if `"`cov'"' != "" & `spin' > 0 {
		di as err "options spin() and cov may not be combined"
		exit 198
	}
	else if `"`cov'"' != "" | `spin' <= 0 {
		if `nobs' < _N {
			di as error "nobs() smaller than current data set"
			exit 198
		}

		// setup nobs for simulation, and tsset data

		if `nobs' == _N {
			gen `t' = _n
		}
		else {
			local N = _N
			quietly set obs `nobs'
			gen `t' = _n
			quietly replace `t' = -`t' in `=`N'+1'/l
			sort `t'
			quietly replace `t' = _n
		}
		quietly tsset `t'

		// Simulate ARMA data using starting values from
		// autocovariance function

		ARMA_AutoCov `varlist' "`arma'" `sigma' "`et'"
		return add
	}
	else {	// spin > 0
		if `"`arma'"' != "" {
			if `spin' <= colsof(`arma') {
				di as err ///
"spin() must be larger that the number of ARMA coefficients"
				exit 198
			}
		}

		// setup nobs for simulation, and tsset data

		local N = _N
		local totalobs = `nobs'+`spin'
		quietly set obs `totalobs'
		gen `t' = _n
		quietly replace `t' = -`t' in `=`N'+1'/l
		sort `t'
		quietly replace `t' = _n
		quietly tsset `t'

		// simulate ARMA data using spinning
		ARMA_Spin `varlist' "`arma'" `sigma' "`et'"
		// drop the spin observations
		quietly keep in `=_N-`nobs'+1'/l
	}

	// generate the time variable, and tsset it
	if `"`time'"' == "" {
		capture unab time : _t
		if !c(rc) & "`time'" == "_t" {
			quietly replace _t = _n
		}
		else {
			gen _t = _n
			local time _t
		}
	}
	else {
		capture unab mytime : `time'
		if !c(rc) & "`mytime'" == "`time'" {
			quietly replace `time' = _n
		}
		else {
			gen `time' = _n
		}
	}
	quietly tsset `time', `options'
	if `"`arima'"' != "" {
		tempname x
		matrix `x' = `arima'
		// return a copy of arima() matrix
		return matrix arima `x'
	}
	if `"`arma'"' != "" {
		return matrix arma `arma'
	}
	return local time `time'
	return scalar spin = `spin'
	return scalar nobs = `nobs'
	return scalar sigma = `sigma'
end

program ARMA_Spin
	args yt arma sigma et

	tempname allcoef
	mat `allcoef' = 1
	mat colnames `allcoef' = ARMA:ma
	mat `allcoef' = `allcoef', nullmat(`arma')
	DropVar ar ma
	qui gen double ar = . in 1
	gen double ma = `sigma'*invnorm(uniform())

	if `"`arma'"' != "" {
		local m = colsof(`arma')
	}
	else	local m 0
	_byobs {
		score ar = `allcoef' if _n>`m' , missval(0)
	}
	if !inlist(`"`et'"', "", "ma") {
		rename ma `et'
	}
	else	drop ma
	if !inlist(`"`yt'"', "", "ar") {
		rename ar `yt'
	}
end

program Get_AR_MA, rclass
	args arma

	if `"`arma'"' == "" {
		return local p 0
		return local q 0
		exit
	}
	local colnames : colnames `arma'
	local nc : word count `colnames'
	local p 0
	local q 0
	forval i = 1/`nc' {
		local name : word `i' of `colnames'
		local arlag : subinstr local name "ar" ""
		local malag : subinstr local name "ma" ""
		if `"`arlag'"' != `"`name'"' {
			local lag : subinstr local arlag "L" ""
			local cur `lag'
			capture confirm number `cur'
			if _rc == 0 {
				if ("`lag'" == ".")	local cur 1
				if (`p' < `cur')	local p = `cur'
			}
		}
		else if `"`malag'"' != `"`name'"' {
			local lag : subinstr local arlag "L" ""
			local lag : subinstr local malag "L" ""
			local cur `lag'
			capture confirm number `cur'
			if _rc == 0 {
				if ("`lag'" == ".")	local cur 1
				if (`q' < `cur')	local q = `cur'
			}
		}
	}
	return local p `p'
	return local q `q'
	if `p' > 0 {
		tempname ar sar
		mat `ar' = J(1,`p',0)
		local colnames
		forval i = 1/`p' {
			local colnames `colnames' l`i'.ar
			scalar `sar' = `arma'[1,colnumb(`arma',"l`i'.ar")]
			if `sar' < . {
				mat `ar'[1,`i'] = `sar'
			}
		}
		matrix colnames `ar' = `colnames'
		return matrix ar `ar'
	}
	if `q' > 0 {
		tempname ma sma
		mat `ma' = J(1,`q',0)
		local colnames
		forval i = 1/`q' {
			local colnames `colnames' l`i'.ma
			scalar `sma' = `arma'[1,colnumb(`arma',"l`i'.ma")]
			if `sma' < . {
				mat `ma'[1,`i'] = `sma'
			}
		}
		matrix colnames `ma' = `colnames'
		return matrix ma `ma'
	}
end

program Get_PSI, rclass
	args ar ma

	if `"`ar'"' == "" {
		local p 0
	}
	else local p = colsof(`ar')-1
	if `"`ma'"' == "" {
		local q 0
	}
	else local q = colsof(`ma')-1
	tempname psi
	local q1 = `q'+1
	mat `psi' = J(1,`q1',0.0)
	forval k = 1/`q1' {
		local m = min(`k'-1,`p')
		forval i = 1/`m' {
			mat `psi'[1,`k'] = ///
			    `psi'[1,`k']+`ar'[1,`i'+1]*`psi'[1,`k'-`i']
		}
		if `k' <= `q'+1 {
			mat `psi'[1,`k'] = `psi'[1,`k'] - `ma'[1,`k']
		}
	}
	return matrix psi `psi'
end

program ARMA_AutoCov, rclass
	args yt arma sigma et

	Get_AR_MA `arma'
	local p = r(p)
	local q = r(q)
	tempname ar ma psi
	if `"`r(ar)'"' != "" {
		mat `ar' = r(ar)
	}
	if `"`r(ma)'"' != "" {
		mat `ma' = r(ma)
	}
	local p1 = `p' + 1
	local q1 = `q' + 1

	mat `ar' = -1, nullmat(`ar')
	mat `ma' = -1, nullmat(`ma')
	Get_PSI "`ar'" "`ma'"
	if `"`r(psi)'"' != "" {
		mat `psi' = r(psi)
	}

	tempname A c
	local p1 = `p'+1
	matrix `A' = J(`p1',`p1',0.0)
	matrix `c' = J(1,`p1',0.0)
	forvalues i = 1/`p1' {
		// initial conditions
		forvalues j = `i'/`q1' {
			mat `c'[1,`i'] = ///
				`c'[1,`i'] - `ma'[1,`j']*`psi'[1,`j'-`i'+1]
		}
		mat `c'[1,`i'] = `c'[1,`i']*(`sigma')^2
		forvalues j = 1/`p1' {
			mat `A'[`i',abs(`j'-`i')+1] = ///
				`A'[`i',abs(`j'-`i')+1] - `ar'[1,`j']
		}
	}
	tempname gamma Ainv
	capture matrix `Ainv' = inv(`A')
	if _rc {
		di as err ///
		"AR coefficients produce a matrix that is not invertible"
		exit _rc
	}
	mat `gamma' = (`Ainv'*(`c')')'
	tempname gamk
	forval k = `p1'/`q' {
		scalar `gamk' = 0
		forval i = 1/`p' {
			scalar `gamk' = ///
				`gamk' + `ar'[1,`i'+1]*`gamma'[1,`k'-`i']
		}
		mat `gamma' = `gamma', `gamk'
	}
	local m = max(`p',`q')
	if `m' > 0 {
		tempname cov
		mat `cov' = J(`m',`m',0.0)
		forval i = 1/`m' {
			tempvar y`i'
			local tempys `tempys' `y`i''
			mat `cov'[`i',`i'] = `gamma'[1,1]
			local im1 = `i' - 1
			forval j = 1/`im1' {
				mat `cov'[`i',`j'] = `gamma'[1,abs(`i'-`j')+1]
				mat `cov'[`j',`i'] = `cov'[`i',`j']
			}
		}

		preserve
		capture drawnorm `tempys', n(1) cov(`cov') double clear
		if c(rc) {
			di as err ///
			"AR coefficients produced an invalid covariance matrix"
			exit c(rc)
		}
		tempname ymat
		mkmat `tempys' in 1, mat(`ymat')
		restore

		DropVar ar
		gen double ar = 0
		forval i = 1/`m' {
			quietly replace ar = `ymat'[1,`i'] in `i'
		}
	}
	else	quietly gen double ar = .

	DropVar ma
	gen double ma = `sigma'*invnorm(uniform())

	tempname allcoef
	mat `allcoef' = 1
	mat colnames `allcoef' = ARMA:ma
	mat `allcoef' = `allcoef', nullmat(`arma')
	_byobs {
		score ar = `allcoef' if _n>`m', missval(0)
	}
	if !inlist(`"`et'"', "", "ma") {
		rename ma `et'
	}
	else	drop ma
	if !inlist(`"`yt'"', "", "ar") {
		rename ar `yt'
	}
	return matrix A `A'
	return matrix c `c'
	return matrix psi `psi'
	return matrix gamma `gamma'
end

program Display
	args arma sigma

	di as txt _n "Process Coefficients:"
	if `"`arma'"' != "" {
		local m = colsof(`arma')
		local colnames : colfullnames `arma'
		forval i = 1/`m' {
			local cur : word `i' of `colnames'
			di as txt _col(4) `"`cur'"' _col(18) "=" ///
				  _col(20) as res %10.0g `arma'[1,`i']
		}
	}
	else {
		di as txt _col(4) "none"
	}

	di as txt _n "Disturbance Standard Error:"
	di as txt _col(4) "sigma" _col(18) "=" _col(20) as res %10.0g `sigma'
end

program DropVar
	foreach var of local 0 {
		capture unab v : `var'
		if !c(rc) & `"`v'"' == `"`var'"' {
			drop `v'
		}
	}
end

exit
