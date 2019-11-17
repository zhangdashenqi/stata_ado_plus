*! version 1.3 -- 10/10/11 typos
*! version 1.2 -- 9/30/02 marksample, typos
*! version 1.1 -- 2/12/02
program define rsquare
  version 6.0
  syntax varlist [if] [in]
  marksample touse
  quietly regress `varlist' if `touse'
  local r2 = e(r2)
  local kk = e(df_m)
  local evar = e(rmse)^2
  tokenize `varlist'
  local dv `1'
  macro shift
  local rest `*'
  display
  display in green "Regression models for dependent variable : `dv'"
  display
  
  display in green "R-squared  Mallows C           SEE           MSE      models with 1 predictor"
  
  /* loop for one variable models */
  local i = 1
  while "``i''"~="" {
    quietly regress `dv' ``i'' if `touse'
    local mc = e(rss)/`evar' + ( 2*(e(df_m)+1) - e(N))
    local sse = e(rss)
    local mse = e(rss)/e(df_r)
    display %6.4f e(r2) "     " %10.2f  `mc' "      " %10.4f  `sse' "   " %10.4f  `mse' "     " "``i''"  
    local i = `i' + 1
  }

  
  /* loop for two variable models */
  if `kk' > 1 {
    display in green "R-squared  Mallows C           SEE           MSE      models with 2 predictors"
    local i = 1
    while `i'< `kk' {
      local j = `i' + 1
      while `j'<= `kk' {
        quietly regress `dv' ``i'' ``j'' if `touse'
        local mc = e(rss)/`evar' + ( 2*(e(df_m)+1) - e(N))
        local sse = e(rss)
        local mse = e(rss)/e(df_r)
        display %6.4f e(r2) "     " %10.2f  `mc' "      " %10.4f  `sse' "   " %10.4f  `mse' "     "  "``i'' ``j''"  
        local j = `j' + 1
      }
      local i = `i' + 1
    }
  }

  /* loop for three variable models */
  if `kk' > 2 {  
    display in green "R-squared  Mallows C           SEE           MSE      models with 3 predictors"
    local i = 1
    while `i' < `kk' - 1 {
      local j = `i' + 1
      while `j' < `kk' {
        local k = `j' + 1
        while `k' < `kk' + 1 {
          quietly regress `dv' ``i'' ``j'' ``k'' if `touse'
          local mc = e(rss)/`evar' + ( 2*(e(df_m)+1) - e(N))
          local sse = e(rss)
          local mse = e(rss)/e(df_r)
          display %6.4f e(r2) "     " %10.2f  `mc' "      " %10.4f  `sse' "   " %10.4f  `mse' "     "  "``i'' ``j'' ``k''"  
          local k = `k' + 1 
        }
        local j = `j' + 1
      }
      local i = `i' + 1
    }
  }
  
  /* loop for four variable models */
  if `kk' > 3 {
    display in green "R-squared  Mallows C           SEE           MSE      models with 4 predictors"
    local i = 1
    while `i' < `kk' - 2 {
      local j = `i' + 1
      while `j' < `kk' -1 {
        local k = `j' + 1
        while `k' < `kk'  {
          local l = `k' + 1
          while `l' < `kk' + 1 {
            quietly regress `dv' ``i'' ``j'' ``k'' ``l'' if `touse'
             local mc = e(rss)/`evar' + ( 2*(e(df_m)+1) - e(N))
             local sse = e(rss)
             local mse = e(rss)/e(df_r)
    display %6.4f e(r2) "     " %10.2f  `mc' "      " %10.4f  `sse' "   " %10.4f  `mse' "     "  "``i'' ``j'' ``k'' ``l''" 
            local l = `l' + 1 
          }
          local k = `k' + 1
        }
        local j = `j' + 1
      }
      local i = `i' + 1
    }  
  }
  
    /* loop for five variable models */
  if `kk' > 4 {
    display in green "R-squared  Mallows C           SEE           MSE      models with 5 predictors"
    local i = 1
    while `i' < `kk' - 3 {
      local j = `i' + 1
      while `j' < `kk' -2 {
        local k = `j' + 1
        while `k' < `kk' - 1  {
          local l = `k' + 1
          while `l' < `kk' {
            local m = `l' + 1
            while `m' < `kk' + 1 {
             quietly regress `dv' ``i'' ``j'' ``k'' ``l'' ``m'' if `touse'
             local mc = e(rss)/`evar' + ( 2*(e(df_m)+1) - e(N))
             local sse = e(rss)
             local mse = e(rss)/e(df_r)
    display %6.4f e(r2) "     " %10.2f  `mc' "      " %10.4f  `sse' "   " %10.4f  `mse' "     "  "``i'' ``j'' ``k'' ``l'' ``m''" 
             local m = `m' + 1
            }
            local l = `l' + 1 
          }
          local k = `k' + 1
        }
        local j = `j' + 1
      }
      local i = `i' + 1
    }  
  }
  
  /* model with all variables - if needed */
  if `kk' > 5 {
    quietly regress `dv' `rest' if `touse'
    display in green "R-squared  Mallows C           SEE           MSE      models with `kk' predictors"
    display %6.4f e(r2) "     " %10.2f  `mc' "      " %10.4f  `sse' "   " %10.4f  `mse' "     "  "`rest'"
  }
end
