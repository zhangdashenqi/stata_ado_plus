capture program drop margin_e
program define margin_e , rclass
*! Subroutine used by margin.ado
*! This version: 28 October 2004 - Author: Tamas Bartus

	version 8
	syntax [varlist] [, eform table dummies(string) count nooffset trace /*
						*/ mopt(string) Weight(varname) hascons mean ]

	if "`weight'"!="" { l
		local weight [fw=`weight']
	}
	if "`dummies'"!="" {
		DumList `dummies'
	}
	if "`s(error)'"!="" {
		di in r "`s(error)' which is included in the -dummy - option does not exist"
		exit
	}


*=======================================
*
*  [1]: PROCESSING ESTIMATION RESULTS
*
*=======================================

	tempname b vce coef pder partder bm Vm
	tempvar touse
	local cmd    = e(cmd)
	local numobs = e(N)
	qui gen byte `touse' = e(sample)

	if "`trace'"!="" {
		di as text "Computations begin...."
	}
	ProcEst`s(type)' `s(model)'

	if "`trace'"!="" {
		di as text "Coefficient matrix obtained, Variance-covariance matrix modified for later computations"
	}

	mat `b' = r(b)
 	mat `coef' = r(coef)
	mat `vce'  = r(v)
	local Vdim = colsof(`vce')

	* ADDING CONSTANTS / CUT-OFFS TO DATA
	local i = 1
	while `i'<=`s(ncons)' {
		tempvar c`i'
		qui gen byte `c`i'' = 1
		local clist `clist' `c`i''
		local i = `i'+1
	}
	PassToS	`clist'

	if "`mean'"!="" {
		local n : word count `s(rhs)'
		local i = 1
		while `i'<`n' {
			tempvar temp
			local term : word `i' of `s(rhs)'
			qui egen `temp' = mean(`term') if `touse'
			qui replace `term' = `temp'
			drop `temp'
			local i = `i'+1
		}
		* qui drop if `touse'==0
		* keep in 1
		* local weight = `numobs'
	}
		 
*=======================================
*
* [2]: PREDICTING INDEX
*	DEFINING CDF, PDF, AND THE DERIVATIVE OF PDF
*
*=======================================


	if "`s(model)'"=="mlogit" {
		local denom 1
	}
   	local i = 1
	while `i'<=`s(neq)' {
		if `s(neq)'>1 {
			local Popt "eq(#`i')"
		}
		tempvar xb`i'
		matrix score `xb`i'' = `b' if `touse' , `Popt'
		Mindex `i' `xb`i''
		if "`s(model)'"=="mlogit" {
			local denom "`denom'+exp(`xb`i'')"
		}
		local i = `i'+1
	}
	if "`s(model)'"=="mlogit" {
		local mopt `denom'
	}

	if `s(type)'==9 {
		local exe eform
	}
	else local exe `s(model)'
	
	GenFx_`exe' `s(depvar)' `mopt'

	if "`s(error)'"!="" {
		di as error "-margin- cannot estimate the requested marginal effects"
		di as error "The problem: `s(error)'"
		exit
	}
	if "`trace'"!="" {
		di as text "Linear predictions calculated, cumulative distribution functions defined"
	}


*=======================================
*
*  [3]: DOING THE CALCULATIONS
*
*=======================================


	local dim  = `s(Ntreat)'*`s(nout)'
	local col  = 0
*	mat  `bm'  = J(1,`dim',0)
	tempname ms	me
	mat `ms' = J(`dim',4,0)


	* Loop for outcomes
	local j = 1
	while `j'<=`s(nout)' {
		local eqname : word `j' of `s(eqname)'

		* Loop for variables
		
		local i = 1
		while `i'<=`s(Ntreat)' {
			local col = `col'+1
			local treat : word `i' of `s(Tlist)'
		*	local names "`names' `treat'"
		*	if `s(nout)'>1 {
		*		local term : word `j' of `s(eqname)'
		*		local neweq "`neweq' `term'"
		*	}
			
			if "`mean'"!="" {
				local vtype Contin
			}
			else {
				capture assert `treat'==1 | `treat'==0 if `touse'
				if _rc==0 {
					local vtype Dummy
				}
				else local vtype Contin
			}
			if "`count'"!="" & "`vtype'"=="Contin" {
				capture assert mod(`treat',int(`treat'))==0	if `touse'
				if _rc==0 {
					local vtype Count
					local delta = 1
				}
			}
			if "`vtype'"=="Contin" {
				qui sum `treat' , detail
				if r(p95)==r(p5) {
					local delta = 10^(-6)*(r(max)-r(min))	
				}
				else local delta = 10^(-6)*(r(p95)-r(p5))
			}
*			qui Calculate `treat' `touse' `numobs' `i' `j' `coef' `Vdim' `vtype' `delta' `weight'
			qui GetMargEff_`vtype' `treat' `touse' `numobs' `i' `j' `coef' `Vdim' `delta' `weight'  

			* Tracing the computations:
			mat `ms'[`col',1] = r(me)
			mat `ms'[`col',2] = r(sd)
			mat `ms'[`col',3] = r(min)
			mat `ms'[`col',4] = r(max)

			* local me   = r(me)
			mat `me'   = r(me)
			mat `pder' = r(pder)
			mat colnames `me'   = `treat'
			mat colnames `pder' = `treat' _cons
			mat rownames `pder' = `treat'
			if `s(nout)'>1 {
				mat coleq `me'   =  `eqname'
				mat coleq `pder' =  `eqname'
				mat roweq `pder' =  `eqname'
			}
			
			if `i'==1  & `j'==1 {
				mat `bm' = `me'
				mat `partder' = `pder'
			}
			else {
				mat `bm' = `bm' , `me'
				mat `partder' = `partder' \ `pder'
			}
			local i = `i'+1
		}
		* End of loop for variables
		
		* CONSTANT TERM
		if "`hascons'"!="" {
			mat `me' = `s(consb`j'1)'
			mat `pder' = 0*`pder'
			local pos = `Ntreat'+1
			mat `pder'[1,`pos']= `s(conse`j'1)'
			mat colnames `me'   = _cons
			mat colnames `pder' = `treat' _cons
			mat rownames `pder' = _cons
			if `s(nout)'>1 {
				mat coleq `me'   =  `eqname'
				mat coleq `pder' =  `eqname'
				mat roweq `pder' =  `eqname'
			}
			mat `bm' = `bm' , `me'
			mat `partder' = `partder' \ `pder'
		}
		local j = `j'+1
	}

	if "`trace'"!="" {
		di as text "Marginal effects and standard errors estimated"
	}
	
	mat `Vm' = `partder'*`vce'
	mat `Vm' = `Vm'*`partder''
