*!version 3.2.0  07may2003                      (SJ3-4: st0049, st0050, st0051)
program define qvf, eclass byable(onecall)
	version 8.0

	if replay() {
		if _by() {
			error 190 
		}
		if "`e(cmd)'" != "qvf" {
			capture program drop qvf
			error 301
		}
		DispEst `0'
		exit
	}
	if _by() {
		local by "by `_byvars'`_byrc0':"
	}
	eret clear
	capture noisily `by' Estimate `0'
	exit _rc
end

program define Estimate, eclass byable(recall) sort
	local cmd `"`0'"'
	syntax varlist(numeric) [if] [in] [fw iw pw] [, *]

	local opt "`options'"
	gettoken fvars   rest  : cmd,   parse(",") match(paren)
	gettoken varlist rest  : fvars, parse("(") match(paren)
	gettoken inst    trash : rest,  parse("(") match(paren)

	local origif  `"`if'"'
	local origin  `"`in'"'
	local origexp `"`exp'"'
	local origwt  `"`weight'"'

	local 0 "`varlist'"
	syntax varlist [if] [in] [fw iw pw]

	tokenize  "`varlist'"
	local dep `1'
	mac shift
	local ind `*'


	local 0 ", `opt'"

	#delimit ;
	syntax [, BOOT BSTRAP BREP(int 0) noCONstant EForm 
		LTOLerance(real 1e-6)
		Family(string) noHEAD ITERate(int 100) 
		LEvel(int $S_level)
		Link(string) LNOFFset(varname numeric) 
		noLOG MESSage(int 2) MTopel
		OFFset(varname numeric)
		OIM SCALEX 
		Robust BTRIM(real .02)
		CLuster(varname numeric)
		SAVing(str) REPLACE
		SCALE(string) SEED(int 0) 
		Vfactor(real 1) ] ;
	#delimit cr ;

	if `"`saving'"'=="" {
		local filetmp "yes"
        	if "`replace'"!="" {
                	di as err "replace valid only with saving()"
                	exit 198
        	}
	}
	else {
		capture qui describe using `saving'
		if _rc == 0 & "`replace'" == "" {
			error 602
		}
	}


        if "`offset'"!="" & "`lnoffset'"!="" {
                di as err "only one of offset() or lnoffset() can be specified"
                exit 198
        }

	if `vfactor' <= 0.0 {
		di as err "vfactor() must be positive"
		exit 198
	}

	tempvar clusvar
	if "`cluster'" != "" { 
		local robust "robust" 
		qui egen long `clusvar' = group(`cluster')
	}
	else    gen long `clusvar' = _n

	MakeLst "`ind'" "`inst'" 
	local Z "`r(Z)'"
	local W "`r(W)'"
	local S "`r(S)'"

	local ns : word count `S'
	local nw : word count `W'


	if `nw' > `ns' {
		noi di as err "list of instruments is too short"
		noi di as err "instruments: `S'"
		noi di as err "me vars    : `W'"
		exit 198
	}

	if `nw' == 0 & `ns' > 0 {
		noi di as err "no me vars for specified instruments"
		exit 198
	}

	MapFL "`family'" "`link'"
	local fam	`"`r(fam)'"'
	local farg	`"`r(famarg)'"'
	local fcode	`"`r(famcode)'"'
	local fstr	`"`r(fstr)'"'
	local lnk	`"`r(lnk)'"'
	local larg	`"`r(lnkarg)'"'
	local lcode	`"`r(lnkcode)'"'
	local lstr	`"`r(lstr)'"'
	local scale1	`"`r(scale1)'"'

	if ("`boot'`bstrap'" != "" & `brep' <= 0) {
		local brep 199
	}
	if (`brep' > 0) {
		local boot "boot"
	}

	if ("`lnk'" == "log" | ( "`lnk'" == "power" & `larg' < 0 )) {
		qui summ `dep' if `touse'
		if r(min) < 0 {
			noi di as err "`lnk' link is invalid with " _c
			noi di as err "negative dependent variable"
			exit 198
		}
	}

	if "`lnk'" == "nbinomial" & `larg' == 0 {
		noi di as err "nbinomial link must have nonzero parameter"
		exit 198
	}

        if `"`scale'"'!="" {
                if "`robust'`mtopel'`boot'" != "" {
                        di as err "cannot use scale() with alternate variances"
                        exit 198
                }
                if `"`scale'"'=="x2" { 
			local scale 0 
		}
                else if `"`scale'"'=="dev" { 
			local scale -1 
		}
                else {
                        capture confirm number `scale'
                        if _rc {
                                di as err "invalid scale()"
                                exit 198
                        }
                        if `scale' <= 0 {
                                di as err "scale(#) must be positive"
                                exit 198
                        }
                }
        }


	if `"`scale'"'=="" {    /* default */
		local scale `scale1'
		local cd
	}
	else if `scale'==0 {    /* Pearson X2 scaling */
		if `scale1' {
			local cd "square root of Pearson"
			local cd "`cd' X2-based dispersion"
		}
	}
	else {                  /* user's scale parameter */
		if !`scale1' | (`scale1' & `scale'!=1) {
			local cd "dispersion equal to square"
			local cd "`cd' root of `scale'"
		}
	}

	if `scale1' == 1 & `scale' != `scale1' {
		local fixme 1
	}
	else {
		local fixme 0
	}


	qui capture {
		tempvar touse binvar
		mark    `touse' `origif' `origin'
		markout `touse' `dep' `ind' `inst'

		/* Process weight */

		tempvar wtvar repvar
		if "`origwt'"!="" {
			qui gen double `wtvar' `origexp' if `touse'
			if "`origwt'" == "pweight" {
				local robust "robust"
			}
		}
		else {
			qui gen byte `wtvar' = `touse' if `touse'
		}

		if "`origwt'" == "fweight" {
			gen double `repvar' = `wtvar'
			replace `wtvar' = 1
		}
		else    gen byte `repvar' = 1

		local fffarg "`farg'"

		if "`farg'" != "" {
			gen double `binvar' = `farg'
			summ `binvar'
			local fffarg = r(max)
		}
		else    gen byte `binvar' = 1

		if `fcode' == 1 | `fcode' == 2 {
			replace `touse' = 0 if `binvar' <= 0 | `dep' > `binvar'
		}

		markout `touse' `wtvar' `cluster' `binvar' `repvar'

		/* Process offset/exposure. */

		tempvar offvar
		if "`lnoffset'"!="" {
			capture assert `lnoffset' > 0 if `touse'
			if _rc {
				di as err "lnoffset() must be greater than zero"
				exit 459
			}
			qui gen double `offvar' = ln(`lnoffset')
			local offstr "ln(`lnoffset')"
		}
		else if "`offset'"!="" {
			markout `touse' `offset'
			local offopt "offset(`offset')"
			gen double `offvar' = `offset'
			local offstr "`offset'"
		}
		else {
			gen byte `offvar' = 0
		}

		if "`origwt'" == "fweight" {
			qui summ `repvar' if `touse', meanonly
		}
		else {
			qui summ `touse' if `touse', meanonly
		}
		local nobs  = r(sum)
		local nnobs = r(N)
		if `nobs' == 0 {
			exit 2000
		}

		local moffset "-`offvar'"

		noi cap noi _rmcoll `Z' if `touse', `constan'
		if _rc == 2000 {
			exit 2001
		}
		else if _rc {
			exit _rc
		}

		local Z  "`r(varlist)'"

		preserve
		keep if `touse'
		local vars "`dep' `Z' `W' `S' `wtvar' `clusvar' `offvar'"
		local vars "`vars' `binvar' `repvar'"
		keep  `vars'
		order `vars'

		if `fcode' == 1 {
			capture assert `dep' == 0 | `dep' == 1
			if _rc {
				noi di as err /*
					*/ "`dep' not 0/1 for Bernoulli model"
				exit 499
			}
		}

		* Sample is set.  Only sample remains in memory

		if "`origwt'" == "pweight" {
			qui summ `wtvar', meanonly
			replace `wtvar' = `wtvar'/r(mean)
		}

		local cc 0
		if "`constan'" == "" {
			local cc 1
		}

		local nz : word count `Z'

		local dfm = `nw' + `nz'
		local p   = `dfm' + (`"`constan'"'=="")
		local df  = `nobs'-`p'

		noi GetCov "`boot'" "`ns'" "`robust'" "`mtopel'" "`oim'"
		local calccv "`r(calccv)'"
		local se1    "`r(se1)'"
		if "`cluster'" != "" {
			local se1 "Modified `se1'"
		}

		if `ns' > 0 {
			local robust ""
		}

		tempname V beta

		mat `beta' = J(1,`p',0)
		mat `V'    = J(`p',`p',0)

		* Get initial values here and put in `beta'

		if 0 == 1 {
		GetInit "`beta'" `fcode' `binvar' `lcode' `larg' /*
			*/ `wtvar' "`dep'" "`Z' `W'" "`constan'" "`moffset'"

		mat `V' = e(V)
		SwapBeta `beta'
		}

		local scalex 1
		if "`scalex'" == "" {
			local scalex 0
		}

		if `ns' == 0 {
					/* GLM */
			local nvars = `p'
			#delimit ;
			noi qvfmex 0
				`message' `fcode' `fffarg' `lcode' 
				`larg' `ltolerance' `iterate' 
				`scalex' `calccv' `brep' `btrim' `seed' 
				`nvars' `nnobs' `beta' `V' 
				"`saving'" `cc'
				;
			#delimit cr
		}
		else {
					/* GLM IV */

			local mt 1
			if "`mtopel'" == "" { 
				local mt 0 
			}

			tempname V 
			mat `V' = `beta''*`beta'
			mat `V' = 0*`V'

			#delimit ;
			noi capture noi qvfmex 3
				`message' `fcode' `fffarg' `lcode' 
				`larg' `ltolerance' `iterate' 
				`scalex' `calccv' `brep' `btrim' `seed'
				`nw' `nz' `ns' `nnobs' `beta' `V'  
				"`saving'" `cc'
				;
			#delimit cr

			local iv "IV "

			if `scale1' == 0 & `mt' {
				mat `V' = `mtdisp'*`V'
			}
		}


		if `status' {
			noi _qvferr `status' `message'
			exit `status'
		}


		/* Passed back from plug-in */

		if "`robust'" != "" & `vfactor' == 1 {
			local ff 1
			if "`cluster'" == "" {
				local ff = `nnobs'/(`nnobs'-1)
			}
			else {
				summ `clustvar', meanonly
				local ng  = `r(max)'
				local ff = `ng'/(`ng'-1)
			}
			mat `V' = `ff'*`V'
		}

		if `disp' == . {
			local disp 0 
		}

		local ff 1
		if `scale1' == 0 { 
			if `scale' != `scale1' { 
				local ff `scale' 
			}
			else { 
				local ff `disp'  
			}
		}

		if `scale' == -1 {
			local ff `dev'/`df'
		}
		else {
			if `fixme' {
				if `scale' { 
					local ff `scale' 
				}
				else { 
					local ff `disp' 
				}
			}
		}

		if "`robust'" != "" {
			local ff = `disp'*`disp'
		}
		if `ns' == 0  { 
			mat `V' = `ff'*`V'
		}
		capture confirm number `disp'
		if _rc {
			local disp  = 0
			local dispc = . 
			local dev   = 0 
			local zapse "yes"
			local p = colsof(`beta')
			mat `V' = J(`p',`p',1) 
		}
		else {
			local dispc = 1/(`disp')
			local dev   = `dev'
		}

		noi FixName `beta' `V' "`Z' `W'"

/*
		if "`mtopel'" != "" {
			tempname yhat 
			local y "`dep'"
			mat score `yhat' = `beta'
			replace `yhat' = `yhat'*`yhat' + `y'*`y' - 2*`y'*`yhat'
			summ `yhat'
			local ff = r(sum)/`df'
			mat `V' = `ff'*`V'
		}
*/


		if "`scale'"=="" {    /* default */
			local scale `scale1'
			if `scale1' { 
				local delta 1 
			}
			else local delta `dispc'
		}
		else if `scale'==0 {    /* Pearson X2 scaling */
			local delta `dispc'
			if `scale1' {
				local cd "square root of Pearson"
				local cd "`cd' X2-based dispersion"
			}
		}
		else if `scale'==-1 {   /* deviance scaling */
			local dispd = `dev'/`df'
			local delta `dispd'
			local cd "square root of deviance-based"
			local cd "`cd' dispersion"
		}
		else {                  /* user scale parameter */
			local delta `scale'
			if !`scale1' | (`scale1' & `scale'!=1) {
				local cd "dispersion equal to square"
				local cd "`cd' root of `delta'"
			}
		}

		tempname Wscale
		if (!`scale1' | (`scale1' & `scale'!=1)) {
			if `scale1' { 
				local dof 100000 
			}
			else local dof `df'
			if `delta'==. { 
				local zapse "yes" 
			}
			else {
				scalar `Wscale' = 1/`delta'
			}
		}

		if "`zapse'"=="yes" {
			local i 1
			while `i'<=rowsof(`V') {
				mat `V'[`i',`i'] = 0
				local i=`i'+1
			}
		}

		if `vfactor' != 1 {
			mat `V' = `vfactor'*`V'
		}

		tempvar touse
		gen byte `touse' = 1
		capture eret post `beta' `V', depname(`dep') /*
			*/ obs(`nobs') esample(`touse')

		if _rc {
noi mat list `V'
mat Vi = syminv(`V')
noi mat list Vi
			noi di as err "variance matrix is not pos-def"
			exit 506
		}

		* Save e() results: macros

		global S_E_vce "`robust'"

		eret local depvar   "`dep'"
		eret local vart     "`fam'"
		eret local lnkt     "`lnk'"
		eret local varf     "`fstr'"
		eret local lnkf     "`lstr'"
		eret local tle      "`iv'Generalized linear models"
		eret local msg      "`cd'"
		eret local opt      "MQL Fisher scoring"
		eret local opt2     "(IRLS EIM)"
		eret local clustvar "`cluster'"
		eret local cons     "`constan'"
		eret local offset   "`offstr'"
		eret local se1      "`se1'"
		if `calccv' == 7 {
			eret local vcetype "Semi-Robust"
		}
		else if `calccv' == 6 {
			eret local vcetype  "Robust"
		}
		else if `calccv' == 4 {
			eret local vcetype  "Murphy-Topel"
		}
		else if `calccv' == 1 {
			eret local vcetype  "Bootstrap"
		}

		if "`fam'" == "Binomial" & /*
			*/ "`lnk'" == "Identity" & "`eform'"=="" {
			eret local msg2 "Coefficients are the risk differences"
		}

		* Save e() results: scalars

		eret scalar N      = `nobs'
		eret scalar df_m   = `dfm'
		eret scalar df     = `df'
		eret scalar fcode  = `fcode'
		eret scalar lcode  = `lcode'
		if "`zapse'" == "yes" {
			eret scalar pdis = .
			eret scalar pdev = 0
			eret scalar dis  = .
			eret scalar dev  = 0
		}
		else {
			eret scalar pdis = `disp'
			eret scalar pdev = `disp'*`df'
			eret scalar dis  = `dev'/`df'
			eret scalar dev  = `dev'
		}
		if "`mtdisp'" != "" {
			eret scalar mtdisp = `mtdisp'
		}

		if `scale1' {
			local disp 1
		}
		eret scalar phi    = `disp'

		if "`cluster'" != "" {
			summ `clustvar', meanonly
			eret scalar N_clust = `r(max)'
		}
		if `brep' > 0 {
			eret scalar N_brep = `brep'
		}
		eret local predict "qvfp"
		eret local cmd     "qvf"
	}
	if _rc {
		exit _rc
	}
	DispEst  , `head' `eform' level(`level')
