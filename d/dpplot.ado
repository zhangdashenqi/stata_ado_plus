*! 2.0.6 NJC 2 Dec 2007
* 2.0.5 NJC 20 April 2005
* 2.0.4 NJC 3 Oct 2004
* 2.0.3 NJC 22 July 2004
* 2.0.2 NJC 4 July 2004
* 2.0.1 NJC 22 June 2004
* 2.0.0 NJC 16 June 2004
* 1.0.0 NJC 19 June 2002
program dpplot, sort
	version 8 
	syntax varname [if] [in] [, GENerate(str) dist(str) param(numlist) ///
	a(real 0.5) plot(str asis) addplot(str asis) line(str asis) diff *]

	if "`generate'" != "" { 
		cap confirm new var `generate' 
		if _rc { 
			di as err "generate() must specify new variables"
			exit _rc 
		} 
		local nvars : word count `generate' 
		if `nvars' != 2 { 
			di as err "generate() must specify two variables"
			exit 198 
		} 
	} 	

	// observations to use 
	marksample touse 
	qui count if `touse' 
	if r(N) == 0 error 2000
	qui replace `touse' = - `touse' 
	sort `touse' `varlist' 

	// plotting positions (i - a ) / (n - 2a + 1) 
	// e.g. default a = 0.5: (i - 0.5) / n 
	//              a = 0: i / (n + 1) 
	tempvar P ft fo 
	qui gen `P' = (_n - `a') / (`r(N)' - 2 * `a' + 1) if `touse' 
	
	// TLAs (may be) allowed for distribution options 
	local l = max(3, length("`dist'"))

	// case-insensitive (allowing Gaussian, Weibull, etc.) 
	local dist = lower("`dist'") 
	
	// distribution defaults to normal (Gaussian) 
	if "`dist'" == "" local dist normal
	else if "`dist'" == substr("normal", 1, `l')  |  /// 
		"`dist'" == substr("gaussian", 1, `l') {  
		local dist normal 
	}	
	else if "`dist'" == substr("lognormal", 1, `l') { 
		local dist lognormal 
	} 
	else if "`dist'" == substr("gamma", 1, `l') { 
		local dist gamma 
	}
	else if "`dist'" == substr("exponential", 1, `l') { 
		local dist exponential 
	}
	else if "`dist'" == substr("weibull", 1, `l') { 
		local dist weibull 
	}
	// any other name falls through: will be treated as call to dp_`dist' 
		
	// dp_`dist' calculates theoretical and "observed" densities
	qui dp_`dist' `ft' `fo' `P' `varlist' `touse' `param' 

	_crcslbl `fo' `varlist' 

	// graph defaults 
	// caption and note set by called program 
	local ytitle "Probability density" 

	if "`diff'" != "" { 
		tempvar d
		gen `d' = `fo' - `ft' 
		label var `d' "difference"
	} 	

	// graph 
	twoway mspline `ft' `varlist' if `touse', bands(200) `line' ||     ///   
                scatter `fo' `d' `varlist' if `touse', ms(oh dh)           /// 
	        yti("`ytitle'") caption("`caption'", size(medsmall))       ///
		note("`note'", size(medsmall))                             ///
                yla(, ang(h)) legend(order(2 1 "`dist'") off) `options' || ///
               `plot'                                                   || ///
               `addplot'                                                      

	// messages about missing values will be visible 
	if "`generate'" != "" { 
		tokenize `generate' 
		gen `1' = `ft' if `touse' 
		label var `1' "`dist' density, `varlist' (direct)" 
		gen `2' = `fo' if `touse'
		label var `2' "`dist' density, `varlist' (indirect)" 
	} 	
end

program dp_glogistic 
	args ft fo P varlist touse xi alpha k garbage 
	
	if "`garbage'" != "" { 
		di as err "too many parameters specified"
		exit 198 
	}
	
	if ("`xi'" == "") | ("`alpha'" == "") | ("`k'" == "") { 
		di as err "need to specify three parameters" 
		exit 198 
	} 	
	
	tempvar y x  
	local v `varlist' 
	gen double `y' = cond(`k' == 0, (`v' - `xi') / `alpha', ///
	-(1 / `k') * ln(1 - `k' * (`v' - `xi') / `alpha')) if `touse' 
	gen double `ft' = (1 / `alpha') * exp(-(1 - `k') * `y') / ///
        (1 + exp(-`y'))^2 

	gen double `x' = cond(`k' == 0, ///
	`xi' - `alpha' * ln((1 - `P') / `P'), /// 
	`xi' + `alpha' * (1 - ((1 - `P') / `P')^`k') / `k')
	replace `y' = cond(`k' == 0, (`x' - `xi') / `alpha', ///
	-(1 / `k') * ln(1 - `k' * (`x' - `xi') / `alpha')) if `touse' 
	gen double `fo' = (1 / `alpha') * exp(-(1 - `k') * `y') / ///
        (1 + exp(-`y'))^2 

	local xi = trim("`: di %7.0g `xi''") 
	local alpha = trim("`: di %7.0g `alpha''") 
	local k = trim("`: di %7.0g `k''") 
	c_local caption "generalised logistic" 
	c_local note : di "xi `xi' alpha `alpha' k `k'" 
end

program dp_laplace 
	args ft fo P varlist touse theta sigma garbage 
	
	if "`garbage'" != "" { 
		di as err "too many parameters specified"
		exit 198 
	}
	
	if "`theta'" != "" & "`sigma'" == "" { 
		di as err "need to specify two parameters" 
		exit 198 
	} 	
		
	qui if "`theta'" == "" { 
		su `varlist' if `touse', d 
		local theta = r(p50)
		tempvar dev 
		gen `dev' = abs(`varlist' - r(p50)) if `touse' 
		su `dev', meanonly 
		local sigma = r(mean)
	} 
	
	gen double `ft' = ///
	(1 / (2 * `sigma')) * exp(-abs(`varlist' - `theta') / `sigma') if `touse' 
	gen double `fo' = `theta' + ///
	`sigma' * cond(`P' <= 0.5, log(2 * `P'), -log(2 * (1 - `P'))) if `touse' 
	replace `fo' = ///
	(1 / (2 * `sigma')) * exp(-abs(`fo' - `theta') / `sigma') if `touse' 

	local theta = trim("`: di %7.0g `theta''") 
	local sigma = trim("`: di %7.0g `sigma''") 
	c_local caption "Laplace" 
	c_local note : di "theta `theta' sigma `sigma'" 
end

program dp_alaplace 
	args ft fo P varlist touse theta sigma kappa garbage 
	
	if "`garbage'" != "" { 
		di as err "too many parameters specified"
		exit 198 
	}
	
	if ("`theta'" == "") | ("`sigma'" == "" | "`kappa'" == "") { 
		di as err "need to specify three parameters" 
		exit 198 
	} 	
	
	tempname K1 K2 
	scalar `K1' = `kappa' / (1 + (`kappa')^2) 
	scalar `K2' =  ((`kappa')^2) / (1 + (`kappa')^2)
	
	local v `varlist' 
	gen double `ft' = (`K1' / `sigma')  * exp((`v' - `theta') * ///
        cond(`v' >= `theta', -`kappa' / `sigma', 1 / (`sigma' * `kappa'))) ///
	if `touse' 
	gen double `fo' = `theta' + (`sigma' * `kappa' / sqrt(2)) * ///
		(ln(`P') - ln(`K2'))  if `touse' & `P' <= `K2'
	replace `fo' = `theta' - (`sigma' / (`kappa' * sqrt(2))) * ///
		ln((1 - `P') * (1 + (`kappa')^2))  if `touse' & `P' > `K2'
	replace `fo' = (`K1' / `sigma') * exp((`fo' - `theta') * ///
    	cond(`fo' >= `theta', -`kappa' / `sigma', 1 / (`sigma' * `kappa'))) ///

	local theta = trim("`: di %7.0g `theta''") 
	local sigma = trim("`: di %7.0g `sigma''") 
	local kappa = trim("`: di %7.0g `kappa''") 
	c_local caption "asymmetric Laplace" 
	c_local note : di "theta `theta' sigma `sigma' kappa `kappa'" 