/*
	mat colnames `bm' = `names' `consname'
	mat rownames `Vm' = `names'
	mat colnames `Vm' = `names'
	mat coleq    `bm' = `neweq'
	mat coleq    `Vm' = `neweq'
	mat roweq    `Vm' = `neweq'
  */
	mat rownames `ms' = `names'
	mat roweq    `ms' = `neweq'
	mat colnames `ms' = Mean SD Min Max
	return matrix margin_tab `ms'

	return mat margin_b `bm'
	return mat margin_V `Vm'
	return local margin_title `s(Title)'
	return local margin_depv  `s(depname)'
	return local margin_cmd   `cmd'
	* sret clear
end



*============================================================
*
* [4] MARGINAL EFFECTS + STANDARD ERRORS
*
*============================================================


program define GetMargEff_Dummy , rclass
	version 8
	args treat touse numobs id out mat Vdim	delta weight
	tempvar hat0 hat1
	tempname row pder
	mat `pder' = J(1,`Vdim',0)
	if "`weight'"!="" {
		local w [fw=`weight']
	}

	nobreak {

	* BACKUP FOR LINEAR PREDICTION
	* SETTING DUMMIES TO ZERO
		local q = 1
		while `q'<=`s(neq)' {
			local beta = `mat'[`id',`q']
			tempvar save`q'
			gen double `save`q'' = `s(xb`q')'
			replace `s(xb`q')' = `s(xb`q')'-`beta'*(`treat'==1)
			local q = `q'+1
		}
	* CALCULATING THE CDF + DENSITIES
		gen double `hat0' = `s(cumu`out'1)'
		local q = 1
		while `q'<=`s(neq)' {
			tempvar phi0`q'
			if "`s(dens`out'`q')'"=="" {
				gen byte `phi0`q'' = 0
			}
			else gen double `phi0`q'' = `s(dens`out'`q')' `s(`treat')'
			local q = `q'+1
		}
	*  SETTING DUMMIES TO 1
		local q = 1
		while `q'<=`s(neq)' {
			local beta = `mat'[`id',`q']
			replace `s(xb`q')' = `s(xb`q')'+`beta'
			local q = `q'+1
		}
	* CALCULATING THE CDF + DENSITIES
		gen double `hat1' = `s(cumu`out'1)'
		local q = 1
		while `q'<=`s(neq)' {
			tempvar phi1`q'
			if "`s(dens`out'`q')'"=="" {
				gen byte `phi1`q'' = 0
			}
			else gen double `phi1`q'' = `s(dens`out'`q')' `s(`treat')'
			local q = `q'+1
		}
	* CALCULATING STANDARD ERRORS
	* RESTORING INDEX
		local q = 1
		while `q'<=`s(neq)' {
			local beta = `mat'[`id',`q']
			tempvar part`q'
			gen double `part`q'' = (`phi1`q''-`phi0`q'')
			if "``s(`treat')'"!="" {
				replace `part`q'' = 0 if `part`q''==. & `touse'==1
			}
			replace `s(xb`q')' = `save`q''
		* The i-th row of the part. deriv. matrix
			su `phi1`q'' `w'
			local add = r(mean)
			tempname row`q'
			mat vecaccum `row`q'' = `part`q'' `s(rhs)' `w' if `touse' , noconstant
			mat list `row`q''
			mat `row`q'' = `row`q'' / `numobs'
			mat `row`q''[1,`id'] = `add'
			if `q'==1 {
				mat `pder' = `row`q''
			}
			else mat `pder' = `pder' , `row`q''
			local q = `q'+1
		}
		
	} /* end of nobreak */

	* MARGINAL EFFECT / RETURNING RESULTS
	replace `hat1' = (`hat1'-`hat0')
	sum `hat1' `s(`treat')' `w'
	return scalar me = r(mean)
	return scalar sd = r(sd)
	return scalar min = r(min)
	return scalar max = r(max)
	return matrix pder `pder'
end


program define GetMargEff_Contin , rclass
	version 8
	args treat touse numobs id out mat Vdim	delta weight 
	tempvar hat0 hat1
	tempname row pder
	mat `pder' = J(1,`Vdim',0)
	if "`weight'"!="" {
		local w [fw=`weight']
	}

	nobreak {

		gen double `hat0' = 0
		local dmin = 10^6
		
	* CALCULATING THE CDF + DENSITIES
	* CORRECTION FOR SMALL CHANGE TERM
		local q = 1
		while `q'<=`s(neq)' {
			local beta = `mat'[`id',`q']
			if `beta'<`dmin' & `beta'!=0  {
				local dmin = `beta'
			}
			tempvar save`q'	phi0`q'
			gen double `save`q'' = `s(xb`q')'
			if "`s(dens`out'`q')'"=="" {
				gen byte `phi0`q'' = 0
			}
			else {
				replace `hat0' = `hat0' + `s(dens`out'`q')'*`beta'	
				gen double `phi0`q'' = `s(dens`out'`q')' `s(`treat')'
			}
			local q = `q'+1
		}
		local delta = `delta'/abs(`dmin')
	*  SETTING DUMMIES TO 1 / INCREASING VALUE OF CONTINUOUS VARS
		local q = 1
		while `q'<=`s(neq)' {
			local beta = `mat'[`id',`q']
			replace `s(xb`q')' = `s(xb`q')'+`beta'*`delta'
			local q = `q'+1
		}
	* CALCULATING DENSITIES
		local q = 1
		while `q'<=`s(neq)' {
			tempvar phi1`q'
			if "`s(dens`out'`q')'"=="" {
				gen byte `phi1`q'' = 0
			}
			else gen double `phi1`q'' = `s(dens`out'`q')' `s(`treat')'
			local q = `q'+1
		}
	* CALCULATING STANDARD ERRORS
	* RESTORING INDEX
		local q = 1
		while `q'<=`s(neq)' {
			local beta = `mat'[`id',`q']
			tempvar part`q'
			gen double `part`q'' = (`phi1`q''-`phi0`q'')/`delta'
			if "``s(`treat')'"!="" {
				replace `part`q'' = 0 if `part`q''==. & `touse'==1
			}
			replace `s(xb`q')' = `save`q''
		* The i-th row of the part. deriv. matrix
			su `phi1`q'' `w'
			local add = r(mean)
			tempname row`q'
			mat vecaccum `row`q'' = `part`q'' `s(rhs)' `w' if `touse' , noconstant
			mat list `row`q''
			mat `row`q'' = `row`q'' / `numobs'
			mat `row`q''[1,`id'] = `row`q''[1,`id'] + `add'
			if `q'==1 {
				mat `pder' = `row`q''
			}
			else mat `pder' = `pder' , `row`q''
			local q = `q'+1
		}
		
	} /* end of nobreak */

	* MARGINAL EFFECT / RETURNING RESULTS
	sum `hat0' `s(`treat')' `w'
	return scalar me = r(mean)
	return scalar sd = r(sd)
	return scalar min = r(min)
	return scalar max = r(max)
	return matrix pder `pder'
end



program define GetMargEff_Count , rclass
	version 8
	args treat touse numobs id out mat Vdim	delta weight 
	tempvar hat0 hat1
	tempname row pder
	mat `pder' = J(1,`Vdim',0)
	if "`weight'"!="" {
		local w [fw=`weight']
	}

	nobreak {

	* BACKUP FOR LINEAR PREDICTION
		local q = 1
		while `q'<=`s(neq)' {
			tempvar save`q'
			gen double `save`q'' = `s(xb`q')'
			local q = `q'+1
		}
	* CALCULATING THE CDF + DENSITIES
		gen double `hat0' = `s(cumu`out'1)'
		local q = 1
		while `q'<=`s(neq)' {
			tempvar phi0`q'
			if "`s(dens`out'`q')'"=="" {
				gen byte `phi0`q'' = 0
			}
			else gen double `phi0`q'' = `s(dens`out'`q')' `s(`treat')'
			local q = `q'+1
		}
	*  INCREASING VALUE OF COUNT VARS
		local q = 1
		while `q'<=`s(neq)' {
			local beta = `mat'[`id',`q']
			replace `s(xb`q')' = `s(xb`q')'+`beta'*`delta'
			local q = `q'+1
		}
	* CALCULATING THE CDF + DENSITIES
		gen double `hat1' = `s(cumu`out'1)'
		local q = 1
		while `q'<=`s(neq)' {
			tempvar phi1`q'
			if "`s(dens`out'`q')'"=="" {
				gen byte `phi1`q'' = 0
			}
			else gen double `phi1`q'' = `s(dens`out'`q')' `s(`treat')'
			local q = `q'+1
		}
	* CALCULATING STANDARD ERRORS
	* RESTORING INDEX
		local q = 1
		while `q'<=`s(neq)' {
			local beta = `mat'[`id',`q']
			tempvar part`q'
			gen double `part`q'' = (`phi1`q''-`phi0`q'')/(`delta')
			if "``s(`treat')'"!="" {
				replace `part`q'' = 0 if `part`q''==. & `touse'==1
			}
			replace `s(xb`q')' = `save`q''
		* The i-th row of the part. deriv. matrix
			su `phi1`q'' `w'
			local add = r(mean)
			tempname row`q'
			mat vecaccum `row`q'' = `part`q'' `s(rhs)' `w' if `touse' , noconstant
			mat list `row`q''
			mat `row`q'' = `row`q'' / `numobs'
			mat `row`q''[1,`id'] = `row`q''[1,`id'] + `add'
			if `q'==1 {
				mat `pder' = `row`q''
			}
			else mat `pder' = `pder' , `row`q''
			local q = `q'+1
		}
		
	} /* end of nobreak */

	* MARGINAL EFFECT / RETURNING RESULTS
	replace `hat1' = (`hat1'-`hat0')/(`delta')
	sum `hat1' `s(`treat')' `w'
	return scalar me = r(mean)
	return scalar sd = r(sd)
	return scalar min = r(min)
	return scalar max = r(max)
	return matrix pder `pder'
end


***********************************


program define Calculate , rclass
	version 8
	args treat touse numobs id out mat Vdim	vtype weight
	tempvar hat0 hat1
	tempname row pder delta
	scalar `delta' = `change'
	mat `pder' = J(1,`Vdim',0)
	if "`weight'"!="" {
		local w [fw=`weight']
	}

	nobreak {

	* BACKUP FOR LINEAR PREDICTION
	* SETTING DUMMIES TO ZERO / LEAVING CONTINUOUS VARS AS THEY ARE
	* CORRECTION FOR SMALL CHANGE TERM
		local dmin = 10^6
		local q = 1
		while `q'<=`s(neq)' {
			local beta = `mat'[`id',`q']
			if `beta'<`dmin' & `beta'!=0  {
				local dmin = `beta'
			}
			tempvar save`q'
			gen double `save`q'' = `s(xb`q')'
			if `vtype'==1 {
				replace `s(xb`q')' = `s(xb`q')'-`beta'*(`treat'==1)
			}
			local q = `q'+1
		}
		scalar `delta' = `delta'/abs(`dmin')
	* CALCULATING THE CDF + DENSITIES
		gen double `hat0' = `s(cumu`out'1)'
		local q = 1
		while `q'<=`s(neq)' {
			tempvar phi0`q'
			if "`s(dens`out'`q')'"=="" {
				gen byte `phi0`q'' = 0
			}
			else gen double `phi0`q'' = `s(dens`out'`q')' `s(`treat')'
			local q = `q'+1
		}
	*  SETTING DUMMIES TO 1 / INCREASING VALUE OF CONTINUOUS VARS
		local q = 1
		while `q'<=`s(neq)' {
			local beta = `mat'[`id',`q']
			replace `s(xb`q')' = `s(xb`q')'+`beta'*(`vtype'==1)+`beta'*(`vtype'==0)*`delta'
			local q = `q'+1
		}
	* CALCULATING THE CDF + DENSITIES
		gen double `hat1' = `s(cumu`out'1)'
		local q = 1
		while `q'<=`s(neq)' {
			tempvar phi1`q'
			if "`s(dens`out'`q')'"=="" {
				gen byte `phi1`q'' = 0
			}
			else gen double `phi1`q'' = `s(dens`out'`q')' `s(`treat')'
			local q = `q'+1
		}
	* CALCULATING STANDARD ERRORS
	* RESTORING INDEX FOR DUMMIES & COUNTS
		local q = 1
		while `q'<=`s(neq)' {
			local beta = `mat'[`id',`q']
			tempvar part`q'
			gen double `part`q'' = (`phi1`q''-`phi0`q'')/(`delta'^(`vtype'==0))
			if "``s(`treat')'"!="" {
				replace `part`q'' = 0 if `part`q''==. & `touse'==1
			}
			replace `s(xb`q')' = `save`q''
		* The i-th row of the part. deriv. matrix
			su `phi1`q'' `w'
			local add = r(mean)
			tempname row`q'
			mat vecaccum `row`q'' = `part`q'' `s(rhs)' `w' if `touse' , noconstant
			mat list `row`q''
			mat `row`q'' = `row`q'' / `numobs'
			if `vtype'==1 {
				mat `row`q''[1,`id'] = `add'
			}
			else  mat `row`q''[1,`id'] = `row`q''[1,`id'] + `add'
			if `q'==1 {
				mat `pder' = `row`q''
			}
			else mat `pder' = `pder' , `row`q''
			local q = `q'+1
		}
		
	} /* end of nobreak */

	* MARGINAL EFFECT / RETURNING RESULTS
	replace `hat1' = (`hat1'-`hat0')/(`delta'^(`vtype'==0))
	sum `hat1' `s(`treat')' `w'
	return scalar me = r(mean)
	return scalar sd = r(sd)
	return scalar min = r(min)
	return scalar max = r(max)
	return matrix pder `pder'
end


*============================================================
*
*	[5] PROGRAMS PREDICTING CDF, DENSITY, AND DERIVATIVES
*
*============================================================


program define GenFx_eform , sclass
	EqLabel `1'
	sret local Title E(exp[xb])
	sret local depname `s(depvar)'
	sret local eqname  `1'
	sret local cumu11  exp(`s(xb1)')
	sret local dens11  exp(`s(xb1)')
	sret local consb11 = exp(_b[_cons])
	sret local conse11 = exp(_b[_cons])
end

program define GenFx_logit , sclass
	version 8
	args depvar rho
	if "`rho'"=="" {
		local rho = 1
	}
	local cumu11 "1/(1+exp(-`rho'*`s(xb1)'))"
	sret local cumu11 `cumu11'
	sret local dens11 " `rho'*(`cumu11')*(1-`cumu11')"
	local consb11 = 1/(1+exp(-`rho'*_b[_cons]))
	sret local consb11 = `consb11'
*	sret local conss11 = exp(-`rho'*(_se[_cons])^2)/((1+exp(-`rho'*(_se[_cons])^2))^2)
	sret local conse11 = `rho'*(`consb11')*(1-`consb11')
	EqLabel `depvar'
	sret local Title Prob(`depvar'==`s(cat)')
	sret local depname `depvar'
	sret local eqname `depvar'