end


program define SwapBeta
        local beta "`1'"

        local nc = colsof(`beta')
        local nc1 = `nc'-1
        mat `beta' = `beta'[1,`nc'], `beta'[1,1..`nc1']
end



program define DispEst
        syntax [, noHEAD Level(int $S_level) eform]
        di
        if `level' < 10 | `level' > 99 {
                di as err "level() must be between 10 and 99"
                exit 198
        }

        if "`eform'" != "" {
                Eform
                local eform  "`r(eform)'"
        }
        if "`eform'" != "" {
                local eopt "eform(`eform')"
        }

        if "`head'" == "" { 
		Head 
	}
        eret di, level(`level') `eopt' first
        if "`e(msg)'" != "" {
                noi di as txt "(Standard errors scaled using `e(msg)')"
        }
        if "`e(msg2)'" != "" {
                noi di as txt "`e(msg2)'"
        }
end

program define Head
/*
----+----1----+----2----+----3----+----4----+----5----+----6----+----7----+---
Generalized linear models                          No. of obs      = #########
Optimization     :                                 Residual df     = #########
                                                   Scale param     = #########
Deviance         = #########                       (1/df) Deviance = #########
Pearson          = #########                       (1/df) Pearson  = #########

Variance Function: V(u) = ########################    ########################
Link Function    : g(u) = ########################    ########################
Standard Errors  : ###############################
                   ###############################
*/
        di as txt "`e(tle)'" /*
                */ _col(52) "No. of obs"        _col(68) "=" /*
                */ _col(70) as res %9.0g e(N)
        di as txt "Optimization     : " as res "`e(opt)'" /*
                */ as txt _col(52) "Residual df" _col(68) "=" /*
                */ _col(70) as res %9.0g e(df)

        di as res _col(20) "`e(opt2)'" as txt _col(52) "Scale param"  /*
                */ _col(68) "="  _col(70) as res %9.0g e(phi)

        di as txt "Deviance" _col(18) "=" as res _col(20) %12.0g e(dev) /*
                */ as txt _col(52) "(1/df) Deviance" /*
                */ _col(68) "=" as res _col(70) %9.0g e(dis)
        di as txt "Pearson" _col(18) "=" as res _col(20) %12.0g e(pdev) /*
                */ as txt _col(52) "(1/df) Pearson" /*
                */ _col(68) "=" as res _col(70) %9.0g e(pdis)

        di
        di as txt "Variance Function: " as res "V(u) = " /*
                */ as res _col(27) "`e(varf)'" /*
                */ _col(52) as txt "[" as res "`e(vart)'" as txt "]"
        di as txt "Link Function    : " as res "g(u) = " /*
                */ as res _col(27) "`e(lnkf)'" /*
                */ _col(52) as txt "[" as res "`e(lnkt)'" as txt "]"

        di as txt "Standard Errors  : " as res "`e(se1)'"
        if "`e(se2)'" != "" {
                di as res _col(20) "`e(se2)' weights"
        }
        else if "`e(disp)'" != "" & "`e(disp)'" != "1" {
                di as txt "Quasi-likelihood model with dispersion: " /*
                        */ as res `e(disp)'
        }
        di
end


program define Eform , rclass
        local var = `e(fcode)'
        local lnk = `e(lcode)'

        if `lnk' == 1 | `lnk' == 10 {
                local eform "Odds Ratio"
        }
        else if `lnk' == 7 | `lnk' == 6 {
                local eform "ExpB"
        }
        else if `var' == 4 {
                local eform "IRR"
        }
        else if `var' == 1 | `var' == 2 {
                if `lnk' == 2 {
                        local eform "Risk Ratio"
                }
                else if `lnk' == 0 {
                        local eform "ExpB"
                }
                else if `lnk' == 4 {
                        local eform "Hlth Ratio"
                }
        }
        else local eform "e^coef"
        return local eform "`eform'"
end



program define FixName
	args b v names

	tempname b1 b2 b3 b4 vu vd
	local n = colsof(`b')
	mat `b1' = `b'[1,1]
	mat `b2' = `b'[1,2..`n']
	mat `b' = `b2',`b1'

	mat `b1' = `v'[1,1]
	mat `b2' = `v'[1,2..`n']
	mat `b3' = `v'[2..`n',1]
	mat `b4' = `v'[2..`n',2..`n']
	mat `vu' = `b4',`b3'
	mat `vd' = `b2',`b1'
	mat `v' = `vu'\ `vd'

	local m : word count `names'
	if `m' < `n' {
		local nn "_cons"
	}

	mat colnames `b' = `names' `nn'
	mat colnames `v' = `names' `nn'
	mat rownames `v' = `names' `nn'
