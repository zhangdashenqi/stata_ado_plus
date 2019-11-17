capture program drop margin6
program define margin6 , eclass
*! Average marginal effects for categorical and limited dependent variable models
*! This version: 06 June 2004 - Author: Tamas Bartus

	version 6.0

	*=======================================
	*
	* [1] Syntax check
	*
	*=======================================

	if "`e(cmd)'"=="" {
		di in r "Last estimates not found"
		exit 301
	}
	if "`e(cmd)'"!="margin" {
		if `e(df_m)'==0  {
			di in r "There are no independent variables; running -margin- makes no sense"
			exit
		}
	}
	local Opt "`0'"
	
	syntax [ , Count Model(string)  Eform Dummies(string) Percent Replace  Table  ]

	local Doit = ("`model'`count'`eform'`dummies'`table'"!="")|("`e(marg_cmd)'"=="")
	if "`e(cmd)'"=="margin" { local Doit = 0 }
	local Disp = "`replace'`percent'`table'"!=""

	if `Doit'==1 {
		if "`eform'"!="" {
			local length : word count `e(depvar)'
			if `length'>1 {
				di in r "The eform option can only be used after single-equation commands"
				exit
			}
		}
   		if "`model'"=="" { local model = e(cmd) }
		SetEnv `model' `eform' /* Checks model & sets environment */
		if "`s(type)'"=="0" {
			di in r "-margin- does not work with `model'; use -mfx- instead"
			exit
		}
		if "`dummies'"!="" { local dummies dummies(`dummies') }

		Estimate , model(`model') `count' `eform' `table' `dummies'	`percent'
	}
	Display , `replace' `percent' `table'

end


	*=======================================
	*
	* [2] Doing the calculations
	*
	*=======================================

program define Estimate	, eclass
	version 6
	syntax [ , Model(string) Count Eform Table Dummies(string) Percent ]


	tempname b V tab
	tempvar touse
	mat `b' = e(b)
	mat `V' = e(V)
  	local depvar = e(depvar)
	local numobs = e(N)
	qui gen byte `touse' = e(sample)
	local mdf = e(df_m)
	local dof  = e(df_r)
	if `dof'!=. { local df "dof(`dof')" }
	if "`dummies'"!="" { local dummies dummies(`dummies') }

	preserve
	margin_e `depvar' , model(`model') `eform' `table' `dummies' `count' `mopt' /*
				*/ b(`b') vce(`V') touse(`touse') numobs(`numobs')
	restore

	mat `b'=r(b)
	mat `V'=r(V)
	mat `tab' = r(ms)
	
	if "`percent'"!="" {
		mat `b' = 10^2 * `b'
		mat `V' = 10^4 * `V'
	}

	est local marg_tit `r(title)'
	est local marg_dep `r(depv)'
	est local marg_cmd `r(model)'
	est mat   marg_b   `b'
	est mat   marg_V   `V'
	est mat   marg_tab `tab'
	
end
	
	*=======================================
	*
	* [3]: DISPLAYING RESULTS
	*
	*=======================================

program define Display , eclass
	version 6
	syntax [ , replace percent table ]
	
	di
	di in g "Marginal effects on " in y "`e(marg_tit)'" in g " after " in y "`e(marg_cmd)'"
	di


	if "`e(cmd)'"!="margin"	{ local prefix "marg_" }
	
	tempname b V tab
	tempvar touse
	mat `b' = e(`prefix'b)
	mat `V' = e(`prefix'V)
	mat `tab' = e(marg_tab)
  	local depvar = e(marg_dep)
	local numobs = e(N)
	qui gen byte `touse' = e(sample)
	local mdf  = e(df_m)
	local dof  = e(df_r)
	if `dof'!=. { local df "dof(`dof')" }
	if "`table'"!="" { mat `tab' = e(marg_tab) }

	if "`e(marg_dep)'"!="" { local depname depname(`e(marg_dep)') }

	if  "`replace'"=="" {
		tempname ehold
		est hold `ehold'
	}
	else {
		local title `e(marg_tit)'
		local depvar `e(marg_dep)'
		local cmd  `e(marg_cmd)'
	}
	if "`percent'"!="" {
		mat `b' = 10^2 * `b'
		mat `V' = 10^4 * `V'
	}

	est post `b' `V' , `df' `depname' obs(`numobs') esample(`touse')
	est disp

	if  "`replace'"=="" {	est unhold `ehold'	} 
	else {
		if "`s(eqname)'"!="" { local depv `s(eqname)' }
		else local  depv    `depvar'
		est local marg_tit `title'
		est local marg_dep `depvar'
		est local marg_cmd `cmd'
		est local cmd      margin
		est matrix marg_tab `tab'
		est scalar N    =  `numobs'
		est scalar df_m =  `mdf'
		if `dof'!=. { est scalar df_r = `dof' }
	}
	* sret clear

	if "`table'"!="" {
		if "`percent'"!="" { local format %12.2f }
		else local format %20.5f
		di _newline(2) in g "Descriptive statistics for individual marginal effects"
		di
		* di in g _dup(50) "-"
		* di in g "Variable" _col(15) %9s "Mean" %9s "SD" %9s  "Min" %9s "Max"
		* di in g _dup(50) "-"
		mat list e(marg_tab) , noblank nohalf noheader format(`format')
	}

end


********************************
*
*	SETTING THE ENVIRONMENT - SetEnv
*
********************************

program define EstSave , rclass
	version 6
	tempname bo vo
	mat `bo' = e(b)
	mat `vo' = e(V)
	return matrix b_orig `bo'
	return matrix v_orig `vo'
end


program define SetEnv , sclass
	version 6
	sret clear
	sret local model "`1'"
	sret local ncons 1
	if "`2'"!="" {
		sret local type 9
		sret local neq  1
		sret local nout 1
		sret local nap  0
		exit
	}
	else if "`1'"=="logit"    | "`1'"=="logistic" | "`1'"=="probit"  | "`1'"=="cloglog" | /*
		*/  "`1'"=="poisson" {
		sret local nout 1
		sret local type 1
		sret local neq  1
		sret local nap  0
		exit
	}
	else if "`1'"=="xtprobit" | "`1'"=="xtlogit"  | "`1'"=="nbreg" | /*
		*/  "`1'"=="tobit"    | "`1'"=="cnreg"    | "`1'"=="intreg"  | "`1'"=="truncreg"  {
		sret local nout 1
		sret local type 1
		sret local neq  1
		sret local nap  1
		exit
	}
 	else if "`1'"=="oprobit"  | "`1'"=="ologit" {
		qui tab `e(depvar)'	if e(sample)
		local ncons = e(k_cat)-1
		local nout = r(r)
		sret local ncons `ncons'
		sret local neq  1
		sret local nout `nout'
		sret local type 2
		sret local nap `ncons'
		exit
	}
	else if "`1'"=="mlogit" | "`1'"=="gologit"  {
		qui tab `e(depvar)' if e(sample)
		local neq = r(r)-1
		local nout = r(r)
		sret local ncons 1
		sret local neq  `neq'
		sret local nout `nout'
		sret local type 2
		sret local nap  0
		exit
	}
	else if "`1'"=="heckman"  | "`1'"=="heckprob" | /*
		*/  "`1'"=="biprobit"  | "`1'"=="zip"      | "`1'"=="zinb"       {
		local neq = 2
		local nout = 1 + ("`1'"=="biprobit")*3 + (substr("`1'",1,2)=="zi")*2
		local type = 3
		if "`1'"=="biprobit" {
			if substr(e(title),1,1)=="B" {
				local type = 2
			}
			*else local nout 1
			else local type 0
		}

		sret local neq `neq'
		sret local nout `nout'
		sret local type `type'
		if "`1'"=="heckman" {
			sret local nap 2
		}
		else if "`1'"=="zip" {
			sret local nap 0
		}
		else sret local nap 1
		exit
	}
	else sret local type 0
end



*------------------------------------------------------------------------------------------------------


program define margin_e , rclass
*! Subroutine needed by margin, written by Tamas Bartus
*! This version: 15 July 2003

	version 6
	syntax [varlist] [, Model(string) Eform Table Dummies(string) Count /*
						*/ mopt(string) Weight(varname) show(varlist) /*
				*/ b(string) vce(string) weight(varname) touse(varname) numobs(integer 0)]

	if "`weight'"!="" { local weight [fw=`weight'] }
	if "`dummies'"!="" { DUMLIST `dummies' }
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

	local depvar = e(depvar)

	ProcEst`s(type)' `s(model)'

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


	*=======================================
	*
	* [2]: PREDICTING INDEX
	*	DEFINING CDF, PDF, AND THE DERIVATIVE OF PDF
	*
	*=======================================


	* if "`model'"=="mlogit" { local denom 1 }
   	local i = 1
	while `i'<=`s(neq)' {
		if `s(neq)'>1 { local Popt "eq(#`i')" }
		tempvar xb`i'
		matrix score `xb`i'' = `b' if `touse' , `Popt'
		if "`e(offset)'"!="" {
			tempvar offset
			qui gen `offset' = `e(offset)' if `touse'
			qui replace `xb`i'' = `xb`i''-`offset' if `touse'
		}
		* qui _predict `xb`i'' if `touse' , xb `Popt'
		MINDEX `i' `xb`i''
		* if "`model'"=="mlogit" { local denom "`denom'+exp(`xb`i'')" }
		local i = `i'+1
	}
	* if "`model'"=="mlogit" | "`model'"=="clogit" { local mopt `mopt' `denom' }

	if `s(type)'==9 { local exe eform }
	else local exe = substr("`model'",1,7)
	M`exe' `s(depvar)' `mopt'
	if "`s(error)'"!="" {
		di in r "-margin- cannot estimate the requested marginal effects"
		di in r "The problem: " in b "`s(error)'"
		exit
	}


	*=======================================
	*
	*  [3]: DOING THE CALCULATIONS
	*
	*=======================================


	local dim  = `s(Ntreat)'*`s(nout)'
	local col  = 0
	mat  `bm'  = J(1,`dim',0)
	tempname ms
	mat `ms' = J(`dim',4,0)


	* Loop for outcomes
	local j = 1
	while `j'<=`s(nout)' {
		* Loop for variables
		local i = 1
			while `i'<=`s(Ntreat)' {
				local col = `col'+1
				local treat : word `i' of `s(Tlist)'
				local names "`names' `treat'"
				if `s(nout)'>1 {
					local term : word `j' of `s(eqname)'
					local neweq "`neweq' `term'"
				}
				tempname delta
				scalar `delta' = 1
				capture assert `treat'==1 | `treat'==0 if `touse'
				local vtype  = (_rc==0)
				if `vtype'==0 {
					if "`count'"!="" {
						capture assert mod(`treat',int(`treat'))==0	if `touse'
						if _rc==0 {	scalar `delta' = 1 }
					}
					else {
						qui sum `treat' , detail
						scalar `delta' = 10^(-6)*(r(p95)-r(p5))
					}
				}

				qui DOMARG `treat' `touse' `numobs' `i' `j' `coef' `Vdim' `vtype' `delta' `weight'

				* Tracing the computations:
				mat `ms'[`col',1] = r(me)
				mat `ms'[`col',2] = r(sd)
				mat `ms'[`col',3] = r(min)
				mat `ms'[`col',4] = r(max)

				local me   = r(me)
				mat `pder' = r(pder)
				mat `bm'[1,`col'] = `me'
				if `i'==1  & `j'==1 { mat `partder' = `pder' }
				else mat `partder' = `partder' \ `pder'
				local i = `i'+1
			}
		local j = `j'+1
	}
	mat `Vm' = `partder'*`vce'
	mat `Vm' = `Vm'*`partder''

	mat colnames `bm' = `names'
	mat rownames `Vm' = `names'
	mat colnames `Vm' = `names'
	mat coleq    `bm' = `neweq'
	mat coleq    `Vm' = `neweq'
	mat roweq    `Vm' = `neweq'

	mat rownames `ms' = `names'
	mat roweq    `ms' = `neweq'
	mat colnames `ms' = Mean SD Min Max
	return matrix ms `ms'

	return mat b `bm'
	return mat V `Vm'
	return local title `s(Title)'
	return local depv  `s(depname)'
	return local model `s(model)'
	global m_title `s(Title)'
	global m_depv  `s(depname)'
	global m_model `s(model)'

	sret clear
end



*============================================================
*
* [5] MARGINAL EFFECTS + STANDARD ERRORS
*
*============================================================


program define DOMARG , rclass
	version 6
	args treat touse numobs id out mat Vdim	vtype change weight
	tempvar hat0 hat1
	tempname row pder delta
	scalar `delta' = `change'
	mat `pder' = J(1,`Vdim',0)
	if "`weight'"!="" { local w [fw=`weight'] }

	nobreak {

	* BACKUP FOR LINEAR PREDICTION
	* SETTING DUMMIES TO ZERO / LEAVING CONTINUOUS VARS AS THEY ARE
	* CORRECTION FOR SMALL CHANGE TERM
		local dmin = 10^6
		local q = 1
		while `q'<=`s(neq)' {
			local beta = `mat'[`id',`q']
			if `beta'<`dmin' & `beta'!=0  { local dmin = `beta' }
			tempvar save`q'
			gen double `save`q'' = `s(xb`q')'
			replace `s(xb`q')' = `s(xb`q')'-`beta'*(`vtype'==1)*(`treat'==1)
			local q = `q'+1
		}
		scalar `delta' = `delta'/`dmin'
	* CALCULATING THE CDF + DENSITIES
		gen double `hat0' = `s(cumu`out'1)'
		local q = 1
		while `q'<=`s(neq)' {
			tempvar phi0`q'
			if "`s(dens`out'`q')'"=="" { gen byte `phi0`q'' = 0 }
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
			if "`s(dens`out'`q')'"=="" { gen byte `phi1`q'' = 0 }
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
			if "``s(`treat')'"!="" { replace `part`q'' = 0 if `part`q''==. & `touse'==1 }
			replace `s(xb`q')' = `save`q''
		* The i-th row of the part. deriv. matrix
			su `phi1`q'' `w'
			local add = r(mean)
			tempname row`q'
			mat vecaccum `row`q'' = `part`q'' `s(rhs)' `w' if `touse' , noconstant
			mat list `row`q''
			mat `row`q'' = `row`q'' / `numobs'
			if `vtype'==1 { mat `row`q''[1,`id'] = `add' }
			else            mat `row`q''[1,`id'] = `row`q''[1,`id'] + `add'
			if `q'==1 { mat `pder' = `row`q'' }
			else mat `pder' = `pder' , `row`q''
			local q = `q'+1
		}
		
	} /* end of nobreak */

	* MARGINAL EFFECT / RETURNING RESULTS
	replace `hat1' = (`hat1'-`hat0')/(`delta'^(`vtype'==0))
	noisily sum `hat1' `s(`treat')' `w'
	return scalar me = r(mean)
	return scalar sd = r(sd)
	return scalar min = r(min)
	return scalar max = r(max)
	return matrix pder `pder'
end



*============================================================
*
*	[6] PROGRAMS PREDICTING CDF, DENSITY, AND DERIVATIVES
*
*============================================================


program define Meform , sclass
	EQLABEL `1'
	sret local Title E(exp[xb])
	sret local depname `s(depvar)'
	sret local eqname  `1'
	sret local cumu11  exp(`s(xb1)')
	sret local dens11  exp(`s(xb1)')
end

program define Mlogit , sclass
	version 6
	args depvar rho
	if "`rho'"=="" { local rho = 1 }
	local cumu11 " 1/(1+exp(-`rho'*`s(xb1)')) "
	sret local cumu11 `cumu11'
	sret local dens11 " `rho'*(`cumu11')*(1-`cumu11')"
	EQLABEL `depvar'
	sret local Title Prob(`depvar'==`s(cat)')
	sret local depname `depvar'
	sret local eqname `depvar'
end

program define Mlogisti
	Mlogit `*'
end

program define Mxtlogit , sclass
	version 6
	if e(predict)=="xtbin_p" {
		local rho = sqrt(1-`e(rho)')
		Mlogit `*' `rho'
	}
	else {
		sret local error "the population-averaged version of xtlogit not supported"
		exit
	}
end


program define Mprobit , sclass
	version 6
	args depvar rho
	if "`rho'"=="" { local rho 1 }
	sret local cumu11 " normprob(`rho'*`s(xb1)') "
	sret local dens11 " `rho'*normd(`rho'*`s(xb1)') "
	EQLABEL `depvar'
	sret local Title "Prob(`depvar'==`s(cat)')"
	sret local depname `depvar'
	sret local eqname `depvar'
end


program define Mxtprobi , sclass
	if e(predict)=="xtbin_p" {
		local rho = sqrt(1-`e(rho)')
		Mprobit `*' `rho'
	}
	else {
		sret local error "the population-averaged version of xtlogit not supported"
		exit
	}
end


program define Mcloglog , sclass
	local depvar "`1'"
	local cumu11 " 1-exp(-exp(`s(xb1)')) "
	local dens11 " -(1-`cumu11')*exp(`s(xb1)') "
	sret local cumu11 `cumu11'
	sret local dens11 `dens11'
	EQLABEL `s(depvar)'
	sret local Title "Prob(`s(depvar)'==`s(cat)')"
	sret local depname `depvar'
	sret local eqname `depvar'
end

program define Moprobit , sclass
	version 6
	args depvar
	tempname matcat
	mat `matcat' = e(cat)
	local kcat = e(k_cat)
	sret local cumu11 " 1-normprob(`s(xb1)'-_b[_cut1])"
	sret local dens11 "-normd(`s(xb1)'-_b[_cut1])"
	local cat = `matcat'[1,1]
	EQLABEL `s(depvar)' `cat'
	local i = 2
	while `i'<`kcat' {
		local j = `i'-1
		sret local cumu`i'1 "normprob(_b[_cut`i']-`s(xb1)')-normprob(_b[_cut`j']-`s(xb1)')"
		sret local dens`i'1 "normd(_b[_cut`j']-`s(xb1)')-normd(_b[_cut`i']-`s(xb1)')"
		local cat = `matcat'[1,`i']
		EQLABEL `e(depvar)' `cat'
		local i = `i'+1
	}
	local j = `nout'-1
	sret local cumu`nout'1 "normprob(`s(xb1)'-_b[_cut`j'])"
	sret local dens`nout'1 "normd(`s(xb1)'-_b[_cut`j'])"
	local cat = `matcat'[1,`nout']
	EQLABEL `depvar' `cat'
	sret local Title Prob(`depvar')
	sret local depname `depvar')
end


program define Mologit , sclass
	version 6
	args depvar
	tempname matcat b
	mat `matcat' = e(cat)
	sret local cumu11 "1/(1+exp(-_b[_cut1]+`s(xb1)'))"
	sret local dens11 "-exp(_b[_cut1]-`s(xb1)')/((1+exp(_b[_cut1]-`s(xb1)'))^2)"
	local cat = `matcat'[1,1]
	EQLABEL `depvar' `cat'
	local i = 2
	while `i'<`kcat' {
		local j = `i'-1
		sret local cumu`i'1 "1/(1+exp(_b[_cut`i']+`s(xb1)'))-1/(1+exp(-_b[_cut`j']+`s(xb1)'))"
		sret local dens`i'1 "exp(_b[_cut`j']-`s(xb1)')/((1+exp(_b[_cut`j']-`s(xb1)'))^2)-exp(_b[_cut`i']-`s(xb1)')/((1+exp(_b[_cut`i']-`s(xb1)'))^2)"
		local cat = `matcat'[1,`i']
		EQLABEL `depvar' `cat'
		local i = `i'+1
	}
	local j = `nout'-1
	sret local cumu`nout'1 "1/(1+exp(_b[_cut`j']-`s(xb1)'))"
	sret local dens`nout'1 "exp(`s(xb1)'-_b[_cut`j'])/((1+exp(`s(xb1)'-_b[_cut`j']))^2)"
	local cat = `matcat'[1,`nout']
	EQLABEL `depvar' `cat'
	sret local Title Prob(`depvar')
	sret local depname `depvar'
end


program define Mgologit , sclass
	version 6
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
		EQLABEL `depvar' `cat'
		local i = `i'+1
	}
	sret local Title Prob(`depvar')
	sret local depname `depvar'
end


program define Mmlogit , sclass
	version 6
	args depvar denom
	tempname matcat
	mat `matcat' = e(cat)
	local base = e(ibasecat)
	local denom "1"
	local i = 1
	while `i'<=`s(neq)' {
		local denom "`denom'+exp(`s(xb`i')')"
		local i = `i'+1
	}
	local i = 1
	while `i'<=`s(nout)' {
		if `i'==`base' { local prob`i' "1/(`denom')" }
		else if `i'<`base' { local prob`i' "exp(`s(xb`i')')/(`denom')" }
		else if `i'>`base'{
			local j = `i'-1
			local prob`i' "exp(`s(xb`j')')/(`denom')"
		}
		local i = `i'+1
	}
	local i = 1
	while `i'<=`s(nout)' {
		if `i'>=`base' { local j = `i'-1 }
		else local j = `i'
		sret local cumu`i'1 "`prob`i''"
		local q = 1
		while `q'<=`s(neq)' {
			if `i'!=`base' & `q'==`j' {	local dens`i'`q' "(`prob`i'')*(1-(`prob`i''))"	}
			else { local dens`i'`q' "-(`prob`i'')*(`prob`q'')" }
			sret local dens`i'`q' `dens`i'`q''
			local q = `q'+1
		}
		local cat = `matcat'[1,`i']
		EQLABEL `depvar' `cat'
		local i = `i'+1
	}
	sret local Title Prob(`depvar')
	sret local depname `depvar'
end


program define Mpoisson , sclass
	version 6
	Meform	`*'
	sret local Title E(`s(depname)')
end


program define Mnbreg , sclass
	version 6
	Mpoisson `*'
end


program define Mzip , sclass
	version 6
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

program define Mzinb, sclass
	version 6
	Mzip `*'
end


program define Mbiprobi , sclass
	version 6
	args v1 v2 bit
	local rho = e(rho)
	local srh = sqrt(1-`rho'^2)
	local k = 1
	while `k'<=`s(nout)' {
		local A
		local C 
		local B 
		if `k'>2           { local A - }
		if `k'==2 | `k'==4 { local B - }
		if `k'==2 | `k'==3 { local C - }
		sret local cumu`k'1  binorm(`A'`s(xb1)',`B'`s(xb2)',`C'`rho')
		sret local dens`k'1  normd(`A'`s(xb1)')*normprob((`B'`s(xb2)'-`C'`rho'*`A'`s(xb1)')/`srh')
		sret local dens`k'2  normd(`B'`s(xb2)')*normprob((`A'`s(xb1)'-`C'`rho'*`B'`s(xb2)')/`srh')
		local k = `k'+1
	}
	sret local eqname "p11 p10 p01 p00"
	sret local Title "Prob(`v1',`v2')"