end

program define GenFx_logistic
	GenFx_logit `*'
end

program define GenFx_xtlogit , sclass
	version 8
	if e(predict)=="xtbin_p" {
		local rho = sqrt(1-`e(rho)')
		GenFx_logit `*' `rho'
	}
	else {
		sret local error "the population-averaged version of xtlogit not supported"
		exit
	}
end


program define GenFx_probit , sclass
	version 8
	args depvar rho
	if "`rho'"=="" {
		local rho 1
	}
	sret local cumu11 "normprob(`rho'*`s(xb1)')"
	sret local dens11 " `rho'*normd(`rho'*`s(xb1)') "
	sret local consb11 "normprob(`rho'*_b[_cons])"
	sret local conse11 " `rho'*normd(`rho'*_b[_cons]) "
	EqLabel `depvar'
	sret local Title "Prob(`depvar'==`s(cat)')"
	sret local depname `depvar'
	sret local eqname `depvar'
end


program define GenFx_xtprobit , sclass
	if e(predict)=="xtbin_p" {
		local rho = sqrt(1-`e(rho)')
		GenFx_probit `*' `rho'
	}
	else {
		sret local error "the population-averaged version of xtlogit not supported"
		exit
	}
end


program define GenFx_cloglog , sclass
	local depvar "`1'"
	local cumu11 " 1-exp(-exp(`s(xb1)')) "
	local dens11 " -(1-`cumu11')*exp(`s(xb1)') "
	sret local cumu11 `cumu11'
	sret local dens11 `dens11'
	EqLabel `s(depvar)'
	sret local Title "Prob(`s(depvar)'==`s(cat)')"
	sret local depname `depvar'
	sret local eqname `depvar'