end


program define MakeLst, rclass
	args ind inst 

	local nxw : word count `ind'
	local nxr : word count `inst'

	if `nxr' == 0 {
		ret local Z "`ind'"
		ret local W ""
		ret local S ""
		exit
	}

	local Z ""
	local W ""
	local S ""
	local s ""
	local i 1 
	while `i' <= `nxw' {
		local x : word `i' of `ind'
		local z 0
		local j 1 
		while `j' <= `nxr' {
			local t : word `j' of `inst'
			if "`x'" == "`t'" {
				local s "`s' `j'"
				local z 1
				local j = `nxr'
			}
			local j = `j' + 1
		}
		if `z' == 1 { 
			local Z "`Z' `x'" 
		}
		else        { 
			local W "`W' `x'" 
		}
		local i = `i' + 1
	}
	local nxs : word count `s'
	local i 1
	while `i' <= `nxr' {
		local x : word `i' of `inst'
		local z 0
		local j 1 
		while `j' <= `nxs' {
			local t : word `j' of `s'
			if `t' == `i' {
				local z 1
				local j = `nxs'
			}
			local j = `j'+1
		}
		if `z' == 0 { 
			local S "`S' `x'" 
		}
		local i = `i' + 1
	}
	ret local Z "`Z'"
	ret local W "`W'"
	ret local S "`S'"
