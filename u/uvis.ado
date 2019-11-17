*! version 1.1.0 PR 30aug2005.
*
* Recent history of uvis
* 1.1.0 03aug2005 Replace -draw- option with -match-. Default becomes draw.
*		  With prediction matching, randomly sort observations with identical predictions.
*		  Order variables in chained equations in order of increasing missingness.		  
* 1.0.4 21jun2005 Add sort, stable to enable reproducibility imputations with given seed
*
program define uvis, rclass sortpreserve
version 8
gettoken cmd 0 : 0
if substr("`cmd'",1,3)=="reg" {
	local cmd regress
}

local normal=("`cmd'"=="regress")|("`cmd'"=="rreg")
local binary=("`cmd'"=="logit")|("`cmd'"=="logistic")
local catcmd=("`cmd'"=="mlogit")|("`cmd'"=="ologit")

if !`normal' & !`binary' & !`catcmd' {
	di in red "invalid or unrecognised command, `cmd'"
	exit 198
}

syntax varlist(min=2 numeric) [if] [in] [aweight fweight pweight iweight] , Gen(string) /*
*/ [ noCONStant Delta(real 0) BOot MAtch REPLACE SEed(int 0) * ]

if "`replace'"=="" {
	confirm new var `gen'
}

if "`match'"=="match" {
	di as text "[imputing by prediction matching" _cont
}
else di as text "[imputing by drawing from conditional distribution" _cont
if "`boot'"=="" {
	di as text " without bootstrap]"
}
else di as text " with bootstrap]"

if "`constant'"=="noconstant" {
	local options "`options' nocons"
}
gettoken y xvars : varlist
tempvar touse
quietly {
	marksample touse, novarlist
	markout `touse' `xvars'	/* note: does not include `y' */

	if `seed'!=0 {
		set seed `seed'
	}

* Deal with weights
	frac_wgt `"`exp'"' `touse' `"`weight'"'
	local wgt `r(wgt)'

* Code types of missings: 1=non-missing y, 2=missing y, 3=other missing
	tempvar obstype yimp
	gen byte `obstype'=1*(`touse'==1 & !missing(`y')) /*
	 */ 		  +2*(`touse'==1 &  missing(`y')) /*
	 */		  +3*(`touse'==0)

	count if `obstype'==1
	local nobs=r(N)
	count if `obstype'==2
	local nmis=r(N)

	local type: type `y'
	gen `type' `yimp'=.

* Fit imputation model
	`cmd' `y' `xvars' `wgt', `options'
	tempname b e V chol bstar
	tempvar xb u
	matrix `b'=e(b)
	matrix `e'=e(b)
	matrix `V'=e(V)
	local colsofb=colsof(`b')
* Check for zeroes on the diagonal of V and replace them with 1. 
* Otherwise this makes the matrix non-positive definite.
* Occurs when e.g. logit drops variables, giving zero variances.
* !! Is this safe to do?
	if diag0cnt(`V')>0 {
		forvalues j=1/`colsofb' {
			if `V'[`j',`j']==0 {
				matrix `V'[`j',`j']=1
			}
		}
	}
	matrix `chol'=cholesky(`V')
	if `catcmd' {
		tempname cat
		local nclass=e(k_cat)	/* number of classes in (ordered) categoric variable */
		matrix `cat'=e(cat)	/* row vector giving actual category values */
		local cuts=`nclass'-1
	}
	* Draw beta, and if necessary rmse, for proper imputation
	if `normal' {
		* draw rmse
		local rmse=e(rmse)
		local df=e(df_r)
		local chi2=2*invgammap(`df'/2,uniform())
		local rmsestar=`rmse'*sqrt(`df'/`chi2')
		matrix `chol'=`chol'*sqrt(`df'/`chi2')
	}
	* draw beta
	forvalues i=1/`colsofb' {
		matrix `e'[1,`i']=invnorm(uniform())
	}
	matrix `bstar'=`b'+`e'*`chol''

	if "`boot'"=="" {
