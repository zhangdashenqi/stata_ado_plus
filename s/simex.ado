*! version 2.2.0  07may2003                     (SJ3-4: st0049, st0050, st0051)
program define simex, eclass byable(onecall)
	version 8.0

	if replay() {
		if _by() {
			error 190
		}
		if "`e(cmd)'" != "simex" {
			error 301
		}
		DispEst `"`0'"'
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
	_crcdeq `"`0'"' , weight(fweight iweight pweight) 
	
	local 0 ",`opts'"
	#delimit ;
	syntax [, SCALE(string) MESSage(int 2) Family(string) 
		Link(string) LTOLerance(real 1e-6) 
		ITERate(int 100) SEED(int 0)
		BSTRAP BOOT BREP(int -1) LINear RATional  MEDian 
		THEta(string)
		SUUINIT(string) BTRIM(real .02) 
		SAVing(str) REPLACE
		SREP(int 50) NLEPS(real 1) NLREP(int 100) noSCALEX ] ;
	#delimit cr

	if `"`saving'"'=="" {
		local filetmp "yes"
        	if "`replace'"!="" {
                	di in red "replace can only be specified when " /*
			*/ "using saving() option"
                	exit 198
        	}
	}
	else {
		capture qui describe using `saving'
		if _rc == 0 & "`replace'" == "" {
			error 602
		}
	}

	if `neq' == 1 {
		di in red "no measurement error data"
		exit 198	
	}

	if "`boot'`bstrap'"!="" & `brep' < 0 {
		local brep 199
	}
	if `brep' > 0 {
		local boot "boot"
	}

	MapFL "`family'" "`link'"
	local fam	`"`r(fam)'"'
	local famarg	`"`r(famarg)'"'
	local fcode	`"`r(famcode)'"'
	local fstr	`"`r(fstr)'"'
	local lnk	`"`r(lnk)'"'
	local lnkarg	`"`r(lnkarg)'"'
	local lcode	`"`r(lnkcode)'"'
	local lstr	`"`r(lstr)'"'
	local scale1	`"`r(scale1)'"'


	local method 0
	if "`rational'" != ""	{ 
		local method 1 
	}
	else if "`linear'" != "" {			{ 
		local method 2 
	}

	if "`median'" == "" 	{ 
		local mean 0 
	}
	else			{ 	
		local mean 1 
	}

	local uutype 1
	if "`suu'" == "" {
		tempname sumat
		local suu "`sumat'"
	}
	else {
		local suusave "yes"
	}
	if "`suuinit'" != "" {
		tempname bb
		confirm matrix `suuinit'
		capture mat `bb' = syminv(`suuinit')
		if _rc {
			di in red "suu() must name a symmetric matrix"
			exit 198
		}
		tempname newname
		mat `newname' = `suuinit'
		local suu "`newname'"
		local uutype 0
	}

	if "`theta'" == "" {
		tempname lamm lamm0
		mat `lamm' = (0,.5,1,1.5,2) 
		mat `lamm0' = `lamm'
		local theta "`lamm'"
	}
	else {
		tempname lamm lamm0
		confirm matrix `theta'
		local nr = rowsof(`theta')
		local nc = colsof(`theta')
		if `nr' != 1 {
			di as err "Must supply a row vector in theta() option"
			exit 198
		}
		mat `lamm' = `theta'
		local flag 0
		local badv 0 
		tempname ss
		local i 1
		while `i' <= `nc' {
			scalar `ss' = `lamm'[1,`i']
			if `ss' == 0 {
				local flag = 1
			}
			if `ss' < 0 {
				local badv = 1
			}
			local i = `i'+1
		}
		if `flag' == 0 {
			di as err "theta() vector must contain zero"
			exit 198
		}
		if `badv' == 1 {
			di as err "theta() vector must be nonnegative"
			exit 198
		}
		mat `lamm0' = `lamm'
		local theta  "`lamm'"
	}
			

	qui {
		if "`scalex'" == "" { 
			local scalex 0 
		}
		else                { 
			local scalex 1 
		}

		tempvar touse
		mark `touse' `ifx' `inx' `wgt'

                local totlst "`ind1'"
                local i 2
                while `i' <= `neq' {
                        global S_WL`i' "`ind`i''"
                        local totlst "`totlst' `ind`i''"
                        local i = `i'+1
                }
                local ntot : word count `totlst'
                qui _rmcoll `totlst'
                local ctot : word count `r(varlist)'
                if `ntot' != `ctot' {
                        di as err "varlists must contain unique variables"
                        exit 198
                }
                global S_WL1 = `neq'-1
                noi ChkReps `touse'

                local i 2
                while `i' <= `neq' {
                        local ind`i' "${S_WL`i'}"
                        local i = `i'+1
                }


		local i 1
		while `i' <= `neq' {
			SetSamp `touse' "`dep`i''" "`ind`i''" "`i'" "regeq"
			local i = `i' + 1
		}
		local i 1
		while `i' <= `neq' {
			RmColl `touse' "`dep`i''" "`ind`i''" "`nc`i''" "ind`i'"
			local i = `i'+1
		}

		local cc 0
		if "`constan'" == "" {
			local cc 1
		}

		preserve
		keep if `touse'
		local lst "`dep`regeq'' `ind`regeq''"
		local nms "`ind`regeq''"
		local i 1
		local nwreal = 0
		while `i' <= `neq' {
			if `i' != `regeq' { 
				local lst "`lst' `ind`i''" 
				local nms "`nms' `eq`i''" 
				capture confirm var `eq`i''
				if _rc == 0 {
				di in red "illegal equation name. " _c
				di in red "`eq`i'' exists as a variable."
					exit 198
				}
				local nind : word count `ind`i''
				local k 1
				while `k' <= `nind' {
					local w : word `k' of `ind`i''
					count if `w'!=.
					local nwreal = `nwreal'+r(N)
					local k = `k'+1
				}
			}
			local i = `i'+1
		}
		order `lst'

		local tlist "`nms'"
		local p : word count `ind`regeq''
		if "`nc`regeq''" == "" {
			local nms "`nms' _cons"
			local p = `p'+1	
		}

		local nw = `neq' 
		local nw1 = `nw'-1
		tempname wmat
		matrix `wmat' = J(1,`nw',0) 
		matrix `wmat'[1,1] = `nw1'

		local i 1 
		local k 2
		while `i' <= `neq' {
			if `i' ~= `regeq' {
				local numw : word count `ind`i''
				matrix `wmat'[1,`k'] = `numw'
				local k = `k'+1
			}
			local i = `i'+1
		}
		local px = `neq'-1
		local nvars = `p'+`px'

		local hassv 0
		if "`from'" != "" {
			ChkB0 `from' `tlist'
			local hassv `r(flag)'
		}
		tempname beta
		if `hassv' == 0 {
			summ `dep'
			local mm = r(mean)
			mat `beta' = J(1,`nvars',0)
			mat `beta'[1,`nvars'] = `mm'
		}
		else mat `beta' = `from'

		FixBeta `beta'

		tempname cv var 
		describe
		local nobs   = r(N)

		if "`boot'" == "" {
			local calccv 0
			local boot 0 
		}
		else {
			local boot 1
			local calccv 1	/* Later change to 1 !! */
		}

		if `message' > 0 { 
			local jj "noi"
		}
		
		#delimit ;
                noi qvfmex 2
			`message' `fcode' `famarg' `lcode' 
			`lnkarg' `ltolerance' `iterate' 
			`scalex' `calccv' `brep' `btrim' `seed'
			`nvars' `nobs' `beta' `cv' "`saving'" `cc'
			`suu' `uutype' `mean' `method' `srep' `theta'
			`nleps' `nlrep'
			`px' `nwreal' `wmat'
			;
		#delimit cr

		if `status' {
			_qvferr `status' `message'
			exit `status'
		}
		qui FixName `beta' `cv' `theta' `lamm0' "`nms'"

		/* If we did not bootstrap, then the returning
			variance matrix is simply the last 
			qvf iteration's vce which is not valid,
			so we zero it out
		*/
		mat `cv' = `boot'*`cv'


		/* ****************************** 

			(*) check status for error
			
			if no error

			(*) `beta' has the coefficient vector
			(*) `cv'   has the variance matrix
			(*) `var'  has the dispersion 

		   ****************************** */

		local obs = _N
		local dof = `obs'-`p'-(`neq'-1)

		tempvar mui

		eret post `beta' `cv' , depname(`dep`regeq'') /*
			*/ obs(`obs') dof(`dof')

		if `mean' == 0 {
			eret local type "Mean"
		}
		else {
			eret local type "Median"
		}

		if `method' == 0 {
			eret local method "Quadratic"
			eret local calc   "Linear regression"
		}
		else if `method' == 1 {
			eret local method "Rational"
			eret local calc   "Nonlinear least squares"
		}
		else {
			eret local method "Linear"
			eret local calc   "Linear regression"
		}

		test `tlist', min
		capture eret matrix suu    = `suu'
		eret scalar F      = r(F)
		eret scalar df_m   = r(df_r) 
		eret scalar df_p   = r(df) 

		eret local family   "`fam'"
		eret local link	    "`lnk'"

		eret local depvar   "`dep'"
		eret local vart     "`fam'"
		eret local lnkt     "`lnk'"
		eret local varf     "`fstr'"
		eret local lnkf     "`lstr'"

		local df = `dof'

/*
		eret scalar pdis = `disp'
		eret scalar pdev = `disp'*`df'
		eret scalar dis  = `dev'/`df'
		eret scalar dev  = `dev'
*/

		eret scalar N_sim  = `srep'
		if `boot' {
			eret local vcetype "Bootstrap"
			eret scalar N_boot = `brep'
		}
		if "`disp'" != "" {
			eret scalar dispers = `disp'
		}
		eret matrix theta    = `lamm'
		eret scalar N        = `obs'
		eret local cmd       "simex"
	}
	DispEst ", `opt'"
end


program define DispEst
	local options "Level(integer $S_level)"
	parse "`*'"

	#delimit ;
	noi di as txt _n "Simulation extrapolation" 
		/* as txt "Family       = " as res "`e(family)'" */
		_col(49) as txt "No. of obs" _col(68) "=" 
		_col(70) as res %9.0g e(N) ;
	#delimit cr
	if e(N_boot) != . { 
		#delimit ;
		di /* as txt "Link         = " as res "`e(link)'" */
			as txt
			_col(49) "Bootstraps reps " _col(68) "=" 
			_col(70) as res %9.0g e(N_boot) ;
		#delimit cr
	} 
/*
	else { 
		di in gr "Link         = " as res "`e(link)'"  
	} 
*/
	#delimit ;
	di as txt _n "Residual df  = " as res %9.0g e(df_m)
		as txt  _col(49) "Wald F(" in ye e(df_p) as txt ","
		as res e(df_m) in gr ")" _col(68) "=" as res _col(70)
		%9.2f e(F) ;
	di as txt _col(49) "Prob > F" _col(68) "=" as res _col(70)
		%9.4f fprob(e(df_p),e(df_m),e(F)) ;
	#delimit cr
/*
        di as txt "Deviance" _col(18) "=" as res _col(20) %12.0g e(dev) /*
                */ as txt _col(52) "(1/df) Deviance" /*
                */ _col(68) "=" as res _col(70) %9.0g e(dis)
        di as txt "Pearson" _col(18) "=" as res _col(20) %12.0g e(pdev) /*
                */ as txt _col(52) "(1/df) Pearson" /*
                */ _col(68) "=" as res _col(70) %9.0g e(pdis)
*/
        di
        di as txt "Variance Function: " as res "V(u) = " /*
                */ as res _col(27) "`e(varf)'" /*
                */ _col(52) as txt "[" as res "`e(vart)'" as txt "]"
        di as txt "Link Function    : " as res "g(u) = " /*
                */ as res _col(27) "`e(lnkf)'" /*
                */ _col(52) as txt "[" as res "`e(lnkt)'" as txt "]"




	di 
	mat mlout, level(`level')
end


program define ChkB0, rclass
	local mat "`1'"
	mac shift 
	local vlist "`*'"
	local p : word count `vlist'
	local p = `p'+1

	local nc = colsof(`mat')
	if `nc' != `p' {
		mat `mat' = J(1,`p',0)
		ret scalar flag 0
	}
	matrix colnames `mat' = `vlist' _cons
	ret scalar flag = 1
end

program define FixName	
	local b "`1'"	
	local v "`2'"	
	local m "`3'"
	local m0 "`4'"
	local names "`5'"

	tempname b1 b2 b3 b4 vu vd
	local n = colsof(`b')
	mat `b1' = `b'[1,1]	
	mat `b2' = `b'[1,2..`n']
	mat `b' = `b2',`b1'

	mat `vu' = (-1)
	mat `vd' = `m0''
	mat `b3' = `m'[1...,1]
	mat `b4' = `m'[1...,2...]
	mat `m' = `vu',`b' 
	mat `b3' = `vd',`b4',`b3'
	mat `m' = `m' \ `b3'

	mat colnames `m' = theta `names'

	capture mat `b1' = `v'[1,1]
	if _rc {
		mat colnames `b' = `names'
		local nc = colsof(`b')
		mat `v' = J(`nc',`nc',0)
		mat colnames `b' = `names'
		mat colnames `v' = `names'
		mat rownames `v' = `names'
		exit
	}
	mat `b2' = `v'[1,2..`n']
	mat `b3' = `v'[2..`n',1]
	mat `b4' = `v'[2..`n',2..`n']

	mat `vu' = `b4',`b3'
	mat `vd' = `b2',`b1'
	mat `v' = `vu'\ `vd'

	mat colnames `b' = `names'
	mat colnames `v' = `names'
	mat rownames `v' = `names'
end

program define SetSamp
	args touse y x i regeq
	if "`x'" == "" & `i' != 1 {		
		noi di in red "equation `i' has no measurement error covariates"
		exit 198
	}
	if "`y'" != "" {
		c_local `regeq' `i'
		markout `touse' `y' `x'
		exit
	}
	tempvar mm
	egen `mm' = rmiss(`x')
	local nx : word count `x'
	replace `touse' = 0 if  `mm'==`nx'
end
	
program define RmColl
	args touse y x nc ind
	if "`y'" == "" {
		exit
	}
	_rmcoll `x' if `touse' , `nc'
	c_local `ind' "`r(varlist)'"
