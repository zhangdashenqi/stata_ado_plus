program resboot_mediation,
  syntax [if] [in] , dv(varname) mv(varname) iv(varname) ///
          [ cv(varlist) reps(integer 100) level(integer 95) ranres]
  mata: mata clear
  local type "Nonparametric resampled residual"
  if "`ranres'"=="ranres" {
    local type "Randomly generated residuals"
  }
  local bign=_N
  if `reps'>_N {
    set obs `reps'
  }

  local ll=(100-`level')/2
  local ul=100-`ll'
  local z1=invnormal(`ul'/100)
  tempvar ya ea yas ybs yb eb ra rb b1 b2 b3
  quietly {
    gen `yas'=.
    gen `ybs'=.
    gen `b1' =.
    gen `b2' =.
    gen `b3' =.
    gen `ra' =.
    gen `rb' =.
    sum `dv'
    local sey = r(sd)
    sum `mv'
    local sem = r(sd)
    sum `iv'
    local sex =  r(sd)
  }
  regress `mv' `iv' `cv' `if' `in'
  local a_coef = _b[`iv']
  local rmse1 = e(rmse)
  quietly { 
    predict `ya'
    predict `ea', resid
    putmata `ea'
  }
  regress `dv' `mv' `iv' `cv' `if' `in'
  local rmse2 = e(rmse)
  local b_coef = _b[`mv']
  local c_coef = _b[`iv']
  local t_eff =  `a_coef'*`b_coef'+`c_coef'
  quietly {
    predict `yb'
    predict `eb', resid
    putmata `eb'
  }
  mata: p=J(rows(`ea'),1,1/rows(`ea'))
  forvalues j=1/`reps' {
    if "`ranres'"=="ranres" {
      quietly replace `ra'=rnormal(0,`rmse1')
      quietly replace `rb'=rnormal(0,`rmse2')
    }
    else {
      mata: i=rdiscrete(rows(`ea'),1,p)
      mata: `ra'=`ea'[i,1]
      mata: `rb'=`eb'[i,1]
      getmata `ra', replace
      getmata `rb', replace
    }
    quietly {
      replace `yas' = `ya' + `ra'
      replace `ybs' = `yb' + `rb'
      regress `yas' `iv' `cv'
    }
    local acoef=_b[`iv']
    quietly {
    regress `ybs' `mv' `iv' `cv'
    replace `b1'=`acoef'*_b[`mv'] in `j'
    replace `b2'=_b[`iv'] in `j'
    replace `b3'=`acoef'*_b[`mv']+_b[`iv'] in `j'
    }
  }
  quietly {
    sum `b1'
    local se1 = r(sd)
    local bias1 = r(mean) - `a_coef'*`b_coef'
    sum `b2'
    local se2 = r(sd)
    local bias2 = r(mean) - `c_coef'
    sum `b3'
    local se3 = r(sd)
    local bias3 = r(mean) - `t_eff'
  }
  
  display
  display as txt "`type' bootstrap of mediation with `reps' replications"
  display
  display as txt _col(33) "Bootstrap"  
  display as txt _col(11) "Coef" _col(24) "Bias" _col(34) "Std Err" _col(45) "[`level'% Conf Interval]"
  _pctile `b1', percentile(`ll' `ul') 
  display as txt "ind eff " as res %8.0g `a_coef'*`b_coef' _col(22) %8.0g  `bias1' _col(32) %8.0g `se1' _col(43) %8.0g r(r1) _col(54) %8.0g r(r2) " (P)"
  quietly count if `b1'<=`a_coef'*`b_coef'
  local z0 = invnormal(r(N)/_N)
  local llb =normal(2*`z0'-`z1')*100
  local ulb =normal(2*`z0'+`z1')*100
  _pctile `b1', percentile(`llb' `ulb')
  display as res  _col(43) %8.0g r(r1) _col(54) %8.0g r(r2) " (BC)"
  _pctile `b2', percentile(`ll' `ul') 
  display as txt "dir eff " as res %8.0g  `c_coef' _col(22) %8.0g  `bias2' _col(32) %8.0g `se2' _col(43) %8.0g r(r1) _col(54) %8.0g r(r2) " (P)"
  quietly count if `b2'<=`c_coef'
  local z0 = invnormal(r(N)/_N)
  local llb =normal(2*`z0'-`z1')*100
  local ulb =normal(2*`z0'+`z1')*100
  _pctile `b2', percentile(`llb' `ulb') 
  display as res  _col(43) %8.0g r(r1) _col(54) %8.0g r(r2) " (BC)"
  _pctile `b3', percentile(`ll' `ul') 
  display as txt "tot eff " as res %8.0g  `t_eff' _col(22) %8.0g  `bias3' _col(32) %8.0g `se3' _col(43) %8.0g r(r1) _col(54) %8.0g r(r2) " (P)"
  quietly count if `b3'<=`t_eff'
  local z0 = invnormal(r(N)/_N)
  local llb =normal(2*`z0'-`z1')*100
  local ulb =normal(2*`z0'+`z1')*100
  _pctile `b3', percentile(`llb' `ulb') 
  display as res  _col(43) %8.0g r(r1) _col(54) %8.0g r(r2) " (BC)"
  display as txt "(P)   percentile confidence interval"
  display as txt "(BC)  bias-corrected confidence interval"
  if _N>`bign' {
    local bign=`bign'+1
    quietly drop in `bign'/l
  }
end