* Based on Ian White's code to implement van Buuren et al (1999).
		* draw y
		gen `u'=uniform()
		if `normal' | `binary' {
			* in normal or binary case, impute by sampling conditional distribution
			* or by prediction matching
			if "`match'"=="match" {
				* prediction matching
				tempvar etaobs etamis
				matrix score `etaobs'=`b' if `obstype'==1
				matrix score `etamis'=`bstar' if `obstype'==2
				* Include non-response location shift, delta.
				if `delta'!=0 {
					replace `etamis'=`etamis'+`delta'
				}
				match_normal `obstype' `nobs' `nmis' `etaobs' `etamis' `yimp' `y'
			}
			else {
				* sampling conditional distribution
				matrix score `xb'=`bstar' if `touse'
				if `normal' {
					replace `yimp'=`xb'+`rmsestar'*invnorm(`u')
				}
				else replace `yimp'=`u'<1/(1+exp(-`xb')) if !missing(`xb')
			}
		}
		else {	/* catcmd */
			if "`match'"=="match" {	// prediction matching
				* predict class-specific probabilities and convert to logits
				if "`cmd'"=="ologit" {
					* Predict index independent of cutpoints
					* (note use of forcezero option to circumvent missing _cut* vars)
					matrix score `xb'=`b' if `touse', forcezero
					* predict cumulative probabilities for obs data and hence logits of class probs
					forvalues k=1/`nclass' {
						tempvar etaobs`k' etamis`k'
						if `k'==`nclass' {
							gen `etaobs`nclass''=log((1-`p`cuts'')/`p`cuts'') if `obstype'==1
						}
						else {
							tempvar p`k'
							local cutpt=`b'[1, `k'+`colsofb'-`cuts']
							*  1/(1+exp(-... is probability of being in category 1 or 2 or ... k
							gen `p`k''=1/(1+exp(-(`cutpt'-`xb')))
							if `k'==1 {
								gen `etaobs`k''=log(`p`k''/(1-`p`k'')) if `obstype'==1
							}
							else {
								local k1=`k'-1
								gen `etaobs`k''=log((`p`k''-`p`k1'')/(1-(`p`k''-`p`k1''))) /*
								 */ if `obstype'==1
							}
						}
					}
					drop `xb'
					matrix score `xb'=`bstar' if `touse', forcezero
					* predict cumulative probabilities for missing data and hence logits of class probs
					forvalues k=1/`nclass' {
						if `k'==`nclass' {
							gen `etamis`nclass''=log((1-`p`cuts'')/`p`cuts'') if `obstype'==2
						}
						else {
							local cutpt=`bstar'[1, `k'+`colsofb'-`cuts']
							replace `p`k''=1/(1+exp(-(`cutpt'-`xb')))
							if `k'==1 {
								gen `etamis`k''=log(`p`k''/(1-`p`k'')) if `obstype'==2
							}
							else {
								local k1=`k'-1
								gen `etamis`k''=log((`p`k''-`p`k1'')/(1-(`p`k''-`p`k1''))) /*
								 */ if `obstype'==2
							}
						}
					}
				}
				else {	/* mlogit */
					* predict cumulative probabilities for obs data and hence logits of class probs
					* care needed dealing with different possible base categories
					tempvar sumexp
					local basecat=e(basecat)	/* actual basecategory chosen by Stata */
					gen `sumexp'=0 if `touse'
					forvalues k=1/`nclass' {
						tempvar etaobs`k' etamis`k' xb`k'
						local thiscat=`cat'[1,`k']
						if `thiscat'==`basecat' {
							gen `xb`k''=0 if `touse'
						}
						else matrix score `xb`k''=`b' if `touse', equation(`thiscat')
						replace `sumexp'=`sumexp' + exp(`xb`k'')
					}
					forvalues k=1/`nclass' {
						* formula for logit of class prob derived from Pk in Stata mlogit entry
						gen `etaobs`k''=`xb`k''-log(`sumexp'-exp(`xb`k'')) if `obstype'==1
					}
					* same for missing obs
					replace `sumexp'=0
					forvalues k=1/`nclass' {
						cap drop `xb`k''
						local thiscat=`cat'[1,`k']
						if `thiscat'==`basecat' {
							gen `xb`k''=0 if `touse'
						}
						else matrix score `xb`k''=`bstar' if `touse', equation(`thiscat')
						replace `sumexp'=`sumexp' + exp(`xb`k'')
					}
					forvalues k=1/`nclass' {
						* formula for logit of class prob derived from Pk in Stata mlogit entry
						gen `etamis`k''=`xb`k''-log(`sumexp'-exp(`xb`k'')) if `obstype'==2
					}
				}
				* match
				sort `obstype', stable
				tempvar order distance
				gen `distance'=.
				gen long `order'=_n
				* For each missing obs j, find index of obs whose etaobs is closest to prediction [j].
				forvalues i=1/`nmis' {
					local j=`i'+`nobs'
					* calc summed absolute distances between etamis* and etaobs*
					replace `distance'=0 in 1/`nobs'
					forvalues k=1/`nclass' {
						replace `distance'=`distance'+abs(`etamis`k''[`j']-`etaobs`k'') in 1/`nobs'
					}
					* Find index of smallest distance between etamis* and etaobs*
					sort `distance'
					local index=`order'[1]
					* restore correct order
					sort `order'
					replace `yimp'=`y'[`index'] in `j'
				}
			}
			else {	// draw
				* sampling conditional distribution
				replace `yimp'=`cat'[1,1]
				if "`cmd'"=="ologit" {
					* Predict index independent of cutpoints
					* (note use of forcezero option to circumvent missing _cut* vars)
					matrix score `xb'=`bstar' if `touse', forcezero
					forvalues k=1/`cuts' {
						*  1/(1+exp(-... is probability of being in category 1 or 2 or ... k
						local cutpt=`bstar'[1, `k'+`colsofb'-`cuts']
						replace `yimp'=`cat'[1,`k'+1]  if `u'>1/(1+exp(-(`cutpt'-`xb')))
					}
				}
				else {	/* mlogit */
					* care needed dealing with different possible base categories
					tempvar cusump sumexp
					local basecat=e(basecat)	/* actual basecategory chosen by Stata */
					gen `sumexp'=0 if `touse'
					forvalues i=1/`nclass' {
						tempvar xb`i'
						local thiscat=`cat'[1,`i']
						if `thiscat'==`basecat' {
							gen `xb`i''=0 if `touse'
						}
						else matrix score `xb`i''=`bstar' if `touse', equation(`thiscat')
						replace `sumexp'=`sumexp' + exp(`xb`i'')
					}
					gen `cusump'=exp(`xb1')/`sumexp'
					forvalues i=2/`nclass' {
						replace `yimp'=`cat'[1,`i']  if `u'>`cusump'
						replace `cusump'=`cusump'+exp(`xb`i'')/`sumexp'
						replace `yimp'=. if missing(`xb`i'')
					}
				}
			}
		}
	}
	else {
		* Bootstrap method
		if "`match'"=="match" {	/* match */
			if `catcmd' {
				* predict class-specific probabilities and convert to logits
				forvalues k=1/`nclass' {
					local outk=`cat'[1,`k']
					tempvar etaobs`k' etamis`k'
					predict `etaobs`k'' if `obstype'==1, outcome(`outk') /* probability */
					replace `etaobs`k''=log(`etaobs`k''/(1-`etaobs`k'')) /* logit */
				}
			}
			else {	/* normal and binary cases */
				tempvar etaobs etamis
				predict `etaobs' if `obstype'==1, xb
			}
		}
		* Bootstrap observed data
		tempvar wt
		gen double `wt'=.
		bsample if `obstype'==1, weight(`wt')
		if "`wgt'"!="" {
			replace `wt' `exp'*`wt'
			local w [`weight'=`wt']
		}
		else local w [fweight=`wt']
		`cmd' `y' `xvars' `w', `options'

		if `catcmd' {
			if e(k_cat)<`nclass' {
				di as error "cannot predict outcome for all classes in bootstrap sample;"
				di as error "probably one or more classes has a low frequency in the original data:"
				di as error "try amalgamating small classes of `y' and rerunning"
				exit 303
			}
		}
		if "`match'"=="match" {
			if `catcmd' {
				* predict class-specific probabilities and convert to logits
				forvalues k=1/`nclass' {
					local outk=`cat'[1,`k']
					predict `etamis`k'' if `obstype'==2, outcome(`outk') /* probability */
					replace `etamis`k''=log(`etamis`k''/(1-`etamis`k'')) /* logit */
				}
				* match
				sort `obstype', stable
				tempvar order distance
				gen `distance'=.
				gen long `order'=_n
				* For each missing obs j, find index of obs whose etaobs is closest to prediction [j].
				forvalues i=1/`nmis' {
					local j=`i'+`nobs'
					* calc summed absolute distances between etamis* and etaobs*
					replace `distance'=0 in 1/`nobs'
					forvalues k=1/`nclass' {
						replace `distance'=`distance'+abs(`etamis`k''[`j']-`etaobs`k'') in 1/`nobs'
					}
					* Find index of smallest distance between etamis* and etaobs*
					sort `distance'
					local index=`order'[1]
					* restore correct order
					sort `order'
					replace `yimp'=`y'[`index'] in `j'
				}
			}
			else {	/* normal and binary */
				predict `etamis' if `obstype'==2, xb
	
				* Include non-response location shift, delta.
				if `delta'!=0 {
					replace `etamis'=`etamis'+`delta'
				}
				match_normal `obstype' `nobs' `nmis' `etaobs' `etamis' `yimp' `y'
			}
		}
		else {	// draw
			matrix `bstar'=e(b)
			gen `u'=uniform()
			if `normal' | `binary' {
				matrix score `xb'=`bstar' if `touse'
				if `normal' {
					replace `yimp'=`xb'+e(rmse)*invnorm(`u')
				}
				else replace `yimp'=`u'<1/(1+exp(-`xb')) if !missing(`xb')
			}
			else {	/* catcmd */
				replace `yimp'=`cat'[1,1]
				if "`cmd'"=="ologit" {
					matrix score `xb'=`bstar' if `touse', forcezero
					forvalues k=1/`cuts' {
						*  1/(1+exp(-... is probability of being in category 1 or 2 or ... k
						local cutpt=`bstar'[1, `k'+`colsofb'-`cuts']
						replace `yimp'=`cat'[1,`k'+1]  if `u'>1/(1+exp(-(`cutpt'-`xb')))
					}
				}
				else {	/* mlogit */
					* care needed dealing with different possible base categories
					tempvar cusump sumexp
					local basecat=e(basecat)	/* actual basecategory chosen by Stata */
					gen `sumexp'=0 if `touse'
					forvalues i=1/`nclass' {
						tempvar xb`i'
						local thiscat=`cat'[1,`i']
						if `thiscat'==`basecat' {
							gen `xb`i''=0 if `touse'
						}
						else matrix score `xb`i''=`bstar' if `touse', equation(`thiscat')
						replace `sumexp'=`sumexp' + exp(`xb`i'')
					}
					gen `cusump'=exp(`xb1')/`sumexp'
					forvalues i=2/`nclass' {
						replace `yimp'=`cat'[1,`i']  if `u'>`cusump'
						replace `cusump'=`cusump'+exp(`xb`i'')/`sumexp'
						replace `yimp'=. if missing(`xb`i'')
					}
				}
			}
		}
	}
	cap drop `gen'
	rename `yimp' `gen'
	*replace `gen'=`y' if `obstype'==1
	replace `gen'=`y' if !missing(`y')
	lab var `gen' "imputed from `y'"
}
di _n in ye `nmis' in gr " missing observations on `y' imputed from " /*
 */ in ye `nobs' in gr " complete observations."
end

program define match_normal
* Prediction matching, normal or binary case.
args obstype nobs nmis etaobs etamis yimp y
quietly {
	* For each missing obs j, find index of observation
	* whose etaobs is closest to etamis[j].
	tempvar sumgt
	tempname etamisi
	gen long `sumgt'=.
	* Sort etaobs within obstype 
	sort `obstype' `etaobs', stable
	forvalues i=1/`nmis' {
		local j=`i'+`nobs'
		scalar `etamisi'=`etamis'[`j']
		replace `sumgt'=sum((`etamisi'>`etaobs')) in 1/`nobs'
		sum `sumgt', meanonly
		local j1=r(max)
		if `j1'==0 {
			local index 1
			local direction 1
		}
		else if `j1'==`nobs' {
			local index `nobs'
			local direction -1
		}
		else {
			local j2=`j1'+1
			if (`etamisi'-`etaobs'[`j1'])<(`etaobs'[`j2']-`etamisi') {
				local index `j1'
				local direction -1
			}
			else {
				local index `j2'
				local direction 1
			}
		}
		* In case of tied etaobs values, add random offset to index in the appropriate direction
		count if `obstype'==1 & reldif(`etaobs', `etaobs'[`index'])<1e-7 // counts as equality
		scalar count`i'=r(N)
		if r(N)>1 {
			local index=`index'+`direction'*int(uniform()*r(N))
		}
		replace `yimp'=`y'[`index'] in `j'
	}
}
end