end

program dp_normal 
	args ft fo P varlist touse mu sigma garbage 
	
	if "`garbage'" != "" { 
		di as err "too many parameters specified"
		exit 198 
	}
	
	if "`mu'" != "" & "`sigma'" == "" { 
		di as err "need to specify two parameters" 
		exit 198 
	} 	
		
	if "`mu'" == "" { 
		su `varlist' if `touse' 
		local mu = `r(mean)' 
		local sigma = `r(sd)'  
	} 
	
	gen double `ft' = (1 / `sigma') * normden((`varlist' - `mu') / `sigma') if `touse' 
	gen double `fo' = (1 / `sigma') * normden(invnorm(`P')) if `touse' 
	
	local mu = trim("`: di %7.0g `mu''") 
	local sigma = trim("`: di %7.0g `sigma''") 
	c_local caption "normal" 
	c_local note : di "mu `mu' sigma `sigma'" 
end

program dp_beta  
	args ft fo P varlist touse alpha beta garbage 
	
	if "`garbage'" != "" { 
		di as err "too many parameters specified"
		exit 198 
	}
	
	if "`alpha'" == "" { 
		di as err "need to specify parameters" 
		exit 198 
	} 
	
	if "`alpha'" != "" & "`beta'" == "" { 
		di as err "need to specify two parameters" 
		exit 198 
	} 	

	tempvar x 
	gen double `ft' = betaden(`alpha', `beta', `varlist') if `touse' 
	gen double `x' = invibeta(`alpha',`beta',`P') if `touse' 
	gen double `fo' = betaden(`alpha', `beta', `x')  

	local alpha = trim("`: di %7.0g `alpha''") 
	local beta = trim("`: di %7.0g `beta''") 
	c_local caption "beta" 
	c_local note : di "alpha `alpha' beta `beta'" 