end
		
program define MapFL, rclass
	args fam lnk

	MapF `fam'
	ret local fam     `"`r(fam)'"'
	ret local famarg  `"`r(farg)'"'
	ret local famcode `"`r(fcode)'"'
	ret local fstr    `"`r(fstr)'"'
	ret local scale1  `"`r(scale1)'"'

	MapL "`r(fcode)'" "`r(farg)'" `lnk'

	ret local lnk     `"`r(lnk)'"'
	ret local lnkarg  `"`r(larg)'"'
	ret local lnkcode `"`r(lcode)'"'
	ret local lstr    `"`r(lstr)'"'
end

program define MapL, rclass
	args fc farg lnk larg 

	if `fc' != 2 { 
		local farg = 1 
	}

	local lcode = -1

	local l = lower(trim(`"`lnk'"'))
	local n = length(`"`l'"')

	if `"`l'"' == "" {
		if `fc' == 0       { 
			local lcode = 0 
		}
		else if `fc' == 1  { 
			local lcode = 1 
		}
		else if `fc' == 2  { 
			local lcode = 1 
		}
		else if `fc' == 3  { 
			local lcode = 2 
		}
		else if `fc' == 4  { 
			local lcode = 9 
			local larg  = -1
		}
		else if `fc' == 5  { 
			local lcode = 9 
			local larg  = -2 
		}
		else if `fc' == 6  { 
			local lcode = 2 
		}
		else { 
			noi di as err "power family needs link specified"
			exit 198
		}
	}
	else if `"`l'"'==substr("identity",1,`n')          { 
		local lcode = 0  
	}
	else if `"`l'"'==substr("logit",1,max(4,`n'))      { 
		local lcode = 1  
	}
	else if `"`l'"'==substr("log",1,max(3,`n'))        { 
		local lcode = 2  
	}
	else if `"`l'"'==substr("nbinomial",1,max(3,`n'))  { 
		local lcode = 3  
	}
	else if `"`l'"'==substr("logc",1,max(4,`n'))       { 
		local lcode = 4  
	}
	else if `"`l'"'==substr("loglog",1,max(2,`n'))     { 
		local lcode = 5  
	}
	else if `"`l'"'==substr("cloglog",1,max(2,`n'))    { 
		local lcode = 6  
	}
	else if `"`l'"'==substr("probit",1,max(2,`n'))     { 
		local lcode = 7  
	}
	else if `"`l'"'==substr("reciprocal",1,max(2,`n')) { 
		local lcode = 9  
	}
	else if `"`l'"'==substr("power",1,max(2,`n'))      { 
		local lcode = 9  
	}
	else if `"`l'"'==substr("opower",1,max(2,`n'))     { 
		local lcode = 10 
	}

	if "`larg'" == "" { 
		local larg "1" 
	}

	if `lcode' == 0 | (`lcode' == 9 & `larg' == 1) {
		local lnk "Identity"
		if "`farg'" == "1" {
			local lst "u"
		}
		else    local lst "u/`farg'"
	}
	else if `lcode' == 1 | (`lcode' == 10 & `larg' == 0) {
		local lnk "Logit"
		if "`farg'" == "1" {
			local lst "log(u/(1-u))"
		}
		else    local lst "log(u/(`farg'-u))"
	}
	else if `lcode' == 2 | (`lcode' == 9 & `larg' == 0) {
		local lnk "Log"
		if "`farg'" == "1" {
			local lst "ln(u)"
		}
		else    local lst "ln(u/`farg')"
	}
	else if `lcode' == 3 {
		local lnk "Neg. Binomial"
		local lst "ln(u/(u+1/`larg')"
	}
	else if `lcode' == 4 {
		local lnk "Log complement"
		if "`farg'" == "1" {
			local lst "ln(1-u)"
		}
		else    local lst "ln(1-u/`farg')"
	}
	else if `lcode' == 5 {
		local lnk "Log-log"
		if "`farg'" == "1" {
			local lst "-ln(-ln(u))"
		}
		else    local lst "-ln(-ln(u/`farg'))"
	}
	else if `lcode' == 6 {
		local lnk "Complementary log-log"
		if "`farg'" == "1" {
			local lst "ln(-ln(1-u))"
		}
		else    local lst "ln(-ln(1-u/`farg'))"
	}
	else if `lcode' == 7 {
		local lnk "Probit"
		if "`farg'" == "1" {
			local lst "invnorm(u)"
		}
		else    local lst "invnorm(u/`farg')"
	}
	else if `lcode' == 8 | (`lcode' == 9 & `larg' == -1) {
		local lnk "Reciprocal"
		if "`farg'" == "1" {
			local lst "1/u"
		}
		else    local lst "`farg'/u"
		local lcode = 9
		local larg  = -1
	}
	else if `lcode' == 9 {
		local lnk "Power"
		if "`farg'" == "1" {
			local lst "u^(`larg')"
		}
		else    local lst "(u/`farg')^(`larg')"
	}
	else if `lcode' == 10 {
		local lnk "Odds power"
		if "`farg'" == "1" {
			local lst "((u/(1-u))^(`larg')-1)/(`larg')"
		}
		else    local lst "((u/(`farg'-u))^(`larg')-1)/(`larg')"
	}

	ret local lnk   "`lnk'"
	ret local larg  "`larg'"
	ret local lcode "`lcode'"
	ret local lstr  "`lst'"