end

program define GenFx_oprobit , sclass
	version 8
	args depvar
	tempname matcat
	mat `matcat' = e(cat)
	local kcat = e(k_cat)
	sret local cumu11 " 1-normprob(`s(xb1)'-_b[_cut1])"
	sret local dens11 "-normd(`s(xb1)'-_b[_cut1])"
	local cat = `matcat'[1,1]
	EqLabel `s(depvar)' `cat'
	local i = 2
	while `i'<=`s(nout)' {
		local j = `i'-1
		sret local cumu`i'1 "normprob(_b[_cut`i']-`s(xb1)')-normprob(_b[_cut`j']-`s(xb1)')"
		sret local dens`i'1 "normd(_b[_cut`j']-`s(xb1)')-normd(_b[_cut`i']-`s(xb1)')"
		local cat = `matcat'[1,`i']
		EqLabel `e(depvar)' `cat'
		local i = `i'+1
	}
	local j = `s(nout)'-1
	sret local cumu`s(nout)'1 "normprob(`s(xb1)'-_b[_cut`j'])"
	sret local dens`s(nout)'1 "normd(`s(xb1)'-_b[_cut`j'])"
	local cat = `matcat'[1,`s(nout)']
	EqLabel `depvar' `cat'
	sret local Title Prob(`depvar')
	sret local depname `depvar'
end


program define GenFx_ologit , sclass
	version 8
	args depvar
	tempname matcat b
	mat `matcat' = e(cat)
	sret local cumu11 "1/(1+exp(-_b[_cut1]+`s(xb1)'))"
	sret local dens11 "-exp(_b[_cut1]-`s(xb1)')/((1+exp(_b[_cut1]-`s(xb1)'))^2)"
	local cat = `matcat'[1,1]
	EqLabel `depvar' `cat'
	local i = 2
	while `i'<=`s(nout)' {
		local j = `i'-1
		sret local cumu`i'1 "1/(1+exp(_b[_cut`i']+`s(xb1)'))-1/(1+exp(-_b[_cut`j']+`s(xb1)'))"
		sret local dens`i'1 "exp(_b[_cut`j']-`s(xb1)')/((1+exp(_b[_cut`j']-`s(xb1)'))^2)-exp(_b[_cut`i']-`s(xb1)')/((1+exp(_b[_cut`i']-`s(xb1)'))^2)"
		local cat = `matcat'[1,`i']
		EqLabel `depvar' `cat'
		local i = `i'+1
	}
	local j = `s(nout)'-1
	sret local cumu`s(nout)'1 "1/(1+exp(_b[_cut`j']-`s(xb1)'))"
	sret local dens`s(nout)'1 "exp(`s(xb1)'-_b[_cut`j'])/((1+exp(`s(xb1)'-_b[_cut`j']))^2)"
	local cat = `matcat'[1,`s(nout)']
	EqLabel `depvar' `cat'
	sret local Title Prob(`depvar')
	sret local depname `depvar'
end


program define GenFx_gologit , sclass
	version 8
	args depvar
	tempvar group
	qui egen `group' = group(`s(depvar)')
	local i = 1
	while `i'<=`s(nout)' {
		local j = `i'-1
		if `i'==1 {
			sret local cumu`i'1 " 1/(1+exp(`s(xb`i')')) "
			sret local dens`i'`i' " -exp(-`s(xb`i')')/((1+exp(-`s(xb`i')'))^2) "
		}
		if `i'>1 & `i'<`s(nout)' {
			sret local cumu`i'1 " 1/(1+exp(`s(xb`i')'))-1/(1+exp(`s(xb`j')'))"
			sret local dens`i'`j' " exp(-`s(xb`j')')/((1+exp(-`s(xb`j')'))^2)"
			sret local dens`i'`i' "-exp(-`s(xb`i')')/((1+exp(-`s(xb`i')'))^2)"
		}
		if `i'==`s(nout)' {
			sret local cumu`i'1 "1/(1+exp(-`s(xb`j')'))"
			sret local dens`i'`j' " exp(`s(xb`j')')/((1+exp(`s(xb`j')'))^2)"
		}
		qui sum `depvar' if `group'==`i'
		local cat = r(mean)
		EqLabel `depvar' `cat'
		local i = `i'+1
	}
	sret local Title Prob(`depvar')
	sret local depname `depvar'
end


program define GenFx_mlogit , sclass
	version 8
	args depvar denom
	tempname matcat
	mat `matcat' = e(cat)
	local base = e(ibasecat)
	local i = 1
	while `i'<=`s(nout)' {
		if `i'==`base' {
			local prob`i' "1/(`denom')"
		}
		else if `i'<`base' {
			local prob`i' "exp(`s(xb`i')')/(`denom')"
		}
		else if `i'>`base'{
			local j = `i'-1
			local prob`i' "exp(`s(xb`j')')/(`denom')"
		}
		local i = `i'+1
	}
	local i = 1
	while `i'<=`s(nout)' {
		if `i'>=`base' {
			local j = `i'-1
		}
		else local j = `i'
		sret local cumu`i'1 "`prob`i''"
		local q = 1
		while `q'<=`s(neq)' {
			if `i'!=`base' & `q'==`j' {
				local dens`i'`q' "(`prob`i'')*(1-(`prob`i''))"
			}
			else  local dens`i'`q' "-(`prob`i'')*(`prob`q'')" 
			sret local dens`i'`q' `dens`i'`q''
			local q = `q'+1
		}
		local cat = `matcat'[1,`i']
		EqLabel `depvar' `cat'
		local i = `i'+1
	}
	sret local Title Prob(`depvar')
	sret local depname `depvar'
end


program define GenFx_poisson , sclass
	version 8
	GenFx_eform	`*'
	sret local Title E(`s(depname)')
end


program define GenFx_nbreg , sclass
	version 8
	GenFx_poisson `*'
end


program define GenFx_zip , sclass
	version 8
	args depvar
	local mu "exp(`s(xb1)')"
	if "`e(inflate)'"=="logit" {
		local cuminf "1/(1+exp(-`s(xb2)'))"
		local deninf "(`cuminf')*(1-`cuminf')"
	}
	else {
		local cuminf "normprob(`s(xb2)')"
		local deninf "normd(`s(xb2)')"
	}
	sret local cumu11 "`mu'*(1-`cuminf')"
	sret local dens11 "`mu'*(1-`cuminf')"
	sret local dens12 "-`mu'*`deninf'"
	sret local cumu21 "`mu'"
	sret local dens21 "`mu'"
	sret local dens22 ""
	sret local cumu31 "(1-`cuminf')"
	sret local dens31 ""
	sret local dens32 "-`deninf'"
   	sret local eqname y ycond  pcond
	sret local depname `depvar'
	sret local Title Prob(`depvar')
end

program define GenFx_zinb, sclass
	version 8
	GenFx_zip `*'
end


program define GenFx_biprobit , sclass
	version 8
	args v1 v2 bit
	local rho = e(rho)
	local srh = sqrt(1-`rho'^2)
	local k = 1
	while `k'<=`s(nout)' {
		local A
		local C 
		local B 
		if `k'>2  {
			local A -
		}
		if `k'==2 | `k'==4 {
			local B -
		}
		if `k'==2 | `k'==3 {
			local C -
		}
		sret local cumu`k'1  binorm(`A'`s(xb1)',`B'`s(xb2)',`C'`rho')
		sret local dens`k'1  normd(`A'`s(xb1)')*normprob((`B'`s(xb2)'-`C'`rho'*`A'`s(xb1)')/`srh')
		sret local dens`k'2  normd(`B'`s(xb2)')*normprob((`A'`s(xb1)'-`C'`rho'*`B'`s(xb2)')/`srh')
		local k = `k'+1
	}
	sret local eqname "p11 p10 p01 p00"
	sret local Title "Prob(`v1',`v2')"