end 

program dp_gamma  
	args ft fo P varlist touse alpha beta garbage 
	
	if "`garbage'" != "" { 
		di as err "too many parameters specified"
		exit 198 
	}
	
	if "`alpha'" == "" { 
		di as err "need to specify parameters" 
		exit 198 
	} 
	
	if "`alpha'" != "" & "`beta'" == "" { 
		di as err "need to specify two parameters" 
		exit 198 
	} 	

	tempvar x 
	gen double `ft' = gammaden(`alpha', `beta', 0, `varlist')  if `touse'
	gen double `x' = `beta' * invgammap(`alpha',`P') if `touse' 
	gen double `fo' = gammaden(`alpha', `beta', 0, `x')  if `touse'
	
	local alpha = trim("`: di %7.0g `alpha''") 
	local beta = trim("`: di %7.0g `beta''") 
	c_local caption "gamma" 
	c_local note : di "alpha `alpha' beta `beta'" 
end 

program dp_gumbel 
	args ft fo P varlist touse alpha mu garbage 
	
	if "`garbage'" != "" { 
		di as err "too many parameters specified"
		exit 198 
	}
	
	if "`alpha'" == "" { 
		di as err "need to specify parameters" 
		exit 198 
	} 
	
	if "`alpha'" != "" & "`mu'" == "" { 
		di as err "need to specify two parameters" 
		exit 198 
	} 	

	tempvar x 
	gen double `ft' = (1 / `alpha') * exp(-(`varlist' - `mu') / `alpha') * ///
		exp(-exp(-(`varlist' - `mu') / `alpha')) if `touse'
	gen double `x' = `mu' - `alpha' * log(-log(`P')) if `touse' 
	gen double `fo' = (1 / `alpha') * exp(-(`x' - `mu') / `alpha') * ///
		exp(-exp(-(`x' - `mu') / `alpha')) 

	local alpha = trim("`: di %7.0g `alpha''") 
	local mu = trim("`: di %7.0g `mu''") 
	c_local caption "Gumbel" 
	c_local note : di "alpha `alpha' mu `mu'" 
end 

program dp_kappa2 
	args ft fo P varlist touse alpha beta garbage 
	
	if "`garbage'" != "" { 
		di as err "too many parameters specified"
		exit 198 
	}
	
	if "`alpha'" == "" { 
		di as err "need to specify parameters" 
		exit 198 
	} 
	
	if "`alpha'" != "" & "`beta'" == "" { 
		di as err "need to specify two parameters" 
		exit 198 
	} 	

	tempvar x 
	gen double `ft' = (`alpha' / `beta') * ///
	(`alpha' + (`varlist' / `beta')^(`alpha'))^(-(`alpha' + 1) / `alpha')  if `touse'
	gen double `x' = `beta' * `P' * ///
	((`alpha')/(1 - `P'^`alpha'))^(1 / `alpha') if `touse' 
	gen double `fo' = (`alpha' / `beta') * ///
	(`alpha' + (`x' / `beta')^(`alpha'))^(-(`alpha' + 1) / `alpha')  

	local alpha = trim("`: di %7.0g `alpha''") 
	local beta = trim("`: di %7.0g `beta''") 
	c_local caption "kappa" 
	c_local note : di "alpha `alpha' beta `beta'" 
