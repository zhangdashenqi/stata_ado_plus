*! version 1.1.1 PR 23sep2005.
*
* History of ice
* 1.1.1 23sep2005 Better error trapping for passive() and substitute() options.
* 1.1.0 23aug2005 Replace -draw- option with -match-. Default becomes draw.
*		  Trace option documented, now has argument for filename.
*		  Report number of rows with 0, 1, 2, ... missing values.
*		  Arrange variables in increasing order of missingness when imputing.
*		  Split ties at random when more than one observation satisfies the
*		  prediction matching criterion
* 1.0.4 21jul2005 Trap and report error when running uvis
* 1.0.3 08jun2005 Tidy up display of equations when have multiple lines (long equations)
* 1.0.3 03jun2005 Silence file load/save
* 1.0.2 20may2005 Changed files containing imputations to tempfiles (standalone mode)
*		  (Angela Wood reported problem).
* 1.0.1 04may2005 Added a trace to a file (undocumented in help file).
* 1.0.0 18apr2005 First release, based on mice.
*
* History of mice
* 1.0.3 13apr2005 Minor tidying up, including recode of ChkIn and deletion of strdel.
*		  Check if prediction equations have a variable on both sides.
* 1.0.2 17feb2005 Added code to take care of inherited missingness of passive variables robustly.
* 1.0.1 21jan2005 Added display of regression command in showing prediction equations.
* 1.0.0 20jan2005 First release, based on mvis2/_mvis2.
*
* History of mvis
* 1.1.0 18jan2005 categoric() option removed.
*		  New options dryrun, passive(), substitute(), eq() added.
*		  Improvements to output showing actual prediction equations.
* 1.0.5 19nov2004 Delete dummy variables for categoric() variables with no missing data from output file
*		  Found problem with bsample in Stata 7 with "if" clause and boot option.
*		  Revert to Stata 8 for mvis, _mvis and uvis.
* 1.0.4 18nov2004 Weights not working (syntax error), fixed.
* 1.0.3 16nov2004 Categoric() option added to deal with unordered categoric
*		  covariates, updated default handling of such variables
* 1.0.2 16oct2004 Saving, using etc of file safest with compound quotes, fixed.
*
program define ice, rclass
version 8
* Check for _I* variables, could be created by xi:
capture describe _I*
if _rc==0 {
	di as err _n "Warning: _I* variables detected in the dataset - was xi: used?"
	di as inp "Use of xi: with mvis is liable to give incorrect results."
	di as inp "If you wish to model categoric covariates with dummy"
	di as inp "variables, please recalculate the dummies via the passive() option"
	di as inp "and use the substitute() option to identify the dummies as predictors." _n
}
local m `s(MI_m)'
if "`m'"!="" {
	* Called by mi_impute
	local mitools mitools
	local mopt
	local uopt
	local fn0 `s(MI_tfile)'
	local using `fn0'
	forvalues i=1/`m' {
		local fn`i' `s(MI_tfile`i')'
	}
}
else {
	* standalone
	local mitools
	local mopt "m(int 1)"
	local uopt [using/]
}

syntax varlist(min=2 numeric) [if] [in] [aweight fweight pweight iweight] `uopt', /*
 */ [ `mopt' REPLACE Seed(int 0) BOot MAtch DRYrun * ]

