*! version 1.1.0 PR 25jan2007
program define uvrs, eclass
version 8.2
gettoken cmd 0 : 0
frac_chk `cmd' 
if `s(bad)' {
	di as err "invalid or unrecognized command, `cmd'"
	exit 198
}
local dist `s(dist)'
if `dist' != 7 gettoken y 0 : 0, parse(" ,")
local glm `s(isglm)'
local qreg `s(isqreg)'
local xtgee `s(isxtgee)'
local normal `s(isnorm)'
local 0 `"`y' `0'"'
syntax varlist [if] [in] [aw fw pw iw] [, all ALpha(real 1) CONStant DEAD(varname) ///
 DEGree(int 3) DF(integer 4) EQUAL KNots(numlist) LINEAR REPort(numlist) ///
 TRAce UNIQUE * ]
if "`knots'"!="" {
	local knot `knots'
	local knots
}
if `degree'>3 | `degree'<0 | `degree'==2 {
	di as err "degree must be either 0,1, or 3"
	exit 198
}
if `degree'==3 local orthog orthog
if `alpha'<=0 | `alpha'>1 {
	di as err "alpha() must lie between 0 and 1"
	exit 198
}
if "`constant'"=="noconstant" {
	if "`cmd'"=="fit" | "`cmd'"=="cox" | "`cmd'"=="stcox" {
		di as err "noconstant invalid with `cmd'"
		exit 198
	}
	local options "`options' noconstant"
}
if "`report'"!="" local all all
marksample touse
markout `touse' `dead'
/*
	With `all', estimation is restricted to `touse' subsample,
	but spline transformation is computed on all available values
*/
if "`all'"!="" {
	local restrict restrict(`touse')
	local splinegen_touse 1
}
else local splinegen_touse `touse'

frac_cox "`dead'" `dist'
local small 1e-6
if "`y'"!="" {
	gettoken y rest : varlist
	gettoken rhs base : rest
	local rest
}
else gettoken rhs base : varlist

if "`knot'"!="" {
	if `df'!=4 di as text "[Note: df(`df') ignored]"
	local df: word count `knot'
	local df=`df'+(`degree'!=0)
}
else local dfopt df(`df')

if `degree'==0 & `df'==1 & "`linear'"=="" local linear 0
else local linear 1

tempvar x
quietly {
	if "`dead'"!="" local options "`options' dead(`dead')"
/*
	Deal with weights.
*/
	frac_wgt `"`exp'"' `touse' `"`weight'"'
	local mnlnwt = r(mnlnwt) // mean log normalized weights
	local wgt `r(wgt)'
	gen double `x'=`rhs' if `touse'
	count if `touse'
	local nobs=r(N)
}
// Report effect sizes (differences on spline curve) at values in report.
if "`report'"!="" {
	local nrep: word count `report'
	local n1=_N+1
	local nplus=_N+`nrep'
	qui set obs `nplus'
	local j 1
	forvalues i=`n1'/`nplus'{
		local X: word `j' of `report'
		qui replace `rhs'=`X' in `i'
		local ++j
	}
}
/*
	Determine residual and model df.
*/
if `dist'!=7 {
	qui regress `y' `base' `wgt' if `touse'
	local rdf=e(df_r)+("`constant'"=="noconstant")
}
else local rdf `nobs'
if `df'<1 | `df'>=`rdf' {
	di as err "invalid df()"
	exit 198
}
/*
	Calc deviance=-2(log likelihood) for regression on covars only,
	allowing for possible weights.

	Note that for logit/logistic with nocons, must regress on zero,
	otherwise get r(102) error.
*/
if `dist'==1 & "`constant'"=="noconstant" {
	tempvar z0
	qui gen `z0'=0
}
qui `cmd' `y' `z0' `base' `wgt' if `touse', `options'
if `glm' {
/*
	Note: with Stata 8 scale param is e(phi); was e(delta) in Stata 6
	Also e(dispersp) has become e(dispers_p).
*/
		local scale 1
		if abs(e(dispers_p)/e(phi)-1)>`small' & abs(e(dispers)/e(phi)-1)>`small' {
			local scale = e(phi)
		}
}
frac_dv `normal' "`wgt'" `nobs' `mnlnwt' `dist' `glm' `xtgee' `qreg' "`scale'"
local dev0 = r(deviance)
/*
	Linear
*/
qui `cmd' `y' `x' `base' `wgt' if `touse', `options'
frac_dv `normal' "`wgt'" `nobs' `mnlnwt' `dist' `glm' `xtgee' `qreg' "`scale'"
local devlin=r(deviance)
local n1 1
local n2=`rdf'-`n1'
local devdiff=`dev0'-`devlin'
frac_pv `normal' "`wgt'" `nobs' `devdiff' `n1' `n2'
local Plin=r(P)
local P `Plin'
local deva `devlin'
local devsat `devlin'
local knots linear
local knotsel linear
local varlist `rhs'
// linear vs null, giving P-value Pfull
local dd=`dev0'-`devlin'
frac_pv `normal' "`wgt'" `nobs' `dd' `n1' `n2'
local Pfull=r(P)
/*
	Note: if degree 0 is chosen with df=1 then no selection is performed.
	If df>1 and selection drops all knots then linear model is chosen.
*/
local kadded 0	// number of knots added to linear
if `df'>1 {
	if "`dfopt'"!=""&"`equal'"!="" {	// ignore unique option
		qui sum `x' if `touse'
		local xmin=r(min)
		local xmax=r(max)
		local nk=`df'-(`degree'!=0)
		local R=`xmax'-`xmin'
		forvalues i=1/`nk' {
			local k=`xmin'+`R'*`i'/(`nk'+1)
			local kk: di %9.0g `k'
			local knot `knot' `kk'
		}
		local dfopt
	}
