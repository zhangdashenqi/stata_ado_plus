*! Program to estimates the spatial lag, the spatial error, the spatial durbin, and the general spatial models with moderately large datasets               
*! Author: P. Wilner Jeanty 
*! Born: December 18, 2009                                                                                              
*! Version 1.0   
*! Version 1.1: January 2010 - General Spatial Model also known as Spatial Mixed Model added
*! Version 1.2: February 2010 - Spatial Durbin Model added                              

program define spmlreg, eclass 
	version 10.0
	if replay() {
      	if "`e(cmd)'"!="spmlreg" {
            	error 301
        	}
        	Display `0'
	}
	else {
        Estimate `0'
	}
end
program define Estimate, eclass
	version 10.0
	syntax varlist(min=2), Weights(str) WFrom(str) Eignvar(str) Model(str) ///
           [noLOG Robust Level(passthru) favor(str) wrho(str) EIGWrho(str) ///
		   INITRho(real 0) INITLambda(real 0) sr2 *]

	if !inlist("`model'", "lag", "error", "sac", "durbin") {
   		di as err "Option {bf:model()} accepts one of the following: {bf:lag}, {bf:error}, {bf:sac}, {bf:durbin}"
   		exit
	}
	if "`model'"!="sac" & `:word count `wrho' `eigwrho''!=0 {
		di as err "Options {bf:wrho()} and {bf:eigwrho()} may only be specified with {bf:model(sac)}"
		exit 198
	}
	local usew1 :word count `wrho' `eigwrho'
	if "`model'"=="sac" & !inlist(`usew1',0,2) { 
		di as err "Options {bf:wrho()} and {bf:eigwrho()} must be combined"
		exit 198
	}
	if inlist("`model'", "error", "sac") & "`robust'"!="" {
		di as err "{bf:robust} may not be combined with {bf:model(`model')}"
		exit 198
	}	
	if "`model'"=="error" & "`sr2'"!="" local sr2 "" 
	preserve
	mata: mata clear
	cap mata: mata drop spmlreg_* 
 	cap macro drop spmlreg_*
	cap drop spmlreg_*
	if inlist("`model'", "error", "sac", "durbin") cap drop wx_*
	if "`model'"=="sac" cap drop w2x_*
    mlopts mlopts, `options'
	gettoken depv indvar: varlist
	global spmlreg_nv : word count `indvar'
	global spmlreg_sr2=0
	if "`sr2'"!="" global spmlreg_sr2=1
	cap confirm numeric var `eignvar'
	qui sum `eignvar'
	local LOWER=1/r(min)
	local UPPER=1/r(max)
	gen double spmlreg_eigv= `eignvar'
	capture drop wy_`depv'
	qui splagvar `depv', wn(`weights') wfrom(`wfrom') favor(`favor') // calculate spatial lag for y
	local a_estimer "spmlreg_lag"
	local titl "Spatial Lag Model"
	global spmlreg_mdf=1
	global spmlreg_wmdf=$spmlreg_nv
	if "`model'"=="error" {
		di in y "Calculating the spatial lags...." _continue
		qui splagvar, wn(`weights') wfrom(`wfrom') ind(`indvar') favor(`favor') // calculate spatial lags for X
		local i=1
		foreach var of local indvar {
			gen double spmlreg_wx`i' = wx_`var'			
			local ++i
		}
		local a_estimer "spmlreg_error"
		local titl "Spatial Error Model"
	}
	if "`model'"=="sac" {
		di in y "Calculating the spatial lags...." _continue
		qui splagvar, wn(`weights') wfrom(`wfrom') ind(`indvar') favor(`favor')
		local i=1
		foreach var of local indvar {
			gen double spmlreg_wx`i' = wx_`var'			
			local ++i
		}
		if `usew1'==2 {
			cap confirm numeric var `eigwrho'
			global spmlreg_w1=1
			qui gen double spmlreg_y=`depv'
			qui splagvar spmlreg_y, wn(`wrho') wfrom(`wfrom') favor(`favor') 
			gen double spmlreg_w1y=wy_spmlreg_y
			gen double spmlreg_eigv1=`eigwrho'
			qui sum `eigwrho'
			local LOWER1=1/r(min)
			local UPPER1=1/r(max)
			qui splagvar wy_spmlreg_y, wn(`weights') wfrom(`wfrom') favor(`favor') 
			gen double spmlreg_w2w1y=wy_wy_spmlreg_y
		}
		else {
			global spmlreg_w1=0
			qui splagvar, wn(`weights') wfrom(`wfrom') ind(`depv') order(2) favor(`favor')
			qui gen double spmlreg_w2w2y=w2x_`depv'
		}
		local a_estimer "spmlreg_sac"
		local titl "Spatial Mixed Model"
		global spmlreg_mdf=2
	}
	if "`model'"=="durbin" {
		qui splagvar, wn(`weights') wfrom(`wfrom') ind(`indvar') favor(`favor')
		local titl "Spatial Durbin Model"
		unab wxxs: wx_*
		local indvar `indvar' `wxxs'
		global spmlreg_mdf=1+$spmlreg_nv
		global spmlreg_wmdf=2*$spmlreg_nv
	}
	* Get initial values
	qui regress `depv' `indvar'
	tempname matinit
	if inlist("`model'", "lag", "durbin")  matrix `matinit'=e(b),`initrho',e(rmse)
	if "`model'"=="error" matrix `matinit'=e(b),`initlambda',e(rmse)
	if "`model'"=="sac" matrix `matinit'=e(b),`initrho',`initlambda',e(rmse)
	local initopt init(`matinit', copy) search(off) `log' `mlopts' 
	matrix spmlreg_matols=`matinit'[1,1..$spmlreg_nv]

	* Estimate the spatial lag or spatial durbin model
	if inlist("`model'", "lag", "durbin") {
		ml model lf `a_estimer' (`depv': `depv'=`indvar') (rho:) (sigma:), `robust' ///
		maximize continue `initopt' title(`titl')
		if $spmlreg_sr2==1 {  		
			tempname bet r2b brho
			matrix `bet'=e(b)
			matrix `r2b'=`bet'[1, "`depv':"]
			scalar `brho'=[rho]_cons
			cap erase spmlreg_filefeig
			cap drop spmlregy_pred
			mata: spmlreg_CalcSR2("`brho'", "`r2b'", "`indvar'", "wfrom", "weights")
			qui sum spmlregy_pred
   			local NUM=r(Var)
   			qui summ `depv'
   			local DEN=r(Var)
  			local VARRAT=`NUM'/`DEN'
   			qui correlate spmlregy_pred `depv'
   			local SQCORR=r(rho)*r(rho)
      		ereturn scalar varRatio=`VARRAT'
      		ereturn scalar sqCorr=`SQCORR'
			ereturn local pred_y "spmlregy_pred"
		}
		local WALD=([rho]_cons/[rho]_se[_cons])^2
		if "`model'"=="durbin" {			
			qui testparm `wxxs'
			local wald_d=r(chi2)
			local p_wald_d=r(p)
			ereturn scalar wald_durbin=`wald_d'
			ereturn scalar p_durbin=`p_wald_d'
		}
		ereturn scalar rho=[rho]_cons
      	ereturn scalar df_m=$spmlreg_mdf
      	ereturn scalar p=chi2tail($spmlreg_mdf, e(chi2))
      	ereturn scalar minEigen=`LOWER'
      	ereturn scalar maxEigen=`UPPER'
	    ereturn scalar Wald=`WALD'
	}
    forv i=1/$spmlreg_nv  {
      	local ITEM : word `i' of `indvar'
		local MODEL "`MODEL'(`ITEM':) "
		local spmlreg_ARGS "`spmlreg_ARGS' beta`i'"                
   	}
	if "`model'"=="error" {
   		local MODEL "`MODEL'(_cons:) (lambda:) (sigma:)"
   		global spmlreg_ARGS "`spmlreg_ARGS' beta0 lambda sigma"
	}
	else if "`model'"=="sac" {
   		local MODEL "`MODEL'(_cons:) (rho:) (lambda:) (sigma:)"
   		global spmlreg_ARGS "`spmlreg_ARGS' beta0 rho lambda sigma"
	}	
	* Estimate the spatial error model
	if "`model'"=="error" { 
        ml model lf `a_estimer' `MODEL', `nolog' ///
        maximize continue `initopt' title(`titl')
        ereturn scalar df_m=$spmlreg_mdf
        ereturn scalar k_eq=3
        ereturn scalar k_aux=1
        tempname BETA
        matrix `BETA'=e(b)
        forv i=1/$spmlreg_nv {
			local ITEM : word `i' of `indvar'
			local COLNAME "`COLNAME'`depv':`ITEM' " 
        }
		local COLNAME "`COLNAME'`depv':_cons lambda:_cons sigma:_cons"
   		matrix colnames `BETA'=`COLNAME'
   		ereturn repost b=`BETA',rename
        tempvar YHAT
        qui predict `YHAT'
		qui summ `YHAT'
   		local NUM=r(Var)
   		qui summ `depv'
   		local DEN=r(Var)
   		local VARRAT=`NUM'/`DEN'
   		qui correlate `YHAT' `depv'
   		local SQCORR=r(rho)*r(rho)
   		local WALD=([lambda]_b[_cons]/[lambda]_se[_cons])^2		
		ereturn scalar lambda=[lambda]_cons
	    ereturn scalar Wald=`WALD'
     	ereturn scalar minEigen=`LOWER'
      	ereturn scalar maxEigen=`UPPER'
      	ereturn scalar varRatio=`VARRAT'
      	ereturn scalar sqCorr=`SQCORR'
	}
	* Estimate the spatial mixed or the general spatial model
	if "`model'"=="sac" { 
        ml model lf `a_estimer' `MODEL', `nolog' ///
		maximize continue `initopt' title(`titl')
        ereturn scalar df_m=$spmlreg_mdf
        ereturn scalar p=chi2tail(2,e(chi2))
        ereturn scalar k_eq=4
        ereturn scalar k_aux=2
        tempname BETA
        matrix `BETA'=e(b)
        forv i=1/$spmlreg_nv {
			local ITEM : word `i' of `indvar'
			local COLNAME "`COLNAME'`depv':`ITEM' " 
        }
		local COLNAME "`COLNAME'`depv':_cons rho:_cons lambda:_cons sigma:_cons"
   		matrix colnames `BETA'=`COLNAME'
   		ereturn repost b=`BETA',rename
		if $spmlreg_sr2==1 {
			tempname bet r2b brho
			matrix `bet'=e(b)
			matrix `r2b'=`bet'[1, "`depv':"]
			scalar `brho'=[rho]_cons
			cap erase spmlreg_filefeig
			cap drop spmlregy_pred
			mata: spmlreg_CalcSR2("`brho'", "`r2b'", "`indvar'", "wfrom", "weights")
			qui sum spmlregy_pred
   			local NUM=r(Var)
   			qui summ `depv'
   			local DEN=r(Var)
  			local VARRAT=`NUM'/`DEN'
   			qui correlate spmlregy_pred `depv'
   			local SQCORR=r(rho)*r(rho)
      		ereturn scalar varRatio=`VARRAT'
      		ereturn scalar sqCorr=`SQCORR'
			ereturn local pred_y "spmlregy_pred"
		}
		qui test ([rho]_cons=0) ([lambda]_cons=0)
		local Wald=r(chi2)
		ereturn scalar Wald=`Wald'
      	ereturn scalar minEigen=`LOWER'
      	ereturn scalar maxEigen=`UPPER'
		if $spmlreg_w1==1 {
      		ereturn scalar minEigen1=`LOWER1'
      		ereturn scalar maxEigen1=`UPPER1'
		}
	}
    ereturn scalar k_dv=1
    ereturn local depvar "`depv'"
	ereturn local wname `weights'
	ereturn local wfrom `wfrom'
	ereturn local cmd "spmlreg"

	* Display results
	Display, `level' `robust'
	restore
	cap drop spmlregy_pred
	if "`sr2'"!="" mata: spmlreg_geteigen()	
	/* Housekeeping*/
	cap macro drop spmlreg_*
	cap mat drop spmlreg_*
	mata: mata clear