end

program define CkFamLk
	
	local nf : word count `1'
	local nl : word count `2'

	if `nf' > 2 {
		noi di in red "illegal family option"
		exit 198
	}
	if `nl' > 2 {
		noi di in red "illegal link option"
		exit 198
	}
	local fam    : word 1 of `1'
	local famarg : word 2 of `1'
	local lnk    : word 1 of `2'
	local lnkarg : word 2 of `2'

	local fam = lower(trim("`fam'"))
	local lnk = lower(trim("`lnk'"))

	local fl = length("`fam'")
	local ll = length("`lnk'")

	if "`fam'" == substr("poisson",1,max(3,`fl')) {
		local family 1
		local famstr "poisson"
	}
	else if "`fam'" == substr("gamma",1,max(3,`fl')) {
		local family 2
		local famstr "gamma"
	}
	else if "`fam'" == substr("power",1,max(3,`fl')) {
		local family 3
		local famstr "power"
	}
	else if "`fam'" == substr("binomial",1,max(3,`fl')) {
		local family -1
		if "`famarg'" == "" {
			local famarg 1
		}
		local famstr "binomial"
	}
	else if "`fam'" == substr("normal",1,max(3,`fl')) | /*
	*/      "`fam'" == substr("gaussian",1,max(3,`fl')) | "`fam'" == "" { 
		local family 0 
		local famstr "normal"
	}
	else if "`fam'" == substr("power",1,max(3,`fl')) {
		local family 4
		local famstr "power"
	}
	else if "`fam'" == substr("igaussian",1,max(3,`fl')) {
		local family 5
		local famstr "igaussian"
	}
	else if "`fam'" == substr("nbinomial",1,max(3,`fl')) {
		local family 6
		local famstr "nbinomial"
	}
	else {
		noi di in red "unknown family function -- `fam'"
		exit 198
	}

	if "`lnk'" == substr("identity",1,max(3,`ll')) {
		local link 0
	}
	else if "`lnk'" == substr("log",1,max(3,`ll')) {
		local link 1
	}
	else if "`lnk'" == substr("reciprocal",1,max(3,`ll')) {
		local link 2
	}
	else if "`lnk'" == substr("logit",1,max(3,`ll')) {
		local link 3
	}
	else if "`lnk'" == substr("power",1,max(3,`ll')) {
		local link 4
	}
	else if "`lnk'" == substr("opower",1,max(3,`ll')) {
		local link 5
	}
	else if "`lnk'" == substr("cloglog",1,max(3,`ll')) {
		local link 6
	}
	else if "`lnk'" == substr("probit",1,max(3,`ll')) {
		local link 7
	}
	else if "`lnk'" == substr("nbinomial",1,max(3,`ll')) {
		local link 8
	}
	else if "`lnk'" == "" { 
		if `family' == 0      { 
			local link 0 
		}
		else if `family' == 1 { 
			local link 1 
		}
		else if `family' == 2 { 
			local link 2 
		}
		else if `family' == 3 { 
			local link 0 
		}
		else if `family' == 4 { 
			local link 3 
		}
		else if `family' == 5 { 
			local lnkarg -2
			local link 4 
		}
		else if `family' == 6 { 
			local link 1 
		}
		else if `family' ==-1 { 
			local link 3 
		}
	}
	else {
		noi di in red "unknown link function -- `lnk'"
		exit 198
	}

	if `link' == 0      { 
		local lnkstr "identity" 
	}
	else if `link' == 1 { 
		local lnkstr "log" 
	}
	else if `link' == 2 { 
		local lnkstr "reciprocal" 
	}
	else if `link' == 3 { 
		local lnkstr "logit" 
	}
	else if `link' == 4 { 
		local lnkstr "power" 
	}
	else if `link' == 5 { 
		local lnkstr "opower" 
	}
	else if `link' == 6 { 
		local lnkstr "cloglog" 
	}
	else if `link' == 7 { 
		local lnkstr "probit" 
	}
	else if `link' == 8 { 
		local lnkstr "nbinomial" 
	}

	/* Check combination */

	if `family' != -1 & (`link'==3 | `link'==6 | /*
		*/ `link'== 7 | `link'==5) {
		noi di in red "illegal family link combination"
		exit 198
	}

	if `family' != 6  & `link' == 8 {
		noi di in red "illegal family link combination"
		exit 198
	}

	if "`lnkarg'" == "" {
		local lnkarg 0	
	}
	if "`lnkarg'" != "" {
		confirm number `lnkarg'
	}
	if "`famarg'" == "" {		
		local famarg 0
	}

	if "`famarg'" != "" {
		confirm number `famarg'
	}

	c_local family	"`family'"
	c_local famarg	"`famarg'"
	c_local link	"`link'"
	c_local lnkarg	"`lnkarg'"
	c_local famstr	"`famstr'"
	c_local lnkstr	"`lnkstr'"
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
		}
		else if `fc' == 5  { 
			local lcode = 9 
		}
		else if `fc' == 6  { 
			local lcode = 2 
		}
		else { 
			noi di in red "power family needs link specified"
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
			noi di in red "illegal family argument"
			exit 198
		}
		capture confirm number `farg' 
		if _rc {
			capture confirm numeric variable `farg'
			if _rc {
				noi di in red "unknown variable `farg'"
				exit 111
			}
			capture assert bad==long(bad)
			if _rc {
				noi di in red "Variable `farg' is not integer"
				exit 499
			}
		}
		else {
			if `farg' <= 0 {
				noi di in red "illegal family argument"
				exit 198
			}
			if `fcode' == 2 {
				capture confirm integer number `farg'
				if _rc {
					noi di in red /*
				*/ "Binomial argument must be integer"
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
		noi di in red "Unknown family function"
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

program define FixBeta
        local beta "`1'"

        local nc = colsof(`beta')
        local nc1 = `nc'-1
        mat `beta' = `beta'[1,`nc'], `beta'[1,1..`nc1']
end

program define ChkReps
        args touse
        local neq = $S_WL1
        local i 2
        local ip1 = `neq'+1
        local kmin = 1e300
        while `i' <= `ip1' {
                local k : word count ${S_WL`i'}
                if `k' < `kmin' {
                        local kmin = `k'
                }
                local i = `i'+1
        }
        local cmp ""
        local i 2
        while `i' <= `ip1' {
                tempvar miss`i'
                local eval "0"
                local j 1
                local tp 1
                while `j' <= `kmin' {
                        local v`j' : word `j' of ${S_WL`i'}
                        local eval "`eval'+`tp'*(`v`j''==.)"
                        local j = `j'+1
                        local tp = `tp'*2
                }
                qui gen `miss`i'' = `eval'
                qui replace `touse' = 0 if `miss`i'' != `miss2'
                local i = `i'+1
        }

        local i 2
        while `i' <= `ip1' {
                local nk : word count ${S_WL`i'}
                if `nk' > `kmin' {
                        local lst ""
                        local j 1
                        while `j' <= `kmin' {
                                local xx : word `j' of ${S_WL`i'}
                                local lst "`lst'`xx' "
                                local j = `j'+1
                        }
                        while `j' <= `nk' {
                                local xx : word `j' of ${S_WL`i'}
                                noi di as res "`xx'" as txt /*
                                */ " (replication var) dropped"
                                local j = `j'+1
                        }
                        global S_WL`i' "`lst'"
                }
                local i= `i'+1
        }
end


program define qvfmex, plugin