end 

program dp_dagum  
	args ft fo P varlist touse a b p garbage 
	
	if "`garbage'" != "" { 
		di as err "too many parameters specified"
		exit 198 
	}
	
	if "`a'" == "" { 
		di as err "need to specify parameters" 
		exit 198 
	} 
	
	if "`a'" != "" & ("`b'" == "" | "`p'" == "") { 
		di as err "need to specify three parameters" 
		exit 198 
	} 	

	tempvar x 
	gen double `ft' = 1 + (`b' / `varlist')^`a' if `touse' 
	replace `ft' = ///
	`a' * `p' * (`b' / `varlist')^`a' * (1  / `varlist') / `ft'^(`p' + 1)  
	gen double `x' = `b' * ((`P')^(-1 / `p') - 1)^(-1 / `a') if `touse' 
	gen double `fo' =  1 + (`b' / `x')^`a'
	replace `fo' = /// 
	`a' * `p' * (`b' / `x')^`a' * (1  / `x') / `fo'^(`p' + 1)  
	
	local a = trim("`: di %7.0g `a''") 
	local b = trim("`: di %7.0g `b''") 
	local p = trim("`: di %7.0g `p''") 
	c_local caption "Dagum" 
	c_local note : di "a `a' b `b' p `p'" 
end 

program dp_sm  
	args ft fo P varlist touse a b q garbage 
	
	if "`garbage'" != "" { 
		di as err "too many parameters specified"
		exit 198 
	}
	
	if "`a'" == "" { 
		di as err "need to specify parameters" 
		exit 198 
	} 
	
	if "`a'" != "" & ("`b'" == "" | "`q'" == "") { 
		di as err "need to specify three parameters" 
		exit 198 
	} 	

	tempvar x 
	gen double `ft' = 1 + (`varlist' / `b')^`a' if `touse' 
	replace `ft' = ///
	`a' * `q' / `b' * `ft'^(-(`q' + 1)) * (`varlist' / `b')^(`a' - 1)  
	gen double `x' = ///
	`b' * (( 1 / (1 - `P'))^(1 / `q') - 1)^(1 / `a') if `touse' 
	gen double `fo' =  1 + (`x' / `b')^`a'
	replace `fo' = ///
	`a' * `q' / `b' * `fo'^(-(`q' + 1)) * (`x' / `b')^(`a' - 1)  
	
	local a = trim("`: di %7.0g `a''") 
	local b = trim("`: di %7.0g `b''") 
	local q = trim("`: di %7.0g `q''") 
	c_local caption "Singh-Maddala" 
	c_local note : di "a `a' b `b' q `q'" 
end 