end


program define GenFx_tobit , sclass
	version 8
	args depvar
	local sig = _b[_se]
	local ul = e(ulopt)
	local ll = e(llopt)
	if `ul'==. {
		local ul = 0
	}
	if `ll'==. {
		local ll = 0
	}
	if `ll'==0 {
		local vll = -10000
	}
	else local vll  (`ll'-`s(xb1)')/`sig'
	if `ul'==0 {
		local vul = 10000
	}
	else local vul  (`ul'-`s(xb1)')/`sig'
	GenFx_Censor , depvar(`depvar') ul(`ul') vul(`vul') ll(`ll') vll(`vll') sig(`sig')
end

program define GenFx_cnreg , sclass
	version 8
	args depvar
	local censor = e(censored)
	local sig = _b[_se]
	local  ll "(`censor'*`depvar')"
	local  ul "(`censor'*`depvar')"
	local vll "(`censor'*( `ll'-`s(xb1)')/`sig'+(1-`censor')*(-10000))"
	local vul "(`censor'*(`ull'-`s(xb1)')/`sig'+(1-`censor')*( 10000))"
	GenFx_Censor , depvar(`depvar') ul(`ul') vul(`vul') ll(`ll') vll(`vll') sig(`sig')
end

program define GenFx_intreg , sclass
	version 8
	args left right
	local sig = e(sigma)
	local censor "(`left'!=`right')"
	local  ll "(`censor'*`left')"
	local  ul "(`censor'*`right')"
	local vll "(`censor'*( `ll'-`s(xb1)')/`sig'+(1-`censor')*(-10000))"
	local vul "(`censor'*(`ull'-`s(xb1)')/`sig'+(1-`censor')*( 10000))"
	GenFx_Censor , depvar(`left' `right') ul(`ul') vul(`vul') ll(`ll') vll(`vll') sig(`sig')
end

program define GenFx_Censor , sclass
	version 8
	syntax [, depvar(string) ll(string) ul(string) vll(string) vul(string) sig(real 0)]
	local cumu11 "`ll'*normprob(`vll')+`ul'*normprob(-`vul')"
	local cumu11 "`cumu11' + (normprob(`vul')-normprob(`vll'))*`s(xb1)'"
	local cumu11 "`cumu11' + `sig'*(normd(`vll')-normd(`vul'))"
	sret local cumu11 `cumu11'
	sret local dens11 "normprob(`vul')-normprob(`vll')"
	sret local Title "E(`depvar'|`depvar' observed)"
	local depvar : word 1 of `depvar'
	sret local depname `depvar'