/*
	Form basis and obtain knots
*/
	tempname zz
	qui splinegen `x' `knot' if `splinegen_touse', ///
	 `dfopt' basis(`zz') deg(`degree') `unique' `orthog' `restrict'
	local basis `r(names)'
	local zbasis `r(names)'
	local knots `r(knots)'
	local nk: word count `knots'
	// Fit full spline model and compare with null model
	qui `cmd' `y' `basis' `base' `wgt' if `touse', `options'
	frac_dv `normal' "`wgt'" `nobs' `mnlnwt' `dist' `glm' `xtgee' `qreg' "`scale'"
	local deva=r(deviance)
	local dfa=`rdf'-`df'
	local devsat `deva'
	// Spline vs null, giving P-value Pfull
	local dd=`dev0'-`devsat'
	local n1 `df'
	local n2=`rdf'-`n1'
	frac_pv `normal' "`wgt'" `nobs' `dd' `n1' `n2'
	local Pfull=r(P)
	if "`trace'"!="" {
		di as text "  Knot    Deviance   Loss   P"
		di as res "  All " _col(11) %7.3f `devsat' _col(21) " 0.000" _col(29) " ."
	}
/*
	PR new code. Closed test procedure.
*/
	local finished 0
	if `degree'>0 {
		//  Test full spline vs. linear.
		local dd=`devlin'-`deva'
		local dfn=`df'-1	// numerator df for testing spline vs linear
		frac_pv `normal' "`wgt'" `nobs' `dd' `dfn' `dfa'
		local Pn=r(P)
		if "`trace'"!="" {
			di as res "Linear" _col(11) %7.3f `devlin' ///
			 _col(21) %6.3f `dd' _col(29) %4.3f `Pn'
		}
		if `alpha'==1 {
			// No knot selection requested
			local varlist `basis'
			local knotsel `knots'
			local kadded `nk'
			local finished 1

		}
		else if `Pn'>=`alpha' {
			// No sig improvement with spline, linear selected
			local varlist `rhs'
			local knotsel linear
			if "`trace'"!="" {
				di as text "-"
				di as text "Finishing with linear"
			}
			local finished 1
		}
		else if `df'==2 {
			// no need to consider further knots since have 1 knot and it is significant
			local varlist `basis'
			local knotsel `knots'
			local kadded 1
			local finished 1
		}
	}
	if !`finished' {
		// Consider adding knots to linear or if degree=0 to null model
		local kiav	// indexes of available knots
		local nkiav `nk'
		forvalues i=1/`nk' {
			local kiav `kiav' `i'
		}
		local knotsel	// accumulated knots as forward-stepwise testing proceeds
		local done 0
		while !`done' & `nkiav'>0 {
			local devbest=1e30
			local ibest 0
			// Find best knot among candidates
			forvalues i=1/`nkiav' {
				if "`trace'"!="" & `i'==1 {
					di as text "-"
					di as text "`nkiav' candidate knots considered"
				}
				local ind: word `i' of `kiav'
				local knoti: word `ind' of `knots'
				qui splinegen `x' `knotsel' `knoti' if `splinegen_touse', ///
				 `orthog' deg(`degree') basis(`zz') `restrict'
				local zbasis `r(names)'
				qui `cmd' `y' `r(names)' `base' `wgt' if `touse', `options'
				frac_dv `normal' "`wgt'" `nobs' `mnlnwt' `dist' ///
				 `glm' `xtgee' `qreg' "`scale'"
				local devn=r(deviance)
				if "`trace'"!="" {
					local dd=`devn'-`deva'
					local dfn=`df'-1-(`kadded'+1)
					frac_pv `normal' "`wgt'" `nobs' `dd' `dfn' `dfa'
					di as res %7.2f `knoti' _col(11) %7.3f `devn' ///
					 _col(21) %6.3f `dd' _col(29) %4.3f r(P)
				}
				if `devn'<`devbest' {
					local devbest `devn'
					local ibest `ind'
					local iknot `knoti'
				}
			}
			// Test augmented model against full spline
			local dd=`devbest'-`deva'
			local dfn=`df'-1-(`kadded'+1)
			frac_pv `normal' "`wgt'" `nobs' `dd' `dfn' `dfa'
			local Pn=r(P)
			local ++kadded
			local knotsel `knotsel' `iknot'
			if `Pn'<`alpha' {
/*
	Add this knot and seek extra knot.
	Remove knot index from list of available knots.
*/
				local kiav: list kiav - ibest
				local --nkiav
				if "`trace'"!="" {
					di as text "-"
					di "Adding knot at `iknot' and continuing search."
				}
			}
			else {
				// Done
				local done 1
				if "`trace'"!="" {
					di as text "-"
					di as text "Adding knot at `iknot' and stopping search."
				}
			}
		}
	}
	cap drop `zbasis'
	if `kadded'>0 {
		qui splinegen `rhs' `knotsel' if `splinegen_touse', `orthog' deg(`degree') `restrict'
		local varlist `r(names)'
	}
	local n1=`kadded'+(`degree'>0)
	local n2=`rdf'-`n1'
}
else if !`linear' {
	qui splinegen `rhs' if `splinegen_touse', `orthog' deg(0) df(1) `restrict'
	local varlist `r(names)'
	local knotsel `r(knots)'
	local n1 1
	local n2=`rdf'-1
}
`cmd' `y' `varlist' `base' `wgt' if `touse', `options'
frac_dv `normal' "`wgt'" `nobs' `mnlnwt' `dist' `glm' `xtgee' `qreg' "`scale'"
local deva=r(deviance)
local devdiff=`dev0'-`deva'
frac_pv `normal' "`wgt'" `nobs' `devdiff' `n1' `n2'
local P=r(P)
if !`linear' {
	local devsat `deva'
}
di as text "Deviance:  " as res _col(12) %7.3f `deva' ///
 as text ". Best knots:  " as res "`knotsel'"