end
program define Display
	version 10.0
	syntax, [Level(int $S_level) robust]
	di _newline
	di as txt "`e(title)'" _col(52) "Number of obs" _col(68) "=" as res %10.0f `e(N)'
	if "`e(title)'"=="Spatial Error Model" {
		di as txt _col(52) "LR chi2(" as res 1 as txt ")" _col(68) "=" as res %10.3f `e(chi2)'
		di as txt _col(52) "Prob > chi2" _col(68) "=" as res %10.3f chi2tail(1,`e(chi2)')
		di as txt _col(52) "Variance ratio" _col(68) "=" as res %10.3f `e(varRatio)'
		di as txt _col(52) "Squared corr." _col(68) "=" as res %10.3f `e(sqCorr)'
	}
	if inlist("`e(title)'", "Spatial Lag Model", "Spatial Mixed Model", "Spatial Durbin Model") {
		if "`robust'"=="" {
			di as txt _col(52) "LR chi2(" as res $spmlreg_mdf as txt ")" _col(68) "=" as res %10.3f `e(chi2)'
			di as txt _col(52) "Prob > chi2" _col(68) "=" as res %10.3f chi2tail($spmlreg_mdf,`e(chi2)')
		}
		else {
			di as txt _col(52) "Wald chi2(" as res $spmlreg_wmdf as txt ")" _col(68) "=" as res %10.3f `e(chi2)'
			di as txt _col(52) "Prob > chi2" _col(68) "=" as res %10.3f chi2tail($spmlreg_wmdf,`e(chi2)')
		}		
		if $spmlreg_sr2==1 {
			di as txt _col(52) "Variance ratio" _col(68) "=" as res %10.3f `e(varRatio)'
			di as txt _col(52) "Squared corr." _col(68) "=" as res %10.3f `e(sqCorr)'
		}
	}
	di as txt "Log likelihood = " as res `e(ll)' as txt _col(52) "Sigma"   /*
     */   _col(68) "=" as res %10.2f [sigma]_cons
	di ""
	if inlist("`e(title)'", "Spatial Error Model", "Spatial Lag Model", "Spatial Durbin Model") {  

		ml display, level(`level') neq(1) plus noheader
		if inlist("`e(title)'", "Spatial Lag Model", "Spatial Durbin Model") {
			_diparm rho, level(`level') label("rho")
			local PARM "rho"
		}
		if "`e(title)'"=="Spatial Error Model" {
			_diparm lambda, level(`level') label("lambda")
			local PARM "lambda"
		}
		di as txt "{hline 13}{c BT}{hline 64}"
		if inlist("`e(title)'", "Spatial Error Model", "Spatial Lag Model") {
			di as txt "Wald test of `PARM'=0:" _col(40) "chi2(1) = "   /*
			*/ as res _col(50) %7.3f `e(Wald)' as txt " ("             /*
			*/ as res %5.3f chi2tail(1,`e(Wald)') as txt ")"
			if "`robust'"=="" {
   				di as txt "Likelihood ratio test of `PARM'=0:" _col(40) "chi2(1) = "   /*
   				*/ as res _col(50) %7.3f `e(chi2)' as txt " ("                         /*
   				*/ as res %5.3f chi2tail(1,`e(chi2)') as txt ")"
			}
		}
		if "`e(title)'"=="Spatial Durbin Model" {
			di as txt "Wald test of `PARM'=0:" _col(50) "chi2(1) = "   /*
			*/ as res _col(58) %7.3f `e(Wald)' as txt " ("             /*
			*/ as res %5.3f chi2tail(1,`e(Wald)') as txt ")"
			di as txt "Wald test for coefficients on lags of X's =0:" _col(50) "chi2(" $spmlreg_nv as txt ") = "   /*
			*/ as res _col(58) %7.3f `e(wald_durbin)' as txt " ("             /*
			*/ as res %5.3f chi2tail($spmlreg_nv,`e(wald_durbin)') as txt ")"
			if "`robust'"=="" {
   				di as txt "Likelihood ratio test of SDM vs. OLS:" _col(50) "chi2("$spmlreg_mdf as txt ") = "   /*
   				*/ as res _col(58) %7.3f `e(chi2)' as txt " ("                         /*
   				*/ as res %5.3f chi2tail($spmlreg_mdf,`e(chi2)') as txt ")"
			}
		}	
		di ""
		di as txt "Acceptable range for `PARM': " as res %5.3f `e(minEigen)'   /*
   		*/   " < `PARM' < " %5.3f `e(maxEigen)' 
		di _newline
	}
	if "`e(title)'"=="Spatial Mixed Model" {
		ml display, level(`level') neq(1) noheader diparm(rho, label("rho")) diparm(lambda, label("lambda"))
		di 
		di as txt "Wald test of SAC vs. OLS:" _col(40) "chi2(2) = "   /*
		*/ as res _col(50) %7.3f `e(Wald)' as txt " ("             /*
		*/ as res %5.3f chi2tail(2,`e(Wald)') as txt ")"
		di
   		di as txt "Likelihood ratio test of SAC vs. OLS:" _col(40) "chi2(2) = "   /*
   			*/ as res _col(50) %7.3f `e(chi2)' as txt " ("                         /*
   			*/ as res %5.3f chi2tail(2,`e(chi2)') as txt ")"		
		if $spmlreg_w1==0 {
			di
			di as txt "Acceptable range for Rho and Lambda: " as res %5.3f `e(minEigen)'   /*
   			*/   " < Rho, Lambda < " %5.3f `e(maxEigen)' 
		}
		else {
			di
			di as txt "Acceptable range for Rho: " as res %5.3f `e(minEigen1)'   /*
   			*/   " < Rho < " %5.3f `e(maxEigen1)' 
			di
			di as txt "Acceptable range for Lambda: " as res %5.3f `e(minEigen)'   /*
   			*/   " < Lambda < " %5.3f `e(maxEigen)'
		}
	}	  
end
version 10.0
set matastrict on
mata
mata drop *()
void spmlreg_CalcSR2(string scalar brho, string scalar bvec, string scalar xvars, string scalar m_wfrom, string scalar m_wname) 
{
    rho=st_numscalar(brho) 
	real matrix B, C, xxs, invIRW
	xxs=st_data(., tokens(xvars))
	C=J(nc=rows(xxs),1,1)
    xxs=xxs,C
	if (st_local(m_wfrom)=="Mata") {
        fh = fopen(st_local(m_wname), "r") 
        spmlreg_w=fgetmatrix(fh)
        fclose(fh)
	}
	else spmlreg_w=st_matrix(st_local(m_wname)) 
    nw=rows(spmlreg_w)
	invIRW=luinv(I(nw)-rho*spmlreg_w)
    B=st_matrix(bvec)
    XB=xxs*B'
    ypred=invIRW*XB
    fhh = fopen("spmlreg_filefeig", "w")
    fputmatrix(fhh, ypred)
    fclose(fhh)
    st_store(., st_addvar("double", "spmlregy_pred"), ypred)
}
void spmlreg_geteigen() {
	fh = fopen("spmlreg_filefeig", "r") 
	predy=fgetmatrix(fh)
	fclose(fh)
	st_store(., st_addvar("double", "spmlregy_pred"), predy)
	unlink("spmlreg_filefeig")
}
end

