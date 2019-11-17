*! version 4.2.0       25 Apr 2006        Mark Stewart
program define redpace
	version 8
	syntax varlist [if] [in] [ , I(string) T(string) Rep(integer 10)  /*
		*/  Seg(integer 1) FROM(string) Halton Primes(name)  /*
		*/  Drop(integer 0) SEED(integer 0) RNT MAvg NOauto ]
	gettoken y 0 : 0
	gettoken xvars 0 : 0 , parse("(")
	gettoken zspec 0 : 0 , parse(",")
	gettoken zvars : zspec , match(parns)
	xt_iis `i'
	local i "$S_1"
	xt_tis `t'
	local t "$S_1"
	tempvar touse notuse x w last gap nper
	mark `touse' `if' `in'
	markout `touse' `y' `i' `t'
	gen byte `notuse' = (`touse'~=1)

/* Check if outcome varies */
	quietly count if `touse'
	local n = r(N)
	quietly count if `y'==0 & `touse'
	local n0 = r(N)
	if `n0'==0 | `n0'==`n' {
		di _n in blu "Outcome does not vary"
		exit
	}

/* Sort data */
	sort `notuse' `i' `t'
	quietly by `notuse' `i': gen `last' = (_n==_N) if `touse'==1
	
/* Check if usable data forms balanced panel */
	quietly by `notuse' `i': gen `gap' = `t'-`t'[_n-1] if `touse'==1 & _n>1
	quietly count if `gap'~=1 & `gap'~=.
	local n0 = r(N)
	if `n0'~=0 {
		di _n in blu "Usable data not balanced"
		exit
	}
	quietly by `notuse' `i': gen `nper' = _N if `touse'==1 & _n==1
	quietly su `nper' if `touse'==1 & _n==1
	local tmax = r(max)
	if r(min)~=`tmax' {
		di _n in blu "Usable data not balanced"
		exit
	}
	local tx1 = `tmax'-1

if "`halton'" != "" {
	sort `notuse' `last' `i' `t'
	tempname ps
	mat `ps' = `primes'
	local m = colsof(`ps')
	if `m'<`tx1' {
		di _n as error "Too few primes"
		exit
	}
	if `m'>`tx1' {
		di _n in gre "Only first " `tx1' " of specified primes used"
		mat `ps' = `ps'[1,1..`tx1']
	}
	mdraws if `touse' & `t'==1, neq(`tx1') draws(`rep') prefix(alph) primes(`ps') burn(`drop') replace
	forvalues r = 1/`rep' {
		qui gen mu1`r' = alph1_`r'
		forvalues j = 2/`tx1' {
			qui by `notuse' `last' `i': replace mu1`r' = alph`j'_`r'[1] if `t'==`j'
		}
	}
	di in gre "Halton draws complete"
}

else {
	di in green "Pseudo-random number draws: # of replications = " in yell `rep'
	if `seed'==0 {
		set seed 81234567
		di "Seed set to " in yell  "81234567" 
	}
	else {
		set seed `seed'
		di "Seed set to " in yell %10.0f `seed' 
	}
	if `seg'==1 & "`rnt'"=="" {
		di in gre "Standard sampling"
		forvalues r = 1/`rep' {
			qui gen mu1`r'=uniform() if `touse' & `t'~=`tmax'
		}
	}
	if `seg'==1 & "`rnt'" != "" {
		di in gre "Standard sampling by t"
		forvalues r = 1/`rep' {
			qui gen mu1`r'=uniform() if `touse' & `t'==1
		}
		local jmax = `tmax'-1
		forvalues j = 2/`jmax' {
			forvalues r = 1/`rep' {
				qui replace mu1`r'=uniform() if `touse' & `t'==`j'
			}
		}
	}
	


	if `seg'>1 {
		if (mod(`rep',`seg')~=0 | mod(`seg',2)~=0) {
			di "#reps must be multiple of #segs & #segs must be " /*
			*/ "multiple of 2."
			exit
		}
		if (`seg'~=2 & `seg'~=4) {
			di "Only 2 or 4 segs currently allowed with symmetric systematic sampling"
			exit
		}
		di "Symmetric systematic sampling (with antithetics), # of segments = " `seg'
		local rs=int(`rep'/`seg')
		local r2=int(`rep'/2)
		forvalues r = 1/`rs' {
			qui gen mu1`r'=uniform() if `touse' & `t'~=`tmax'
		}
		if `seg'==4 {
			forvalues r = 1/`rs' {
				local rx = `rs' + `r'
				qui gen mu1`rx' = mu1`r'+ 0.25 - (0.5*mod(int(4*mu1`r'),2)) if `touse' & `t'~=`tmax'
			}
		}
		forvalues r=1/`r2' {
			local rq = `r'+`r2'
			qui gen mu1`rq' = 1 - mu1`r' if `touse' & `t'~=`tmax'
		}
	}