// Compute effect sizes and SEs
if "`report'"!="" {
	di as txt _n "{hline 17}{c TT}{hline 47}" ///
	 _n %12s abbrev("`rhs'", 16) ///
	 _col(18)"{c |}  Difference   Std. Err.   [$S_level% Conf. Interval]" ///
	 _n "{hline 17}{c +}{hline 47}"
	tempname b V diff var se l u X Diff Se
	matrix `b'=e(b)
	matrix `V'=e(V)
	local nrow=`nrep'-1
	matrix `X'=J(`nrow',2,0)
	matrix `Diff'=J(`nrow',1,0)
	matrix `Se'=J(`nrow',1,0)
	local m: word count `varlist'
	local tail=(1-$S_level/100)/2
	if `dist'==0 local t=invttail(e(df_r),`tail')
	else local t=invnorm(1-`tail')
	// Store FP(x) values in first additional row
	local row=`nplus'-`nrep'+1
	forvalues i=1/`m' {
		local fpx: word `i' of `varlist'
		tempname x1`i' x2`i'
		scalar `x1`i''=`fpx'[`row']
	}
	local ++row
	local extra 1			// counts the points at which evaluation is required
	forvalues j=`row'/`nplus' {
		scalar `diff'=0
		scalar `var'=0
		forvalues i=1/`m' {
			local fpx: word `i' of `varlist'
			scalar `x2`i''=`fpx'[`j']
			scalar `diff'=`diff'+`b'[1, `i']*(`x2`i''-`x1`i'')
			scalar `var'=`var'+`V'[`i', `i']*(`x2`i''-`x1`i'')^2
		}
		if `m'>1 {
			forvalues i=1/`m' {
				local i1=`i'+1
				forvalues k=`i1'/`m' {
					scalar `var'=`var'+2*`V'[`i', `k']* ///
					 (`x2`i''-`x1`i'')*(`x2`k''-`x1`k'')
				}
			}
		}
		scalar `se'=sqrt(`var')
		scalar `l'=`diff'-`t'*`se'
		scalar `u'=`diff'+`t'*`se'
		local ix `extra'
		local X1: word `extra' of `report'
		local ++extra
		local X2: word `extra' of `report'
		matrix `X'[`ix',1]=`X1'
		matrix `X'[`ix',2]=`X2'
		matrix `Diff'[`ix',1]=`diff'
		matrix `Se'[`ix',1]=`se'
		di as text ///
		  %8.0g `X1' "-" %-8.0g `X2' _col(18) "{c |}" ///
		 _col(21)  as res %9.0g `diff'	  ///
		 _col(33)  as res %9.0g `se'	  ///
		 _col(47)  %9.0g `l' ///
		 _col(57)  %9.0g `u'
		forvalues i=1/`m' {
			scalar `x1`i''=`x2`i''
		}
	}
	di as txt "{hline 17}{c BT}{hline 47}"
	local row=`nplus'-`nrep'+1
	qui drop in `row'/l
	ereturn matrix repx=`X'
	ereturn matrix repdiff=`Diff'
	ereturn matrix repse=`Se'
}
/*
	Output
*/
global S_1 `varlist'
global S_2 `knotsel'
/*
	New code in v 1.1.6 for consistency with mfracpol
*/
ereturn scalar fp_d0 = `dev0'
ereturn scalar fp_dlin = `devlin'