end


program define Mtobit , sclass
	version 6
	args depvar
	local sig = _b[_se]
	local ul = e(ulopt)
	local ll = e(llopt)
	if `ul'==. { local ul = 0 }
	if `ll'==. { local ll = 0 }
	if `ll'==0 { local vll = -10000 }
	else local vll  (`ll'-`s(xb1)')/`sig'
	if `ul'==0 { local vul = 10000 }
	else local vul  (`ul'-`s(xb1)')/`sig'
	CENSOR , depvar(`depvar') ul(`ul') vul(`vul') ll(`ll') vll(`vll') sig(`sig')
end

program define Mcnreg , sclass
	version 6
	args depvar
	local censor = e(censored)
	local sig = _b[_se]
	local  ll "(`censor'*`depvar')"
	local  ul "(`censor'*`depvar')"
	local vll "(`censor'*( `ll'-`s(xb1)')/`sig'+(1-`censor')*(-10000))"
	local vul "(`censor'*(`ull'-`s(xb1)')/`sig'+(1-`censor')*( 10000))"
	CENSOR , depvar(`depvar') ul(`ul') vul(`vul') ll(`ll') vll(`vll') sig(`sig')
end

program define Mintreg , sclass
	version 6
	args left right
	local sig = _b[/sigma]
	local censor "(`left'!=`right')"
	local  ll "(`censor'*`left')"
	local  ul "(`censor'*`right')"
	local vll "(`censor'*( `ll'-`s(xb1)')/`sig'+(1-`censor')*(-10000))"
	local vul "(`censor'*(`ull'-`s(xb1)')/`sig'+(1-`censor')*( 10000))"
	CENSOR , depvar(`left') ul(`ul') vul(`vul') ll(`ll') vll(`vll') sig(`sig')
end

program define CENSOR , sclass
	version 6
	syntax [, depvar(string) ll(string) ul(string) vll(string) vul(string) sig(real 0)]
	local cumu11 "`ll'*normprob(`vll')+`ul'*normprob(-`vul')"
	local cumu11 "`cumu11' + (normprob(`vul')-normprob(`vll'))*`s(xb1)'"
	local cumu11 "`cumu11' + `sig'*(normd(`vll')-normd(`vul'))"
	sret local cumu11 `cumu11'
	sret local dens11 "normprob(`vul')-normprob(`vll')"
	sret local Title "E(`depvar'|`depvar' observed)"
	sret local depname `depvar'
end

program define Mtruncre , sclass
	version 6
	args v1
	di "`v1'"
	local sig = `e(sigma)'
	local ul = e(ulopt)
	local ll = e(llopt)
	if `ll'==. { local vll = -10000 }
	else local vll  (`ll'-`s(xb1)')/`sig'
	if `ul'==. { local vul = 10000 }
	else local vul  (`ul'-`s(xb1)')/`sig'
	local mills  "(normd(`vll')-normd(`vul'))/(normprob(`vul')-normprob(`vll')) "
	sret local cumu11 "`s(xb1)'+`sig'*`mills'"
	sret local dens11 "1+`mills'-(`mills')^2"
	sret local Title "E(`v1'|`v1' observed)"
	sret local depname `v1'
end

			
program define Mtreatre , sclass
	version 6
	args v1 v2
	local sig = `e(sigma)'*`e(rho)'
	local mills  "normd(`s(xb2)')/normprob(`s(xb2)')"
	sret local cumu11 "(1-`v2')*[`v1']_b[`v2']+`s(xb1)'+`sig'*`mills' "
	sret local dens11 "1"
	sret local dens12 "-`sig'*(`s(xb2)'*(`mills')+(`mills')^2 )"
	sret local Title "E(`v1'|`v2'==1)"
	sret local depname `v1'
end


program define Mheckman , sclass
	version 6
	args v1 v2
	local sig = `e(sigma)'*`e(rho)'
	local mills  "normd(`s(xb2)')/normprob(`s(xb2)') "
	sret local cumu11 "`s(xb1)'+`sig'*`mills'"
	sret local dens11 "1"
	sret local dens12 "-`sig'*(`s(xb2)'*(`mills')+(`mills')^2 )"
	if "`v2'"=="select" { sret local Title "E(`v1'|`v1' observed)" }
	else sret local Title "E(`v1'|`v2'==1)"
	sret local depname `v1'
end


program define Mheckpro , sclass
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
	if "`v2'"=="select" { sret local Title "Prob(`v1'==1|`v1' observed)" }
	else sret local Title "Prob(`v1'==1|`v2'==1)"
	sret local depname `v1'
end


*============================================================
*
*	[7] SUBROUTINES THAT PROCESS ESTIMATION RESULTS
*
*============================================================

program define PassToS , sclass
	version 6
	local rhs `*'
	local Tlist `r(treat)'
	local ntreat : word count `Tlist'
	sret local depvar `r(depvar)'
	sret local rhs `Tlist' `rhs'
	sret local Tlist `r(treat)'
	sret local Ntreat `ntreat'
end


program define ProcEst1 , rclass
	version 6
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
	version 6
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
	version 6
	local depvar = e(depvar)
	local v1 : word 1 of `depvar'
	local v2 : word 2 of `depvar'
	if "`v2'"=="" {
		if "`s(model)'"=="zip" | "`s(model)'"=="zinb" { local v2 "inflate" }
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
	version 6
	args touse orig dest sym
	if `orig'==`dest' {	exit }
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
	version 6
	args touse pos name sym
	tempname mat col m1 m2
	mat `mat' = `touse'
	local nrow = rowsof(`mat')
	local ncol = colsof(`mat')
   	local sym = ("`sym'"!="")
	local row = 1+`sym'
	mat `col' = `mat'[1..`nrow',1]*0
	mat coln `col' = `name'
	if `pos'==0 { mat `mat' = `col', `mat' }
	else if `pos'==`ncol' { mat `mat' = `mat' , `col' }
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
*	[8] OTHER SUBROUTINES
*
*============================================================


program define MRHS , sclass
	version 6
	local id "`1'"
	mac shift
	sret local rhs`id' `*'
end


program define MINDEX , sclass
	version 6
	sret local xb`1' `2'
end



program define EQLABEL , sclass
	args depvar cat
	if "`cat'"=="" {
		qui sum `depvar' if `depvar'!=0
		local cat = r(mean)
	}
	local label : label (`depvar') `cat'
	if "`label'"=="" { local label "p`cat'" }
	else {
		local cat `label'
		local label = substr("`label'",1,8)
	}
	local eqlab "`s(eqname)' `label'"
	sret local eqname `eqlab'
	sret local cat `cat'
end


program define DUMLIST , sclass
	version 6
	* Saving existing s() macros
	local nout `s(nout)'
	local type `s(type)'
	local neq `s(neq)'
	local ncons `s(ncons)'
	local model `s(model)'
	* local MPRED `s(MPRED)'

	parse "`*'" , p(" \ ")
	local i 1
	while "`1'"!="" {
		if "`1'"=="\" {local i = `i'+1 }
		else {
			capture unabbrev "`1'"
			if _rc==0 { local list`i' "`list`i'' $S_1" }
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
					if "`list'"=="" { local list "if `term'!=1" }
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

	sret local type  `type'
	sret local neq   `neq'
	sret local nout  `nout'
	sret local ncons   `ncons'
	sret local model `model'
	* sret local MPRED `MPRED'
end