* Check if there are variables called boot and/or match
if "`boot'"=="boot" {
	cap confirm var boot
	if _rc local options `options' boot(`varlist')
	else local options `options' boot(boot)
}
if "`match'"=="match" {
	cap confirm var match
	if _rc local options `options' match(`varlist')
	else local options `options' match(match)
}
if `seed'>0 set seed `seed'
local first first
if "`dryrun'"!="" {
	if `"`using'"'=="" {
		tempname fn
		local using `fn'
	}
	_ice `varlist' `if' `in' [`weight' `exp'] using `using', `options' first dryrun
	di as text _n "End of dry run. No imputations were done, no files were created."
	exit
}
preserve
if "`mitools'"=="" {
	if `m'<1 {
		di as err "number of imputations must be 1 or more"
		exit 198
	}
	if `"`using'"'=="" {
		if "`dryrun'"=="" {
			di as err "using required"
			exit 100
		}
	}
	else {
		if substr(`"`using'"',-4,.)!=".dta" {
			local using `using'.dta
		}
		if "`replace'"=="" {
			confirm new file `"`using'"'
		}
	}
	forvalues i=1/`m' {
		tempfile fn`i'
		_ice `varlist' `if' `in' [`weight' `exp'] using `fn`i'', `options' `first'
		di as text `i' ".."  _cont
		local first
	}
	* Join files of imputations vertically using code from mijoin.ado
	quietly {
		local J _j
		forvalues j=1/`m' {
			* could automate this part
			use `"`fn`j''"', clear
			chkrowid
			local I `s(I)'
			if "`I'"=="" {
				* create row number
				local I _i
				cap drop `I'
				gen long `I'=_n
				lab var `I' "obs. number"
			}
			cap drop `J'
			gen int `J'=`j'
			lab var `J' "imputation number"
			save `"`fn`j''"', replace
		}
		use `"`fn1'"', clear
		forvalues j=2/`m' {
			append using `"`fn`j''"'
		}
		char _dta[mi_id] `I'
	}
	save `"`using'"', `replace'
}
else {
	* Save original data and imputations to tempfiles for mi_impute to stack
	* fn0,...,fn`m' are local macros created by mi_impute and supplied as s() functions;
	* they contain the actual names of tempfiles, hence the need for compound quotes.
	local original original
	forvalues i=0/`m' {
		if "`replace'"!="" cap drop `"`fn`i''"'	// !! bug - should be erase not cap drop?
		_ice `varlist' `if' `in' [`weight' `exp'] using `"`fn`i''"', ///
		 `options' `first' `original' mitools
		di as text `i' ".."  _cont
		local original
		if `m'>0 local first
	}
}
end

program define chkrowid, sclass
version 8
local I: char _dta[mi_id]
if "`I'"=="" exit
cap confirm var `I'
if _rc exit
sret local I `I'
end

*! Based on _mvis2 version 1.0.2 PR 19jan2005.
program define _ice, rclass
version 8
syntax varlist(min=2 numeric) [if] [in] [aw fw pw iw] using/, /*
 */ [ BOot(varlist) CC(varlist) CMd(string) CYcles(int 10) noCONStant MAtch(varlist) /*
 */ DRYrun EQ(string) first Genmiss(string) Id(string) mitools ON(varlist) original /*
 */ PASsive(string) noSHoweq SUBstitute(string) TRace(string) ]

if "`original'"!="" {
	* Save original data
	quietly save `"`using'"', replace
	exit
}

local nvar: word count `varlist'
if "`id'"!="" {
	confirm new var `id'
}
else local id _i

preserve
tempvar touse order
quietly {
	marksample touse, novarlist
	if "`cc'`on'"!="" {
		markout `touse' `cc' `on'
	}

* Record sort order
	gen long `order'=_n
	lab var `order' "obs. number"

* For standard operation (no `on' list), disregard any completely missing rows in varlist, among marked obs
	if "`on'"=="" {
		tempvar rmis
		egen int `rmis'=rmiss(`varlist') if `touse'==1
		count if `rmis'==0
		replace `touse'=0 if `rmis'==`nvar'
		replace `rmis'=. if `rmis'==`nvar'
		lab var `rmis' "#missing values"
		if "`first'"!="" & "`showeq'"=="" noi tab `rmis', missing
		drop `rmis'
	}
* Deal with weights
	frac_wgt `"`exp'"' `touse' `"`weight'"'
	local wgt `r(wgt)'

* Sort out cmds (not checking if each cmd is valid - any garbage may be entered)
	if "`cmd'"!="" {
		* local cmds "regress logistic logit ologit mlogit"
		detangle "`cmd'" cmd "`varlist'"
		forvalues i=1/`nvar' {
			if "${S_`i'}"!="" {
				local cmd`i' ${S_`i'}
			}
		}
	}