local nbase: word count `base'
forvalues i=1/`nbase' {
	local j=`i'+1
	ereturn local fp_x`j' : word `i' of `base'
	ereturn local fp_k`j' 1
}
ereturn local fp_x1 `rhs'
ereturn local fp_k1 `knotsel'
ereturn scalar fp_kadd=`kadded'
if `degree'>0 {
	ereturn local fp_c1 1
}
/*
	End of new code in v 1.1.6 for consistency with mfracpol
*/
ereturn scalar fp_nx = `nbase'+1
ereturn scalar fp_dsat=`devsat'
ereturn scalar fp_dev=`deva'
ereturn scalar fp_dd=`devdiff'
ereturn scalar fp_P=`P'
ereturn scalar fp_Pful=`Pfull'
ereturn scalar fp_Plin=`Plin'
ereturn local fp_base `base'
ereturn scalar fp_df=`df'
ereturn scalar fp_fdf=`n1'	/* df of final model */
ereturn scalar fp_rdf=`rdf'
ereturn local fp_depv `y'
ereturn local fp_xp `varlist'
ereturn local fp_fvl `varlist' `base'
ereturn local fp_wgt "`weight'"
ereturn local fp_wexp "`exp'"
ereturn scalar fp_N=`nobs'
ereturn local fp_opts `options'
ereturn local fp_rhs `rhs'
ereturn local fp_t1t "Regression Spline"
ereturn local fp_pwrs `knotsel'
ereturn scalar fp_dist = `dist'
ereturn local  fp_cmd "fracpoly"
ereturn local  fp_cmd2 "fracpoly"
end