end

program define GenFx_truncreg , sclass
	version 8
	args v1
	local sig = `e(sigma)'
	local ul = e(ulopt)
	local ll = e(llopt)
	if `ll'==. {
		local vll = -10000
	}
	else local vll  (`ll'-`s(xb1)')/`sig'
	if `ul'==. {
		local vul = 10000
	}
	else local vul  (`ul'-`s(xb1)')/`sig'
	local mills  "(normd(`vll')-normd(`vul'))/(normprob(`vul')-normprob(`vll')) "
	sret local cumu11 "`s(xb1)'+`sig'*`mills'"
	sret local dens11 "1+`mills'-(`mills')^2"
	sret local Title "E(`v1'|`v1' observed)"
	sret local depname `v1'
end


program define GenFx_heckman , sclass
	version 8
	args v1 v2
	local sig = `e(sigma)'*`e(rho)'
	local mills  "normd(`s(xb2)')/normprob(`s(xb2)') "
	sret local cumu11 "`s(xb1)'+`sig'*`mills'"
	sret local dens11 "1"
	sret local dens12 "-`sig'*(`s(xb2)'*(`mills')+(`mills')^2 )"
	if "`v2'"=="select" {
		sret local Title "E(`v1'|`v1' observed)"
	}
	else sret local Title "E(`v1'|`v2'==1)"
	sret local depname `v1'
end


program define GenFx_heckprob , sclass
	args v1 v2
	local rho = e(rho)
	local srh = sqrt(1-`rho'^2)
	* local dbvn# = deriative of Bivariate Normal Density w.r.t. eq. #
	local expr1 "(`s(xb2)'-`rho'*`s(xb1)')/`srh'"
	local expr2 "(`s(xb1)'-`rho'*`s(xb2)')/`srh'"
	local dbvn1 "(normd(`s(xb1)')*normprob(`expr1'))"
	local dbvn2 "(normd(`s(xb2)')*normprob(`expr2'))"
	local cumu11 "binorm(`s(xb1)',`s(xb2)',`rho')/normprob(`s(xb2)')"
	sret local cumu11 `cumu11'
	sret local dens11 "`dbvn1'/normprob(`s(xb2)')"
	sret local dens12 "`dbvn2'/normprob(`s(xb2)')-(`cumu11')*normd(`s(xb2)')/normprob(`s(xb2)')"
	if "`v2'"=="select" {
		sret local Title "Prob(`v1'==1|`v1' observed)"
	}
	else sret local Title "Prob(`v1'==1|`v2'==1)"
	sret local depname `v1'
end



*============================================================
*
*	[6] SUBROUTINES THAT PROCESS ESTIMATION RESULTS
*
*============================================================


program define PassToS , sclass
	version 8
	local rhs `*'
	local Tlist `r(treat)'
	local ntreat : word count `Tlist'
	sret local depvar `r(depvar)'
	sret local rhs `Tlist' `rhs'
	sret local Tlist `r(treat)'
	sret local Ntreat `ntreat'
end


program define ProcEst1 , rclass
	version 8
sret list
	tempname b v coef
	local depvar = e(depvar)
	mat `b' = e(b)
	mat `v' = e(V)
	local dim = colsof(`b')-`s(nap)'
	mat `v' = `v'[1..`dim',1..`dim']
	mat `b' = `b'[1,1..`dim']
	local dim = `dim'-1 /* -1 is the constant */
	mat `coef' = `b'[1,1..`dim']
	local treat : colnames(`coef')
	mat `coef' = `coef''
	return local treat `treat'
	return local depvar `e(depvar)'
	return matrix b `b'
	return matrix coef `coef'
	return matrix v `v'
end

 	
program define ProcEst2 , rclass
	version 8
	tempname b v coef temp
	mat `b' = e(b)
	mat `v' = e(V)
	if substr("`s(model)'",1,1)=="o" {
		local dim = colsof(`b')-`s(ncons)'
		mat `b' = `b'[1,1..`dim']
	}
	else if substr("`s(model)'",1,1)=="b" {
		local dim = colsof(`b')-`s(nap)'
		mat `b' = `b'[1,1..`dim']
		mat `v' = `v'[1..`dim',1..`dim']
	}
	else local dim = colsof(`b')/(`s(nout)'-1)-1
	local i = 1
	while `i'<=`s(neq)' {
		local p = (`i'-1)*(`dim'+1)+1
		local q = `p'+`dim'-1
		mat `temp' = `b'[1,`p'..`q']
		if `i'==1 {
			mat `coef' = `temp'
			local treat : colnames(`temp')
		}
		else  {
			mat `coef' = `coef' \ `temp'
		}
		local i = `i'+1
	}
	mat `coef' = `coef''
	return local depvar `e(depvar)'
	return local treat `treat'
	return matrix b `b'
	return matrix coef `coef'
	return matrix v `v'
end


program define ProcEst3 , rclass
	version 8
	local depvar = e(depvar)
	local v1 : word 1 of `depvar'
	local v2 : word 2 of `depvar'
	if "`v2'"=="" {
		if "`s(model)'"=="zip" | "`s(model)'"=="zinb" {
			local v2 "inflate"
		}
		else local v2 "select"
		local depvar "`depvar' `v2'"
	}	
	tempname b v b1 b2 b3 v11 v12 v21 v22 bnew vnew 
	mat `b' = e(b)
	mat `v' = e(V)
	local dim = colnumb(`b',"_cons")-1
	mat `b1' = `b'[1,1..`dim']

	mat `b2' = `b'[1,"`v2':"]
	mat `b3' = `b1'*0
	mat `v11' = `v'["`v1':","`v1':"]
	mat `v12' = `v'["`v1':","`v2':"]
	mat `v22' = `v'["`v2':","`v2':"]
	local e1 : colnames(`b1')
	local e2 : colnames(`b2')
	local n1 = colsof(`v11')
	local n2 = colsof(`v12')

	* RESHAPING THE VECTOR OF COEFFICIENTS
	local j = 1
	while `j'<=`n2' {
		local x : word `j' of `e2'
		if "`x'"!="_cons" {
			* Does the first eq contains `x' from the second eq?
			capture display _b[`v1':`x']
			 if _rc==0 {
				local dest = colnumb("`v11'","`x'")
				mat subst `b3'[1,`dest'] =  _b[`v2':`x']
			}
			else  {
				local addname `addname' `x'
				local beta = _b[`v2':`x']
				local addbeta `addbeta' `beta'
				local dim = `dim'+1
			}
		}
		local j = `j'+1
	}
	local treat `e1' `addname'
	local ntreat : word count `treat'
	mat `bnew' = J(2,`dim',0)
	mat input `b2' = (`addbeta')
	local nadd = colsof(`b2')
	mat `b3' = `b3', `b2'
	mat subst `bnew'[1,1] = `b1'
	mat subst `bnew'[2,1] = `b3'
	mat `bnew' = `bnew''
	
	* RESHAPING THE VARIANCE-COVARIANCE MATRIX

	* increasing dimension of Eq#2 parts & changing the ordering of cols therein
	local i = 1
	local moves = 0
	while `i'<=`ntreat' {
		local var : word `i' of `treat'
		local beta = `bnew'[`i',2]
		if `beta'==0  {
			local dest = (`i'-1)*(`moves'>0)  /* dest=0 as long as var contained only in Eq#2 */
			Ins0Vec `v22' `dest' `var'
			mat `v22' = `v22''
			Ins0Vec `v22' `dest' `var'
			mat `v22' = `v22''
			Ins0Vec `v12' `dest' `var'
		}
		else if `i'<`n1'  {	   /* - no modification needed if var is only in Eq#2 */
			local orig = colnumb(`v22',"`var'")
			MoveVec `v22' `orig' `i'
			mat `v22' = `v22''
			MoveVec `v22' `orig' `i'
			mat `v22' = `v22''
			MoveVec `v12' `orig' `i'
			local moves = `moves'+1
		}
		local i = `i'+1
	}
*	* Adding row zeros to matrices containing Eq#2 parts 
	
	mat `v21' = `v12''
	local i = `n1'-1
	while `i'<`ntreat' {
		local var : word `i' of `treat'
		Ins0Vec `v21' `i' `var'
		Ins0Vec `v11' `i' `var'
		mat `v11' = `v11''
		Ins0Vec `v11' `i' `var'
		mat `v11' = `v11''
		local i = `i'+1
	}

	* RETURNING RESULTS
	
	mat `v12' = `v21''
	mat `vnew' = ( `v11' , `v12' ) \ ( `v21' , `v22' )
   	return local depvar `v1' `v2'
	return local treat `treat'
	return matrix b `b'
	return matrix coef `bnew'
	return matrix v `vnew'
end


program define ProcEst9
	ProcEst1  `*'
end

program define MoveVec
	version 8
	args touse orig dest sym
	if `orig'==`dest' {
		exit
	}
	tempname mat col m1 m2 m3
	mat `mat' = `touse'
	local nrow = rowsof(`mat')
	local ncol = colsof(`mat')
	mat `col' = `mat'[1..`nrow',`orig']
	local pc1 = `dest'-1
	local pc2 = `orig'-1
	local pc3 = `orig'+1
	if `orig'<`dest' {
		local pc1 = `orig'-1
		local pc2 = `orig'+1
		local pc3 = `dest'+1
	}
	if `orig'==`ncol' & `dest'==1 {
		mat `m1' = `mat'[1..`nrow',1..`pc2']
		mat `mat' = `col', `m1'
	}
	else if `dest'==`ncol' & `orig'==1 {
		mat `m1' = `mat'[1..`nrow',2..`ncol']
		mat `mat' = `m1' , `col'
	}
	else if `orig'<`ncol' & `dest'==1 {
		mat `m2' = `mat'[1..`nrow',`dest'..`pc2']
		mat `m3' = `mat'[1..`nrow',`pc3'..`ncol']
		mat `mat' = `col', `m2', `m3'
	}
	else if `dest'<`ncol' & `orig'==1 {
		mat `m2' = `mat'[1..`nrow',`pc2'..`dest']
		mat `m3' = `mat'[1..`nrow',`pc3'..`ncol']
		mat `mat' =  `m2', `col',`m3'
	}
	else if `orig'==`ncol' & `dest'>1 {
		mat `m1' = `mat'[1..`nrow',1..`pc1']
		mat `m2' = `mat'[1..`nrow',`dest'..`pc2']
		mat `mat' =  `m1', `col', `m2'
	}
	else if `dest'==`ncol' & `orig'>1 {
		mat `m1' = `mat'[1..`nrow',1..`pc1']
		mat `m2' = `mat'[1..`nrow',`pc2'..`dest']
		mat `mat' =  `m1', `m2', `col'
	}
	else if `orig'>`dest' {
		mat `m1' = `mat'[1..`nrow',1..`pc1'] 
		mat `m2' = `mat'[1..`nrow',`dest'..`pc2']
		mat `m3' = `mat'[1..`nrow',`pc3'..`ncol']
		mat `mat' =  `m1' , `col' , `m2' , `m3' 
	}
	else {
		mat `m1' = `mat'[1..`nrow',1..`pc1'] 
		mat `m2' = `mat'[1..`nrow',`pc2'..`dest']
		mat `m3' = `mat'[1..`nrow',`pc3'..`ncol']
		mat `mat' =  `m1' ,  `m2' , `col', `m3' 
	}
	mat `touse' = `mat'
end

program define Ins0Vec
	version 8
	args touse pos name sym
	tempname mat col m1 m2
	mat `mat' = `touse'
	local nrow = rowsof(`mat')
	local ncol = colsof(`mat')
   	local sym = ("`sym'"!="")
	local row = 1+`sym'
	mat `col' = `mat'[1..`nrow',1]*0
	mat coln `col' = `name'
	if `pos'==0 {
		mat `mat' = `col', `mat'
	}
	else if `pos'==`ncol' {
		mat `mat' = `mat' , `col'
	}
	else {
		local pos2 = `pos'+1
		mat `m1'  = `mat'[1..`nrow',1..`pos']
		mat `m2'  = `mat'[1..`nrow',`pos2'..`ncol']
		mat `mat' = `m1' , `col' , `m2'
	}
	mat `touse' = `mat'
end



*============================================================
*
*	[7] OTHER SUBROUTINES
*
*============================================================


program define Mrhs , sclass
	version 8
	local id "`1'"
	mac shift
	sret local rhs`id' `*'
end


program define Mindex , sclass
	version 8
	sret local xb`1' `2'
end

program define EqLabel , sclass
	args depvar cat
	if "`cat'"=="" {
		qui sum `depvar' if `depvar'!=0
		local cat = r(mean)
	}
	local label : label (`depvar') `cat'
	if "`label'"=="" {
		local label "p`cat'"
	}
	else {
		local cat `label'
		local label = substr("`label'",1,8)
	}
	local eqlab "`s(eqname)' `label'"
	sret local eqname `eqlab'
	sret local cat `cat'
end


program define DumList , sclass
	version 8
	* Saving existing s() macros
	local nout  `s(nout)'
	local type  `s(type)'
	local neq   `s(neq)'
	local ncons `s(ncons)'
	local nap `s(nap)'
	local model `s(model)'

	parse "`*'" , p(" \ ")
	local i 1
	while "`1'"!="" {
		if "`1'"=="\" {
			local i = `i'+1
		}
		else {
			capture unabbrev "`1'"
			if _rc==0 {
				local list`i' "`list`i'' $S_1"
			}
			else {
				sret local error `1'
				exit
			}
		}
		mac shift
	}
	sret clear

	local N = `i'
	local i = 1
	while `i'<=`N' {
		local j = 1
		local n : word count `list`i''
		while `j'<=`n' {
			local treat : word `j' of `list`i''
			local k = 1
			while `k'<=`n' {
				if `k'!=`j' {
					local term : word `k' of `list`i''
					if "`list'"=="" {
						local list "if `term'!=1"
					}
					else local list "`list' & `term'!=1"
				}
				local k = `k'+1
			}
			sret local `treat' `list'
			local list ""
			local j = `j'+1
			local t = `t'+1
		}
		local i = `i'+1
	}

	sret local type   `type'
	sret local neq    `neq'
	sret local nout   `nout'
	sret local ncons  `ncons'
	sret local nap    `nap'
	sret local model  `model'
end