end

program define MapF, rclass
	args fam farg
	
	local fcode = -1

	local f = lower(trim(`"`fam'"'))
	local n = length(`"`f'"')

	if `"`f'"' == "" 		                  { 
		local fcode = 0 
	}
	else if `"`f'"'==substr("gaussian",1,max(3,`n'))  { 
		local fcode = 0 
	}
	else if `"`f'"'==substr("normal",1,`n')           { 
		local fcode = 0 
	}
	else if `"`f'"'==substr("binomial",1,`n')         { 
		local fcode = 2 
	}
	else if `"`f'"'==substr("bernoulli",2,`n')        { 
		local fcode = 1 
	}
	else if `"`f'"'==substr("poisson",1,`n')          { 
		local fcode = 3 
	}
	else if `"`f'"'==substr("gamma",1,max(3,`n'))     { 
		local fcode = 4 
	}
	else if `"`f'"'==substr("igaussian",1,max(2,`n')) { 
		local fcode = 5 
	}
	else if `"`f'"'==substr("inormal",1,max(2,`n'))   { 
		local fcode = 5 
	}
	else if `"`f'"'==substr("ivg",1,max(2,`n'))       { 
		local fcode = 5 
	}
	else if `"`f'"'==substr("nbinomial",1,max(2,`n')) { 
		local fcode = 6 
	}
	else if `"`f'"'==substr("power",1,max(3,`n'))     { 
		local fcode = 7 
	}

	if "`farg'" != "" {
		local n : word count `farg'
		if `n' > 1 {
			noi di as err "illegal family argument"
			exit 198
		}
		capture confirm number `farg' 
		if _rc {
			capture confirm numeric variable `farg'
			if _rc {
				noi di as err "unknown variable `farg'"
				exit 111
			}
			capture assert `farg'==int(`farg')
			if _rc {
				noi di as err "Variable `farg' is not integer"
				exit 499
			}
		}
		else {
			if `farg' <= 0 {
				noi di as err "illegal family argument"
				exit 198
			}
			if `fcode' == 2 {
				capture confirm integer number `farg'
				if _rc {
					noi di as err "Binomial " /*
						*/ "argument must be integer"
					exit 198
				}
			}
		}
	}
	else {
		local farg = 1
	}

	if `fcode' == 2 & `farg' == 1 {
		local fcode = 1
	}

	local scale1 0 
	if `fcode' == -1 {
		noi di as err "Unknown family function"
		exit 198
	}
	else if `fcode' == 0 { 
		local fam "Gaussian"      
		local fst "1"
	}
	else if `fcode' == 1 { 
		local fam "Bernoulli"     
		local fst "u(1-u)"
		local scale1 1
	}
	else if `fcode' == 2 { 
		local fam "Binomial"      
		local fst "u(1-u/(`farg'))"
		local scale1 1
	}
	else if `fcode' == 3 { 
		local fam "Poisson"       
		local fst "u"
		local scale1 1
	}
	else if `fcode' == 4 { 
		local fam "Gamma"         
		local fst "u^2"
	}
	else if `fcode' == 5 { 
		local fam "Igauss"        
		local fst "u^3"
	}
	else if `fcode' == 6 { 
		local fam "Neg. Binomial" 
		local fst "u+(`farg')u^2"
		local scale1 1
	}
	else if `fcode' == 7 { 
		local fam "Power" 
		local fst "u^(`farg')"
	} 
	ret local fam		"`fam'"
	ret local farg		"`farg'"
	ret local fcode		"`fcode'"
	ret local fstr		"`fst'"
	ret local scale1	"`scale1'"