program dp_gb2 
	args ft fo P varlist touse a b p q garbage 
	
	if "`garbage'" != "" { 
		di as err "too many parameters specified"
		exit 198 
	}
	
	if "`a'" == "" { 
		di as err "need to specify parameters" 
		exit 198 
	} 
	
	if "`a'" != "" & ("`b'" == "" | "`p'" == "" | "`q'" == "") { 
		di as err "need to specify four parameters" 
		exit 198 
	} 	

	tempname factor 
	tempvar v1 v2 x 
	scalar `factor' = lngamma(`p') + lngamma(`q') - lngamma(`p' + `q') 
	gen double `v1' = (`a' * `p' - 1) * log(`varlist') if `touse' 
	gen double `v2' = (`a' * `p' * log(`b')) + `factor' +  ///
		((`p' + `q') * log(1 + (`varlist' / `b')^`a'))
        gen double `ft' = exp(log(`a') + `v1' - `v2') 
	gen double `x' = invibeta(`p',`q',`P') if `touse' 
	replace `x' = `b' * (`x' / (1 - `x'))^(1 / `a') 
	replace `v1' = (`a' * `p' - 1) * log(`x') 
	replace `v2' = (`a' * `p' * log(`b')) + `factor' +  ///
		((`p' + `q') * log(1 + (`x' / `b')^`a'))
	gen double `fo' = exp(log(`a') + `v1' - `v2') 

	local a = trim("`: di %7.0g `a''") 
	local b = trim("`: di %7.0g `b''") 
	local p = trim("`: di %7.0g `p''") 
	local q = trim("`: di %7.0g `q''") 
	c_local caption "Generalized Beta" 
	c_local note : di "a `a' b `b' p `p' q `q'" 
end 

program dp_lognormal 
	args ft fo P varlist touse mu sigma garbage 
	
	if "`garbage'" != "" { 
		di as err "too many parameters specified"
		exit 198 
	}
	
	if "`mu'" != "" & "`sigma'" == "" { 
		di as err "need to specify two parameters" 
		exit 198 
	} 	
	
	qui count if `varlist' <= 0 & `touse' 
	if r(N) > 0 error 411
	
	tempvar logvar logvar2 
	gen double `logvar' = log(`varlist') if `touse' 

	if "`mu'" == "" { 
		su `logvar' if `touse' 
		local mu = `r(mean)' 
		local sigma = `r(sd)'  
	} 	
	
	gen double `ft' = /// 
		(1 / (`varlist' * `sigma' * sqrt(2 * _pi))) * ///
		exp(-(`logvar' - `mu')^2 / (2 * `sigma'^2)) if `touse' 
	gen double `fo' = exp(invnorm(`P') * `sigma' + `mu') if `touse' 
	gen double `logvar2' = log(`fo')
	replace `fo' = (1 / (`fo' * `sigma' * sqrt(2 * _pi))) * ///
		exp(-(`logvar2' - `mu')^2 / (2 * `sigma'^2)) 

	local mu = trim("`: di %7.0g `mu''") 
	local sigma = trim("`: di %7.0g `sigma''") 
	c_local caption "lognormal"
	c_local note : di "mu `mu' sigma `sigma'"
end 

program dp_weibull   
	args ft fo P varlist touse beta gamma garbage 
	
	if "`garbage'" != "" { 
		di as err "too many parameters specified"
		exit 198 
	}
	
	if "`beta'" != "" & "`gamma'" == "" { 
		di as err "need to specify two parameters" 
		exit 198 
	} 	
	
	qui count if `varlist' < 0 & `touse' 
	if r(N) > 0 {
		di as err "negative values encountered" 
		exit 411
	} 	
	
	tempname eb 
	weibull `varlist' if `touse' 
	nlcom (b : exp(_b[_cons])) (c : exp([ln_p][_cons])), post  
	mat `eb' = e(b)
	local beta = `eb'[1,1] 
	local gamma = `eb'[1,2] 

	gen double `ft' = (`gamma' / `beta') * (`varlist' / `beta')^(`gamma' - 1) * ///
		exp(-(`varlist'/ `beta')^`gamma') if `touse' 
	gen double `fo' = `beta' * (-ln(1 - `P'))^(1 / `gamma') if `touse' 
	replace `fo' = (`gamma' / `beta') * (`fo' / `beta')^(`gamma' - 1) * ///
		exp(-(`fo'/ `beta')^`gamma')  

	local beta = trim("`: di %7.0g `beta''") 
	local gamma = trim("`: di %7.0g `gamma''") 
	c_local caption "Weibull"
	c_local note : di "beta `beta' gamma `gamma'"
end 

program dp_exponential
	args ft fo P varlist touse mu garbage 
	
	if "`garbage'" != "" { 
		di as err "too many parameters specified"
		exit 198 
	}
	
	count if `varlist' < 0 & `touse' 
	if r(N) > 0 { 
		di as err "negative values encountered"
		exit 411
	} 
	
	if "`mu'" == "" { 
		su `varlist' if `touse', meanonly 
		local mu = `r(mean)' 
	} 
	
	gen double `ft' = (1 / `mu') * exp(-(`varlist' / `mu')) if `touse' 
	gen double `fo' = (1 - `P') / `mu' if `touse'
	local mu = trim("`: di %7.0g `mu''")  
	c_local caption "exponential" 
	c_local note : di "mu `mu'" 
end 