* Default for all uvis operations is nomatch, meaning draw
	if "`match'"!="" {
		tokenize `match'
		while "`1'"!="" {
			ChkIn `1' "`varlist'"
			if `s(k)'>0 {
				local match`s(k)' match
			}
			mac shift
		}
	}

	if "`boot'"!="" {
		tokenize `boot'
		while "`1'"!="" {
			ChkIn `1' "`varlist'"
			if `s(k)'>0 {
				local boot`s(k)' boot
			}
			mac shift
		}
	}
	local anyerr 0
	if `"`passive'"'!="" {
		tempvar passmiss
		/*
		   Defines vars that are functions or transformations of others in varlist.
		   They are (may be) "passively imputed". "\" is an expression separator.
		   Default is comma.
		   Comma may not always be appropriate (i.e. may appear in an expression).
		*/
		detangle "`passive'" passive "`varlist'" \
		local haserr 0
		forvalues i=1/`nvar' {
			if "${S_`i'}"!="" {
				local exp`i' ${S_`i'}
				ParsExp `exp`i''
				local exclude `s(result)'
				if "`exclude'"!="" {
					* Count missingness of this passive variable
					egen int `passmiss'=rmiss(`exclude') if `touse'
					count if `passmiss'>0 & `touse'==1
					local nimp`i'=r(N)
					if `nimp`i''==0 {
						local v: word `i' of `varlist'
						noi di as err "passive definition `v' = (${S_`i'}) redundant: `exclude' has no missing data."
						local ++haserr
					}
					drop `passmiss'
				}
			}
		}
		if `haserr'>0 {
			di as err "`haserr' error(s) found in option " as inp "passive(`passive')"
			local anyerr 1
		}
	}
	if "`substitute'"!="" {
		* defines vars that are to be substituted in the recalc context
		detangle "`substitute'" substitute "`varlist'"
		local haserr 0
		forvalues i=1/`nvar' {
			if "${S_`i'}"!="" {
				local sub`i' ${S_`i'}
				local v: word `i' of `varlist'
				count if missing(`v') & `touse'==1
				if r(N)==0 {
					noi di as err "substitute for variable `v' redundant: `v' has no missing data."
					local ++haserr
				}
			}
		}
		if `haserr'>0 {
			noi di as err "`haserr' error(s) found in option " as inp "substitute(`substitute')"
			local anyerr 1
		}
	}
	if `"`eq'"'!="" {
		* defines equations specified vars.
		detangle "`eq'" equation "`varlist'"
		forvalues i=1/`nvar' {
			if "${S_`i'}"!="" {
				local Eq`i' ${S_`i'}
				* Check that eq vars are in mainvarlist
				tokenize `Eq`i''
				while "`1'"!="" {
					ChkIn `1' "`varlist'"
					mac shift
				}
			}
		}
	}
	if `anyerr' {
		di as err _n "specification error(s) found."
		exit 198
	}
	count if `touse'
	local n=r(N)