end

program define GetCov, rclass
	args boot ns robust mtopel oim

		/******************************************************
			ns     =  number of instruments
			boot   = whether bootstrap
			robust = whether robust
			mtopel = whether mtopel
			oim    = whether oim

			calccv
			------
			1	bootstrap
			2	EIM qvf (no instruments)
			3	robust OIM qvf with instruments (IVAR)
			4	mtopel (no instruments)
			5	OIM qvf (no instruments)
			6	OIM robust qvf (no instruments)
			7	EIM robust qvf (no instruments)
		*******************************************************/

	if "`boot'" != "" {
		local calccv 1
		local se1    "Bootstrap"
		if "`robust'`mtopel'`oim'" != "" {
			noi di as err "bootstrap can not be combined " /*
				*/ "with other variance options"
			error 198
		}
	}

	else if `ns' != 0 {
		if "`mtopel'" != "" & "`robust'" != "" {
			noi di as err "Only one of mtopel and robust allowed"
			error 198
		}
		if "`mtopel'" != "" {
			local calccv 4
			local se1 "Murphy-Topel"
		}
		else {
			local robust "robust"
			local calccv 3
			local se1 "OIM Sandwich"
		}
	}
	else {
		if "`mtopel'" != "" {
			noi di as err "Murphy-Topel estimates available for " /*
				*/ "instrumental variables models only"
			error 198
		}

		local calccv 2
		local se1    "EIM Hessian"

		if "`robust'" != "" {
			if "`oim'" != "" {
				local calccv 6 
				local se1 "OIM Sandwich"
			}
			else {
				local calccv 7
				local se1 "EIM Sandwich"
			}
		}
		else if "`oim'" != "" {
			local calccv 5
			local se1    "OIM Hessian"
		}
	}
	ret local calccv "`calccv'"
	ret local se1    "`se1'"