su mu1*
}
	sort `notuse' `i' `t'

/* Set up macros for ml function. */
	global S_sample "`touse'"
	global S_ivar   "`i'"
	global S_tvar   "`t'"
	global S_rep    "`rep'"
	global S_TT     "`tmax'"
	
	tempname Cmat
	matrix `Cmat' = I(`tmax')
	global S_C "`Cmat'"

/* Set up initial values. */
	tempname llrho0 b0 b00 b1 b ll V b2
	if "`from'"=="" {
	di _n in gr "Pooled Probit Model for t>1"
	probit `y' `xvars' if `touse' & `t'>1
	scalar `llrho0' = _result(2)
	matrix `b0' = get(_b)
	matrix coleq `b0' = `y'

	di _n in gr "Probit Model for t=1"
	probit `y' `zvars' if `touse' & `t'==1
	scalar `llrho0' = `llrho0'+_result(2)
	matrix `b00' = get(_b)
	matrix coleq `b00' = rfper1
	matrix `b0' = `b0' , `b00'

	if "`mavg'" == "" & "`noauto'" == "" {
		matrix `b1' = (-0.5, 0, 0)
		matrix colnames `b1' = logitlam:_cons atar1:_cons ltheta:_cons
		}
	if "`mavg'" == "" & "`noauto'" != "" {
		matrix `b1' = (-0.5, 0)
		matrix colnames `b1' = logitlam:_cons ltheta:_cons
		}
	if "`mavg'" != "" & "`noauto'" == "" {
		matrix `b1' = (-0.5, 0, 0)
		matrix colnames `b1' = logitlam:_cons ma1:_cons ltheta:_cons
		}
	matrix `b0' = `b0' , `b1'
	}
	else {
	mat `b0' = `from'
	}

	sort `touse' `i' `t'

/* Set up ml commands. */
      if "`mavg'" == "" & "`noauto'" == "" {
	di _n in gr "Iterations for full ML estimation"
	ml model d0 redsar_ll (`y': `y' = `xvars') (rfper1: `zvars') /*
	*/ (logitlam:) (atar1:) (ltheta:) if `touse', miss nopreserve /*
	*/ title("RE Dynamic Probit Model with AR1 errors") /*
	*/ init(`b0') search(off) maximize trace grad
	ml display, neq(2) plus
	_diparm logitlam, prob
	_diparm atar1, prob
	_diparm ltheta, prob
	di in smcl in gr "{hline 13}{c +}{hline 64}"
	_diparm logitlam, label("lambda") ilogit prob
	_diparm atar1, label("ar1") tanh prob
	_diparm ltheta, label("theta") exp prob
	di in smcl in gr "{hline 13}{c BT}{hline 64}"
      }

      if "`mavg'" == "" & "`noauto'" != "" {
	di _n in gr "Iterations for full ML estimation"
	ml model d0 redsnoau_ll (`y': `y' = `xvars') (rfper1: `zvars') /*
	*/ (logitlam:) (ltheta:) if `touse', miss nopreserve /*
	*/ title("RE Dynamic Probit Model, no auto, MSL") /*
	*/ init(`b0') search(off) maximize trace grad
	ml display, neq(2) plus
	_diparm logitlam, prob
	_diparm ltheta, prob
	di in smcl in gr "{hline 13}{c +}{hline 64}"
	_diparm logitlam, label("lambda") ilogit prob
	_diparm ltheta, label("theta") exp prob
	di in smcl in gr "{hline 13}{c BT}{hline 64}"
      }

      if "`mavg'" != "" & "`noauto'" == "" {
	di _n in gr "Iterations for full ML estimation"
	ml model d0 redsma_ll (`y': `y' = `xvars') (rfper1: `zvars') /*
	*/ (logitlam:) (ma1:) (ltheta:) if `touse', miss nopreserve /*
	*/ title("RE Dynamic Probit Model with MA1 errors") /*
	*/ init(`b0') search(off) maximize trace grad
	ml display, neq(2) plus
	_diparm logitlam, prob
	_diparm ma1, prob
	_diparm ltheta, prob
	di in smcl in gr "{hline 13}{c +}{hline 64}"
	_diparm logitlam, label("lambda") ilogit prob
	_diparm ma1, label("ma1") prob
	_diparm ltheta, label("theta") exp prob
	di in smcl in gr "{hline 13}{c BT}{hline 64}"
      }

end
	
