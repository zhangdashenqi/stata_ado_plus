*----------------------------------------------------------------------------
*! version 0.8.3 16apr2014 14:11
program femlogit, eclass properties(svyb or) sortpreserve
   version 11.0
   syntax varlist [if] [in] [, GRoup(varlist) Baseoutcome(passthru) /*
   */ CONSTraints(numlist) DIFFicult OR Robust]
   
   // process group indicator
   if `"`group'"'=="" {
     capture quietly _xt
     if _rc!=0 {
       noisily display as error "must specify panelvar; use xtset"
       quietly error 459
     }
     else {
       local group `r(ivar)'
     }
   }
   
   // process odds ratio option
   if "`or'"!="" {
     local eform eform
     local coeftitle "Odds Ratio"
   }
   
   // missings
   marksample touse
   markout `touse' `varlist' `group', strok
   
   // remove collinear variables, handle basecategory (following mlogit.ado)
   quietly _rmcoll `varlist' if `touse', mlogit `baseoutcome'
   
   // Results stored in locals and matrix (following mlogit.ado)
   local varlist `"`r(varlist)'"'
   // outcome vector (baseoutcome inclusive)
   tempname out
   matrix `out' = r(out)
   // vector position of baseoutcome in vector out
   local ibase = r(ibaseout)
   // Number of outcomes (baseoutcome inclusive)
   local nout = r(k_out)
   // Error if only one outcome
   if (`nout' == 1) { 
      error 148
   }
  
   // split depvar from varlist
   gettoken lhs rhs : varlist
   local nindeps `:list sizeof rhs'

   // matsize-check: Error if matsize to small (taken from mlogit)
   if `nout'*`nindeps' > c(matsize) {
      error 908
   }

   // matrix out2eq for Mata
   tempname out2eq
   matrix `out2eq'=J(`nout',2,0)
   local j=1
   forvalues i=1/`nout' {
      matrix `out2eq'[`i',1]=`out'[1,`i']
      if `i'!=`ibase' {
         matrix `out2eq'[`i',2]= `j'
         local j=`j'+1
      }
   }

   // Ignore offending observations/groups.
   // Taken from clogit.ado version 1.6.14 19may2010 and adjusted
   /* `vv' /// */
   cap noi CheckGroups `lhs' `group' `touse' `rhs' /*`wgt', `offopt'*/
   if _rc {
      exit _rc
   }
   local rhs `"`r(varlist)'"'
   local n `r(N)'
   local ng `r(ng)'
   local n_drop `r(n_drop)'
   local ng_drop `r(ng_drop)'
   // not supported
   // local multiple `r(multiple)'
   /* not supported
   if !`r(useoffset)' {
      local offopt
   }
   */
      
   // calculation of baseline log.likelihood (=ll0 (inverse of number of 
   // permutations)) (inspired by clogit.ado version 1.6.14)
   // necessary for model w/o indep. var.'s and baseline for LR-test
   tempname ll0 v1 v2
   sort `touse' `group' `lhs'
   // Number of measurements $T_i$ for each observation unit $i$
   quietly by `touse' `group': gen double `v1'=_n if `touse'
   quietly by `touse' `group': replace `v1'=`v1'[_N] if `touse' & _n==1
   quietly by `touse' `group': replace `v1'=. if `touse' & _n!=1
   // $\ln((T_i)!)$
   quietly replace `v1'=lnfactorial(`v1') if `touse'
   // Number of chosen outcomes $\delta_{y_{it}=j}$
   quietly by `touse' `group' `lhs': gen double `v2'=_n if `touse'
   quietly by `touse' `group' `lhs': replace `v2'=`v2'[_N] if `touse' & _n==1
   quietly by `touse' `group' `lhs': replace `v2'=. if `touse' & _n!=1
   // $\ln((k_{ij})!)$
   quietly replace `v2'=lnfactorial(`v2') if `touse'
   // $\ln((k_{i1})!)+\dots+\ln((k_{iJ})!)=\ln((k_{i1})!*\dots*(k_{iJ})!)$
   quietly by `touse' `group': replace `v2'=sum(`v2') if `touse'
   quietly by `touse' `group': replace `v2'=`v2'[_N] if `touse' & _n==1
   quietly by `touse' `group': replace `v2'=. if `touse' & _n!=1
   // Number of permutations for each i = $|\Upsilon_i|$
   quietly by `touse': replace `v1'=sum(`v1'-`v2') if `touse'
   scalar `ll0'=-`v1'[_N]
   drop `v1' `v2'

   // init values (only if indep.vars given)
   // inspired by clogit's "Check for initial values"
   // (init values are coef's from pooled mlogit)
   if `nindeps'>0 {
      quietly mlogit `lhs' `rhs' if `touse', b(`=`out'[1,`ibase']')
      tempname aux2 init
      // matrix 1 row, (#indep.vars + constant) x (#outcomes) cols
      matrix `aux2'=e(b) 
      // Cols of init matrix (1 row, #indep.vars x (outcomes-1) cols
      local aux1=((colsof(`aux2')/`nout')-1)*(`nout'-1)
      matrix `init'=J(1,`aux1',0)
      // build init matrix
      local i2=1
      forvalues i=1/`nout' {
         if `i'!=`ibase' { /* loop over outcomes except base category */
            local j2=1
            forvalues j=1/`=colsof(`aux2')/`nout'' {
                /* loop over indep. variables + constant except const */
               if `j'!=`=colsof(`aux2')/`nout'' {
                  matrix `init'[1,`=((`i2'-1)*(colsof(`aux2')/`nout'-1))+ /*
                  */ `j2'']=`aux2'[1,`=((`i'-1)*colsof(`aux2')/`nout')+`j'']
                  local j2=`j2'+1
               }
            }
            local i2=`i2'+1
         }
      }
      matrix drop `aux2'
   }
   
   // Constraint handling for moptimize
   // (only if indep. vars given)
   if `nindeps'>0 & `"`constraints'"'!="" {
      // dummy beta-vector & V-matrix
      tempname b V T a C cnsmat
      matrix `b'=J(1,`=(`nout'-1)*`nindeps'',0)
      // Column names necessary for constraint matrix creation
      matrix roweq `b'="_"
      matrix rownames `b'="y1"
      forvalues i=1/`nout' {
         if `i'!=`ibase' {
            foreach var in `rhs' {
               local eqlist `eqlist' `=abbrev(strtoname("`:label (`lhs') `=`out'[1,`i']''",0),12)'
               local namelist `namelist' `var'
            }
         }
      }
      matrix coleq `b'=`eqlist'
      matrix colnames `b'=`namelist'
      matrix `V'=`b''*`b'
      
      // ereturn post
      quietly ereturn post `b' `V'
      
      // create matrices for transformation of reduced-form to unreduced-form 
      // vectors/matrices
      noisily _makecns `constraints'
      capture quietly local i=r(clist)==""
      // _rc==0 -> r(clist) string -> at least 1 constr correctly specified
      // _rc==109 -> r(clist) not string -> no constr correctly specified
      if _rc==0 { /* all fine, at least one constraint survived */
         matrix `cnsmat'=e(Cns)
         quietly matcproc `T' `a' `C'
      }
      if _rc!=0 { /* all constraints dropped */
         di as txt "(note: all constraints are dropped,"
         di as txt "       switched to unconstrained estimation,"
         di as txt "       check constraint specification.)"
         matrix `cnsmat'=J(1,1,.)
         matrix `T'=J(1,1,.)
         matrix `a'=J(1,1,.)
         matrix `C'=J(1,1,.)   
         local constraints=""
      }
   }
   if `nindeps'>0 & `"`constraints'"'=="" {
      tempname cnsmat T a C
      matrix `cnsmat'=J(1,1,.)
      matrix `T'=J(1,1,.)
      matrix `a'=J(1,1,.)
      matrix `C'=J(1,1,.)
   }
   
   // Sorting before evaluator call (if indep.vars given)
   if `nindeps'>0 {
      sort `touse' `group'
   }
   
   // moptimize-call with mata-evaluator (if indep.vars given)
   if `nindeps'>0 {
      tempname rvm Vmata
      // Most parts in mata
      noisily di "" /* single line skip for aesthetic reasons */
      mata: moptcall()

      // Estimation is done, post results in e() macros
      if "`robust'"!="" {
         ereturn repost V=`rvm'
         ereturn matrix V_modelbased=`Vmata'
      }

      // Rest with results from moptcall()
      // Scalars
      ereturn scalar k_eq_model=`nout'-1 /* number of eq's in overall model test */
      if "`constraints'"=="" {
         ereturn scalar ll_0=`ll0' /* log-likelihood w/o indep. var's, not defined w/ constraints */
      }
      ereturn scalar df_m=`=cond("`constraints'"!="",colsof(`T'),(`nout'-1)*`nindeps')' /* model degrees of freedom w/ constraints taken into account */
      if "`constraints'"=="" & "`robust'"=="" {
         ereturn scalar chi2=2*(e(ll)-`ll0') /* LR chi2, not defined w/ constraints */
         ereturn scalar p=chi2tail(e(df_m),e(chi2)) /* significance */
      }
      if "`constraints'"!="" | "`robust'"!="" {
         tempname chi2temp
         mata: st_matrix(st_local("chi2temp"),st_matrix("e(b)")* /*
         */ pinv(st_matrix("e(V)"))*st_matrix("e(b)")') 
         ereturn scalar chi2=`chi2temp'[1,1] /* Wald chi2, only defined w/ constraints */
         ereturn scalar p=chi2tail(e(df_m),e(chi2)) /* significance */
      }
      if "`n_drop'"!="" {
	       ereturn scalar N_drop=`n_drop' /* # of obs dropped bec. of invariant dep. var's */
         ereturn scalar N_group_drop=`ng_drop' /* # of groups dropped bec. of invariant dep. var's */
      }
      if "`constraints'"=="" {
         ereturn scalar r2_p=1-e(ll)/e(ll_0) /* pseudo-R-squared, not defined w/ constraints */
      }
      if "`constraints'"!="" {
         ereturn scalar r2_p=.
      }
      ereturn scalar ibaseout=`ibase' /* index of base outcome ($B$) */
      ereturn scalar baseout=`=`out'[1,`ibase']' /* value of base outcome ($o_B$) */
      ereturn scalar k_out=`nout' /* number of outcomes */
      // Macros
      ereturn local crittype=cond("`robust'"!="","log pseudolikelihood","log likelihood") /* optimization criterion */
      ereturn local title="Fixed-effects multinomial logistic regression" /* title in est. output */
      if "`robust'"=="" { /* var.-covar.-matrix derived from observed information matrix */
         ereturn local vce="oim"
      }
      if "`robust'"!="" {
         ereturn local vce="robust"
         ereturn local vcetype="Robust"
      }
      if "`constraints'"=="" & "`robust'"=="" {
         ereturn local chi2type="LR" /* model chi2 test is LR-test, only w/o constraints */
      }
      if "`constraints'"!="" | "`robust'"!="" {
         ereturn local chi2type="Wald" /* model chi2 test is Wald-test, only w/ constraints */
      }
      ereturn local group="`group'" /* name of group variable */
      local t1 "`:coleq e(b)'"
      forvalues i=1/`=(`nout'-1)*`nindeps'' {
         if mod(`i',`nindeps')==1 {
            local t2 `t2' `:word `i' of `t1''
         }
      }
      ereturn local eqnames `t2' /* equation names */
      ereturn local marginsok="xb"
      ereturn local marginsnotok="stdp stddp"
      ereturn local predict="_predict"
      ereturn local cmd="femlogit"
      ereturn local cmdline femlogit `0' /* complete command line */
      // Matrices
      ereturn matrix out=`out', copy /* vector of outcome values */
      
      // Display results table (adapted from mprobit)
      noisily _coef_table_header
      if "`constraints'"=="" { /* single line skip for aesthetic reasons */
         noisily di ""
      }
      tempname T
      quietly .`T'   = ._b_table.new
      noisily .`T'.display_titles, depname("`lhs'") cnsreport coeftitle("`coeftitle'")
      local j=1
      forval i = 1/`nout' {
         if `i' == `ibase' {
            .`T'.sep
            .`T'.display_comment "`=abbrev(strtoname("`:label (`lhs') /*
            */ `=`out'[1,`ibase']''",1),12)'", comment("  (base outcome)")
         }
         else {
            .`T'.display_eq #`j', `eform'
            local j=`j'+1
         }
      }
      .`T'.finish
      if (!missing(e(rc)) & e(rc) != 0) error e(rc)
      _prefix_footnote
   }
   
   
   // display of results if no indep. vars given
   if `nindeps'==0 {
      // Fake ml step
      noisily di "" /* single line skip */
      if "`robust'"!="" { /* does not apply */
         noisily display as text "Iteration 0:   log pseudolikelihood = " as result `ll0'
      }
      if "`robust'"=="" {
         noisily display as text "Iteration 0:   log likelihood = " as result `ll0'
      }
      
      // silent clogit to create macros for results (this can be simplified)
      quietly tempvar av
      quietly gen `av'=`lhs'!=`=`out'[1,`ibase']' if `touse'
      quietly clogit `av', group(`group') `robust'
      
      // overwrite results macros with correct values
      ereturn scalar N=`n' /* taken from code line 50ff. */
      ereturn scalar ll_0=`ll0' /* taken from code line 70ff. */
      ereturn scalar ll=`ll0' /* taken from code line 70ff. */
      ereturn scalar df_m=0
      ereturn scalar chi2=0
      ereturn scalar r2_p=0
      ereturn local chi2type="LR"
      ereturn local group="`group'"
      ereturn local properties="b V"
      ereturn local predict="predict"
      ereturn local crittype=cond("`robust'"!="","log pseudolikelihood","log likelihood")
      ereturn local cmd="femlogit"
      ereturn local depvar="`lhs'"
      ereturn local cmdline femlogit `0'
      ereturn repost, esample(`touse')
   
      // Display results table
      noisily _coef_table_header, /*
      */ title(Fixed-effects multinomial logistic regression)
      noisily di "" /* single line skip for aesthetic reasons */
      tempname T
      quietly .`T'   = ._b_table.new
      noisily .`T'.display_titles, depname("`lhs'") coeftitle("`coeftitle'")
      noisily .`T'.sep
      noisily .`T'.finish
   }
end

// Taken from clogit.ado version 1.6.14  19may2010
program CheckGroups, rclass
   local caller = _caller()
   version 8.2, missing
   syntax varlist(fv) [fw iw] [, offset(varname)]
   gettoken y varlist : varlist
   gettoken group varlist : varlist
   gettoken touse xvars : varlist 

   sort `touse' `group'

   // Check weights.
   if "`weight'" != "" {
      tempvar w 
      qui gen double `w'`exp' if `touse'
      cap by `touse' `group':assert `w'==`w'[1] if `touse'
      if _rc {
         error 407
      }   
      if "`weight'"=="fweight" {
         local freq `w'
      }
   }

   // Check at least one good group.
   cap by `touse' `group': assert `y'==`y'[1] if `touse' 
   if !_rc {
      di as txt "outcome does not vary in any group"
      exit 2000 
   }   

   /* does not work directly with femlogit, "sum(`y')" works only with dummy
   // Check for multiple positive outcomes within groups.

   tempvar sumy 
   qui by `touse' `group': gen double `sumy' = cond(_n==_N, ///
      sum(`y'), .) if `touse'
   qui count if `sumy' > 1 & `sumy' < .
   if `r(N)' {
      di as txt "note: multiple positive outcomes within " _c
      di as txt "groups encountered."
      local multiple multiple
   }
   */

   // Delete groups where outcome doesn't vary.
   CountObsGroups `touse' `group' `freq'
   local n_orig = r(n)
   local ng_orig = r(ng)

   tempvar varies rtouse
   qui by `touse' `group': gen byte `varies' = cond(_n==_N, ///
      sum(`y'!=`y'[1]), .) if `touse'
   qui by `touse' `group': gen byte `rtouse' = (`varies'[_N]>0) & `touse'
   qui replace `touse' = `rtouse'
   sort `touse' `group'

   CountObsGroups `touse' `group' `freq'
   local n = r(n)
   local ng = r(ng)
   
   if `n' < `n_orig' {
      if `ng_orig'-`ng' > 1 {
         local s s
      }
      di as txt "note: " `ng_orig'-`ng' " group`s' (" _c
      di as txt `n_orig'-`n' _c 
      di as txt " obs) dropped because of all positive or"
      di as txt "      all negative outcomes."
      local ng_drop   = `ng_orig' - `ng'
      local n_drop   = `n_orig' - `n'
   }

   // Check that each xvar varies in at least 1 group.
   if `"`xvars'"' != "" {
      fvexpand `xvars'
      local xvars "`r(varlist)'"
      foreach v of local xvars {
         _ms_parse_parts `v'
         if r(type) == "variable" & !r(omit) {
             cap by `touse' `group':   ///
            assert `v'==`v'[1] if `touse'
             if !_rc {
            di as txt "note: `v' omitted because of no "_c
            di as txt "within-group variance."      
            if `caller' < 11 {
               local v
            }
            else   local v o.`v'
             }
         }
         local xs `xs' `v'
      }
   }   

   // Check that offset varies in at least 1 group.
   local useoffset 0
   if "`offset'" != "" {
      cap by `touse' `group': assert `offset'==`offset'[1] if `touse'
      if !_rc {
         di as txt "note: offset `offset' omitted " _c
         di as txt "because of no " _c
         di as txt "within-group variance."
      }
      else {
         local useoffset 1
      }
   }

   return local multiple `multiple'
   return local varlist `xs'
   return local useoffset `useoffset'
   return scalar N = `n'
   return scalar ng = `ng'
   if `:length local n_drop' {
      return scalar n_drop = `n_drop'
      return scalar ng_drop = `ng_drop'
   }
end

program CountObsGroups, rclass 
   args touse group freq

   tempvar i
   if "`freq'" == "" {
      qui count if `touse'
      return scalar n = r(N)
      qui by `touse' `group': gen byte `i' = _n==1 & `touse'
      qui count if `i'
      return scalar ng = r(N)
   }
   else {
      qui summ `freq' if `touse', meanonly
      return scalar n = r(sum)
      qui by `touse' `group': gen double `i' = (_n==1&`touse')*`freq'
      qui summ `i' if `touse', meanonly
      return scalar ng = r(sum)
   }
end

// mata function to define ml-problem, call evaluator, maximize, and give results back
mata:
mata set matastrict on
void moptcall(){
   // declare variables
   transmorphic matrix M
   real scalar i,j

   // Initialize moptimize
   M=moptimize_init()

   // Definition of problem
   moptimize_init_touse(M,st_local("touse")) /* sample-indicator */
   moptimize_init_depvar(M,1,st_local("lhs")) /* dep. var. */
   // number of eq's = number of outcomes w/o ref.cat.
   moptimize_init_eq_n(M,strtoreal(st_local("nout"))-1)
   /* indep. vars for each eq. (loop over all outcomes) */
   j=1
   for(i=1;i<=strtoreal(st_local("nout"));i++) {
      if (i!=strtoreal(st_local("ibase"))) { /* take out ref.cat.*/
         // same `rhs' for each equation!
         moptimize_init_eq_indepvars(M,j,st_local("rhs"))
         moptimize_init_eq_cons(M,j,"off") /* no constant */
         // value labels for outcomes = eq. names (for output and matrix names)
         // if dep.var has value label
         if (st_varvaluelabel(st_local("lhs"))!="") {
            moptimize_init_eq_name(M,j,strtoname(st_vlmap( /*
            */ st_varvaluelabel(st_local("lhs")),/*
            */ st_matrix(st_local("out"))[1,i])!="" ? /* if value label string for outcome can be transformed to name
            */ st_vlmap(st_varvaluelabel(st_local("lhs")), /*
            */ st_matrix(st_local("out"))[1,i]) : /* if value label string for outcome cannot be transformed to name
            */ strofreal(st_matrix(st_local("out"))[1,i]),1))
         }
         // if dep.var has no value label
         if (st_varvaluelabel(st_local("lhs"))=="") {
            moptimize_init_eq_name(M,j,strtoname(strofreal( /*
            */ st_matrix(st_local("out"))[1,i]),1))
         }
         j=j+1
      }
   }
   if (st_local("constraints")!="") { /* constraint-matrix */
      moptimize_init_constraints(M,st_matrix(st_local("cnsmat"))) 
   }
   moptimize_init_technique(M,"nr") /* maximization technique: modified Newton–Raphson */
   if (st_local("difficult")!="") {
      moptimize_init_singularHmethod(M, "hybrid") /* if the Hessian is found to be singular: Hybrid method instead of modified marquardt (default) */
   }
   // init-value
   // indep. vars for each eq (loop over all outcomes except ref.cat.)
   for(i=1;i<=strtoreal(st_local("nout"))-1;i++) {
      moptimize_init_eq_coefs(M,i,rowshape(st_matrix(st_local("init")), /*
      */ strtoreal(st_local("nout"))-1)[i,.]) /* initial value, taken from pooled mlogit w/o constant */
   }
   moptimize_init_search(M,"off") /* initial value are not improved by search methods */
   moptimize_init_valueid(M,st_local("robust")==""?"log likelihood":"log pseudolikelihood") /* label of objective function */

   // Evaluator
   moptimize_init_evaluator(M,&femlogit_eval_gf2()) /* define evaluator */
   moptimize_init_evaluatortype(M,"gf2") /* define evaluator type */
      
   // Maximize
   moptimize(M)
   
   // Post results to Stata in e() macros
   st_eclear() /* clear all existing e() macros */
   moptimize_result_post(M) /* post results in e() macros */

   // Preparation for posting of all results in e() macros
   if (st_local("robust")!="") {
      st_matrix(st_local("Vmata"),st_matrix("e(V)"))
      st_matrixrowstripe(st_local("rvm"),st_matrixrowstripe("e(V)"))
      st_matrixcolstripe(st_local("rvm"),st_matrixcolstripe("e(V)"))
   }
   st_numscalar("e(ll)",moptimize_result_value(M)) /* push overall log-likelihood in macro e(ll) */
}
end