end
			

program define qvfmex, plugin


exit

program define GetInit 
	args beta fcode farg lcode larg wtvar dep xvars constant moffset

	tempvar mu eta z dmu W v
	tempname Wscale
	summ `dep' [aw=`wtvar'] 

	if `fcode' != 2 {
		gen double `mu' = (`dep'+r(mean)) / (`farg'+1)
		local ff = 1
	}
	else {
		gen double `mu' = `farg'*(`dep'+.5)/(`farg'+1)
		local ff = `farg'
	}

	GetEta `eta' `mu' `lcode' "`larg'"  "`ff'"
	GetV   `eta' `mu' `v'     `fcode' "`farg'"
	GetDmu `eta' `mu' `dmu'   `lcode' "`larg'" "`farg'"

	gen double `z' = `eta' + (`dep'-`mu')/`dmu' `moffset'
	gen double `W' = `dmu'*`dmu'/`v'
	summ `W' [aw=`wtvar']
	scalar `Wscale' = r(mean)

	reg `z' `xvars' [iw=`W'*`wtvar'/`Wscale'], mse1 `constan'

	mat `beta' = e(b)
end

program define GetEta
	args eta mu lcode larg f

	if `lcode' == 0       { 
		gen double `eta' = `mu'/`f' 
	}
	else if `lcode' == 1  { 
		gen double `eta' = ln(`mu'/(`f'-`mu')) 
	}
	else if `lcode' == 2  { 
		gen double `eta' = ln(`mu'/`f') 
		}
	else if `lcode' == 3  { 
		gen double `eta' = ln(`mu'/(`mu'+(1/`f'))) 
	}
	else if `lcode' == 4  { 
		gen double `eta' = ln(1-`mu'/`f') 
	}
	else if `lcode' == 5  { 
		gen double `eta' = -ln(-ln(`mu'/`f')) 
	}
	else if `lcode' == 6  { 
		gen double `eta' = ln(-ln(1-`mu'/`f')) 
	}
	else if `lcode' == 7  { 
		gen double `eta' = invnorm(`mu'/`f') 
	}
	else if `lcode' == 8  { 
		gen double `eta' = `f'/`mu' 
	}
	else if `lcode' == 9  { 
		gen double `eta' = (`mu'/`f')^(`larg') 
	}
	else if `lcode' == 10 { 
		gen double `eta' = ((`mu'/(`f'-`mu'))^(`larg')-1) / `larg' 
	}