/*
	Count potentially imputable missing values for each variable,
	and where necessary create an equation for each
*/
	local to_imp 0	// actual number of vars with missing values to be imputed
	local recalc 0	// number of passively imputed vars to be recalculated
	tempvar xtmp	// temporary holding area
	local nimp	// list of number of missing values for each variable
	forvalues i=1/`nvar' {
		local xvar: word `i' of `varlist'
		if "`genmiss'"!="" {
			tempvar mvar`i'
			gen byte `mvar`i''=missing(`xvar') if `touse'==1
			lab var `mvar`i'' "1 if `xvar' missing, 0 otherwise"
		}
		local x`i' `xvar'
		count if missing(`xvar') & `touse'==1
		* Create prediction equation for each active variable
		if r(N)>0 & `"`exp`i''"'=="" {
			local nimp`i'=r(N)
			* active var: has missing obs, not passive
			local ++to_imp
			local main`i' 1
			* Keep missingness of the original variable
			tempvar miss`i'
			gen byte `miss`i''=missing(`xvar') if `touse'==1
			* Define equation for this variable - user definition from eq() takes precedence
			if "`Eq`i''"!="" {
				local eq`i' `Eq`i''
			}
			else {
				* Remove variable from mainvarlist
				local eq`i': list varlist - xvar
			}
			if "`cmd`i''"=="" {
/*
	Assign default cmd for vars not so far accounted for.
	cmd is relevant only for vars requiring imputation, i.e. with >=1 missing values.
	Use logit if 2 distinct values, mlogit if 3-5, otherwise regress.
*/
				inspect `xvar' if `touse'
				local nuniq=r(N_unique)
				if `nuniq'==1 {
					noi di as err "only 1 distinct value of `xvar' found"
					exit 2000
				}
				if `nuniq'==2 {
					count if `xvar'==0 & `touse'==1
					if r(N)==0 {
						noi di as err "variable `xvar' unsuitable for imputation,"
						noi di as err "binary variables must include at least one 0 and one non-missing value"
						exit 198
					}
					local cmd`i' logit
				}
				else if `nuniq'<=5 {
					local cmd`i' mlogit
				}
				else local cmd`i' regress
			}
			if "`cmd`i''"=="mlogit" {
				* With mlogit, if xvar carries a score label,
				* drop it since it causes prediction problems
				local xlab: value label `xvar'
				capture label drop `xlab'
			}
			if "`on'"=="" {
				* Initially fill missing obs cyclically with nonmissing obs
				sampmis `xtmp'=`xvar'
				replace `xvar'=cond(`touse'==0, ., `xtmp')
				drop `xtmp'
			}
			else replace `xvar'=. if `touse'==0
			local lab`i' `xvar' imput.`suffix' (`nimp`i'' values)
		}
		else {
			local main`i' 0
			if "`nimp`i''"=="" {	// may have been set earlier by consideration of ParsExp
				local nimp`i'=r(N)
			}
			if `"`exp`i''"'!="" {
				if "`Eq`i''"!="" {
					noi di as err "equation" as input " `xvar':`Eq`i'' " ///
					 as err "invalid, `xvar' is passively imputed"
					exit 198
				}
				local ++recalc
			}
		}
		local nimp `nimp' `nimp`i''
	}
	if `to_imp'==0 {
		noi di as err _n "All relevant cases are complete, no imputation required."
		return scalar N=`n'
		return scalar imputed=0
		exit 2000
	}
* Remove passivevars from equations as necessary
	forvalues i=1/`nvar' {
		if `"`exp`i''"'!="" {
			ParsExp `exp`i''
			local exclude `s(result)'
			* remove current passivevar from each relevant equation
			local passive `x`i''
			tokenize `exclude'
			while "`1'"!="" {
				* identify which variable in mainvarlist we are looking at
				ChkIn `1' "`varlist'"
				local index `s(k)'
				* Remove `passive' from equation of variable
				* whose index in mainvarlist is `index'
				* (only allowed to be done if there is no
				* user equation Eq`' for var #`index')
				if "`eq`index''"!="" & "`Eq`index''"=="" {
					local eq`index': list eq`index' - passive
				}
				mac shift
			}
		}
	}
	if "`substitute'"!="" {
		forvalues i=1/`nvar' {
			if `main`i'' & "`sub`i''"!="" {
				* substitute for this variable in all equations where it is a covariate
				forvalues j=1/`nvar' {
					if `main`j'' & (`j'!=`i') & "`Eq`j''"=="" {
						local res: list eq`j' - x`i'
						* substitute sub`i' if necessary i.e. if not already there
						tokenize `sub`i''
						while "`1'"!="" {
							cap ChkIn `1' "`res'"
							if "`s(k)'"=="0" {
								local res `res' `1'
							}
							mac shift
						}
						local eq`j' `res'
					}
				}
			}
		}
	}
	* Show prediction equations at first imputation
	if "`first'"!="" {
		local errs 0
		local longstring 55	// max display length of variables in equation
		local off 13		// blanks to col 13 on continuation lines
		if "`showeq'"=="" {
			noi di as text _n "   Variable {c |} Command {c |} Prediction equation" _n ///
			 "{hline 12}{c +}{hline 9}{c +}{hline `longstring'}"
		}
		forvalues i=1/`nvar' {
			if "`exp`i''"!="" & `nimp`i''>0 {
				local eq "[Passively imputed from `exp`i'']"
				local formatoutput 0
			}
			else if "`eq`i''"=="" {
				local eq "[No missing data in estimation sample]"
				local formatoutput 0
			}
			else {
				local eq `eq`i''
				local formatoutput 1
			}
			if "`showeq'"=="" {
				if `formatoutput' {
					formatline, n(`eq') maxlen(`longstring')
					local nlines=r(lines)
					forvalues j=1/`nlines' {
						if `j'==1 noi di as text %11s abbrev("`x`i''",11) ///
						 " {c |} " %-8s "`cmd`i''" "{c |} `r(line`j')'"
						else noi di as text _col(`off') ///
						 "{c |}" _col(23) "{c |} `r(line`j')'"
					}
				}
				else noi di as text %11s abbrev("`x`i''",11) ///
				 " {c |} " %-8s "`cmd`i''" "{c |} `eq'"
			}
			// Check for invalid equation - xvar on both sides
			if "`eq`i''"!="" {
				if `: list x`i' in eq`i'' {
					noi di as err "Error!" as inp " `x`i''" ///
					 as err " found on both sides of prediction equation"
					local ++errs
				}
			}
		}
		if `errs' {
			di as err _n `errs' " error(s) found. Consider using the passive() option to fix the problem"
			exit 198
		}
		if "`dryrun'"!="" {
			exit
		}
		noi di as text _n "Imputing " _cont
	}
	if `to_imp'==1 | "`on'"!="" {
		local cycles 1
	}