end

program define GetV
	args eta mu v fcode f

	if `fcode' == 0      { 
		gen double `v' = 1 
	}
	else if `fcode' == 1 { 
		gen double `v' = (`mu'*(1-`mu'/`f')) 
	}
	else if `fcode' == 2 { 
		gen double `v' = (`mu'*(1-`mu'/`f')) 
	}
	else if `fcode' == 3 { 
		gen double `v' = `mu' 
	}
	else if `fcode' == 4 { 
		gen double `v' = `mu'*`mu' 
	}
	else if `fcode' == 5 { 
		gen double `v' = `mu'*`mu'*`mu' 
	}
	else if `fcode' == 6 { 
		gen double `v' = `mu'+`mu'*`mu'*`f' 
	}
	else if `fcode' == 7 { 
		gen double `v' = `mu'^(`f') 
	}
end

program define GetDmu
	args eta mu dmu lcode larg f

	if `lcode' == 0        { 
		gen double `dmu' = `f' 
	}
	else if `lcode' == 1   { 
		gen double `dmu' = `mu'*(1-`mu'/`f') 
	}
	else if `lcode' == 2   { 
		gen double `dmu' = `mu' 
	}
	else if `lcode' == 3   { 
		gen double `dmu' = `mu'*(1+`mu'*`f') 
	}
	else if `lcode' == 4   { 
		gen double `dmu' = `mu'-`f' 
	}
	else if `lcode' == 5   { 
		gen double `dmu' = -`mu'*ln(`mu'/`f') 
	}
	else if `lcode' == 6   { 
		gen double `dmu' = (`mu'-`f')*ln(1-`mu'/`f') 
	}
	else if `lcode' == 7   { 
		gen double `dmu' = `f'*normd(invnorm(`mu'/`f')) 
	}
	else if `lcode' == 8   { 
		gen double `dmu' = -`mu'*`mu'/`f' 
	}
	else if `lcode' == 9   { 
		gen double `dmu' = `mu'^(1-`larg')* (`f')^(`larg')/(`larg')
	}
	else if `lcode' == 10  { 
		gen double `dmu' = `f'*(`mu'/`f')^(1-`larg') * /*
			*/ (1-`mu'/`f')^(1+`larg') 
	}
end