* Update recalculated variables
	if `"`passive'"'!="" & `recalc'>0 {
		forvalues i=1/`nvar' {
			if "`exp`i''"!="" {
				replace `x`i''=`exp`i''
			}
		}
	}
* Impute sequentially `cycles' times by regression switching (van Buuren et al)
	tempvar y imputed
	* Sort variables on number of missing values, from low to high numbers.
	* Of benefit to the mice algorithm since less missings get imputed first.
	listsort "`nimp'"
	forvalues i=1/`nvar' {
		local r`i' `s(index`i')'
	}
	if `"`trace'"'!="" {
		tempname tmp
		* create names
		local postvl cycle
		forvalues r=1/`nvar' {
			local i `r`r''	// antirank: vars with small #missing come first
			if `main`i'' local postvl `postvl' `x`i''_mean
		}
		postfile `tmp' `postvl' using `"`trace'"', replace
	}
	forvalues j=1/`cycles' {
		if `"`trace'"'!="" local posts (`j')
		forvalues r=1/`nvar' {
			local i `r`r''	// antirank, ensuring vars with small #missing come first
			if `main`i'' {
				* Each var is reimputed based on imputed values of other vars
				local type: type `x`i''
				gen `type' `y'=`x`i'' if `miss`i''==0 & `touse'==1
				if "`on'"=="" {
					local vars `eq`i''
				}
				else local vars `on'
				* uvis is derived from uvisamp4.ado
				cap uvis `cmd`i'' `y' `vars' `wgt' if `touse', ///
				 gen(`imputed') `boot`i'' `match`i'' `constant'
				if _rc {
					noi di as err _n(2) "Error running -uvis-"
					noi di as err "I detected a problem with running uvis with command `cmd`i'' on response `x`i''"
					noi di as err "and covariates `vars'."
					if "`cmd`i''"=="mlogit" {
						noi di as inp "The troublesome regression command is mlogit."
						noi di as inp "Try reducing the number of categories of `x`i'' or using ologit if appropriate"
					}
					exit 198
				}
				if `"`trace'"'!="" {
					summarize `imputed' if missing(`y') & `touse'==1
					local mean=r(mean)
					local posts `posts' (`mean')
/*
					noi di as text %11s abbrev("`x`i''",10) %7.0g `mean' _cont
					foreach v of var `vars' {
						if "`v'"=="`x`i''" {
							noi di as result "       ." _cont
						}
						else noi di as result _skip(1) %7.0g _b[`v'] _cont
					}
					noi di
*/
				}
				replace `x`i''=`imputed'
				drop `y' `imputed'
			}
		}
		if `"`trace'"'!="" post `tmp' `posts'
		if `recalc'>0 {	// update covariates needing recalculation
			forvalues i=1/`nvar' {
				if "`exp`i''"!="" & `nimp`i''>0 {
					replace `x`i''=`exp`i''
				}
			}
		}
		if `to_imp'==1 & "`first'"!="" {
			noi di as text _n "[Only 1 variable to be imputed, therefore no cycling needed.]"
		}
	}
}
if `"`trace'"'!="" postclose `tmp'
* Save to file with cases in original order
quietly {
	local impvl	/* list of newvars containing imputations */
	sort `order'
	forvalues i=1/`nvar' {
		return scalar ni`i'=`nimp`i''
		if "`genmiss'"!="" {
			cap drop `genmiss'`x`i''
			rename `mvar`i'' `genmiss'`x`i''
		}
		if `main`i'' {
			local impvl `impvl' `x`i''
			lab var `x`i'' "`lab`i''"
			cap drop `miss`i''
		}
	}
	drop `touse'
	if "`mitools'"=="" {
		* Save list of imputed variables with imputations to char _dta[mi_ivar]
		char _dta[mi_ivar] `impvl'
		char _dta[mi_id] `id'
		rename `order' `id'
		return local impvl `impvl'
		return scalar imputed=`to_imp'
	}
	else drop `order'
	save `"`using'"', replace
}
end

*! v 1.0.0 PR 01Jun2001.
program define sampmis
version 7
* Duplicates nonmissing obs of `exp' into missing ones, in random order.
* This routine always reproduces the same sort order among the missings.
* Note technique to avoid Stata creating arbitrary sort order for missing
* observations of `exp'; affects entire reproducibility of mvi sampling.
syntax newvarname =/exp
quietly {
	tempvar u
	* Sort non-missing data at random, sort missing data systematically
	gen double `u'=cond(missing(`exp'), _n, uniform())
	sort `u'
	count if !missing(`exp')
	local nonmis=r(N)
	drop `u'
	local type: type `exp'
	gen `type' `varlist'=`exp'
	local blocks=int((_N-1)/`nonmis')
	forvalues i=1/`blocks' {
		local j=`nonmis'*`i'
		local j1=`j'+1
		local j2=min(`j'+`nonmis',_N)
		replace `varlist'=`exp'[_n-`j'] in `j1'/`j2'
	}
}
end

program define ChkIn, sclass
version 7
* Returns s(k) = index # of target variable v in varlist, or 0 if not found.
args v varlist
sret clear
local k: list posof "`v'" in varlist
sret local k `k'
if `s(k)'==0 {
   	di as err "`v' is not a valid covariate"
   	exit 198
}
end

*! version 1.0.0 PR 20dec2004.
program define ParsExp, sclass
version 8
tokenize `*', parse(" +-/^()[]{}.*=<>!$%&|~`'")
local vl
while "`1'"!="" {
	cap confirm var `1'
	if _rc==0 {
		if index("`vl'", "`1'")==0 {
			local vl `vl' `1'
		}
	}
	mac shift
}
sreturn local result `vl'
end

program define detangle
version 8
/*
	Disentangle varlist:string clusters---e.g. for DF.
	Returns values in $S_*.
	If `4' is null, `3' is assumed to contain rhs
	and lowest and highest value checking is disabled.
	Heavily based on frac_dis.ado, but "=" disallowed as separator
	and "\" allowed (for use by passive()).
*/
args target tname rhs separator
if "`separator'"=="" {
	local separator ","
}
unab rhs:`rhs'
local nx: word count `rhs'
forvalues j=1/`nx' {
	local n`j': word `j' of `rhs'
}
tokenize "`target'", parse("`separator'")
local ncl 0 			/* # of separator-delimited clusters */
while "`1'"!="" {
	if "`1'"=="`separator'" {
		mac shift
	}
	local ncl=`ncl'+1
	local clust`ncl' "`1'"
	mac shift
}
if "`clust`ncl''"=="" {
	local --ncl
}
if `ncl'>`nx' {
	di as err "too many `tname'() values specified"
	exit 198
}
/*
	Disentangle each varlist:string cluster
*/
forvalues i=1/`ncl' {
	tokenize "`clust`i''", parse(":")
	if "`2'"!=":" {
		if `i'>1 {
			noi di as err "invalid `clust`i'' in `tname'() (syntax error)"
			exit 198
		}
		local 2 ":"
		local 3 `1'
		local 1
		forvalues j=1/`nx' {
			local 1 `1' `n`j''
		}
	}
	local arg3 `3'
	unab arg1:`1'
	tokenize `arg1'
	while "`1'"!="" {
		ChkIn `1' "`rhs'"
		local v`s(k)' `arg3'
		mac shift
	}
}
forvalues j=1/`nx' {
	if "`v`j''"!="" {
		global S_`j' `v`j''
	}
	else global S_`j'
}
end

*! Based on artformatnos.ado v 1.0.0 PR 26Feb2004
program define formatline, rclass
version 8
syntax, N(string) Maxlen(int) [ Format(string) Leading(int 1) Separator(string) ]

if `leading'<0 {
	di as err "invalid leading()"
	exit 198
}

if "`separator'"!="" {
	tokenize "`n'", parse("`separator'")
}
else tokenize "`n'"

local n 0
while "`1'"!="" {
	if "`1'"!="`separator'" {
		local ++n
		local n`n' `1'
	}
	macro shift
}
local j 0
local length 0
forvalues i=1/`n' {
*noi di in red "format=`format' i=`i' item=`n`i''"
	if "`format'"!="" {
		capture local out: display `format' `n`i''
		if _rc {
			di as err "invalid format attempted for: " `"`n`i''"'
			exit 198
		}
	}
	else local out `n`i''
	if `leading'>0 {
		local out " `out'"
	}
	local l1=length("`out'")
	local l2=`length'+`l1'
	if `l2'>`maxlen' {
		local ++j
		return local line`j'="`line'"
		local line "`out'"
		local length `l1'
	}
	else {
		local length `l2'
		local line "`line'`out'"
	}
}
local ++j
return local line`j'="`line'"
return scalar lines=`j'
end
*! version 1.1.0 PR 02aug2005.
program define listsort, sclass
version 6
gettoken p 0 : 0, parse(" ,")
if `"`p'"'=="" {
	exit
}
sret clear
syntax , [ Reverse Lexicographic ]
local lex="`lexicog'"!=""
if "`reverse'"!="" { local comp < }
else local comp >
local np: word count `p'
local i 1
while `i'<=`np' {
	local p`i': word `i' of `p'
	local index`i' `i'
	if !`lex' { confirm number `p`i'' }
	local i=`i'+1
}
* Apply shell sort (Kernighan & Ritchie p 58)
local gap=int(`np'/2)
while `gap'>0 {
	local i `gap'
	while `i'<`np' {
		local j=`i'-`gap'
		while `j'>=0 {
			local j1=`j'+1
			local j2=`j'+`gap'+1
			if `lex' { local swap=(`"`p`j1''"' `comp' `"`p`j2''"') }
			else local swap=(`p`j1'' `comp' `p`j2'')
			if `swap' {
				local temp `p`j1''
				local p`j1' `p`j2''
				local p`j2' `temp'
				* swap indexes
				local temp `index`j1''
				local index`j1' `index`j2''
				local index`j2' `temp'
			}
			local j=`j'-`gap'
		}
		local i=`i'+1
	}
	local gap=int(`gap'/2)
}
local p
local index
local i 1
while `i'<=`np' {
	sret local i`i' `p`i''
	sret local index`i' `index`i''
	local p `p' `p`i''
	local index `index' `index`i''
	local i=`i'+1
}
/* Find antirank of each obs
forvalues i=1/`np' {
	forvalues j=1/`np' {
		if 
*/
sret local list `p'
sret local index `index'
end
exit

		sort `c'
		local i 0
		while `i'<`nx' {
			local i=`i'+1
/*
	Store positions of sorted predictors in user's list
*/
			local j 0
			while `j'<`nx' {
				local j=`j'+1
				if `i'==`n'[`j'] {
					local r`j' `i'
					local j `nx'
				}
			}
		}
