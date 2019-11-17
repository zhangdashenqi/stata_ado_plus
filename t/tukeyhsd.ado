*! version 1.1 - pbe - 1/30/08 - 4/10/06
program define tukeyhsd
  version 6.0
  syntax varlist(max=1) [if/] [, Level(real .95) nu(real 0) mse(real 0) ]
  if "`e(cmd)'" ~= "anova" {
    error 301
  }
  quietly capture which qsturng
      if _rc {
         di in red "qsturng.ado not found"
         error 499
      }
   if (`nu'==0 & `mse'~=0) | (`nu'~=0 & `mse'==0) {
     di in red "both nu and mse required"
     exit
   }
   tempname q mse2 qfh
   tempvar grp
   tokenize `varlist'
     egen `grp' = group(`1')
     quietly summ `grp'
     local min = r(min)
     local max = r(max) 
     local p1  = `max' - `min'
     local p   = `p1' + 1
     if `nu' == 0 {
       local dfe = e(df_r)
       scalar `mse2' = e(rmse)^2
     }
     else {
       local dfe=`nu'
       scalar `mse2' = `mse'
     }
     local dv `e(depvar)'
     local alpha = 1 - `level'
     quietly qsturng `p' `dfe' `level'
     scalar `q' = $S_1
 
      local hmean = 0
   local i = `min'
   while `i' <= `max' {
     if "`if'" ~= "" {
       quietly summ `dv' if `grp' == `i' & `if'
     }
     else quietly summ `dv' if `grp' == `i'
     local m`i' = r(mean)
     local n`i' = r(N)
          local hmean = `hmean' + 1/r(N)
     local i = `i' + 1
   }
      local hmean = `p'/`hmean'
   display
   display in green "Tukey HSD pairwise comparisons for variable `1'"
   display  in green "studentized range critical value(`alpha', `p', `dfe') = " `q'
      display    in green  "uses harmonic mean sample size = "  %8.3f `hmean'
   display 
   display in green "                                       mean "
   display in green "grp vs grp       group means           dif    HSD-test"
   display in green "-------------------------------------------------------"
      
      
   local ii = `min'
   local i  = `min'
   local j  = `min' + 1
   local s1 = `max' - 1
   while `i' <= `s1' {
   while `j' <= `max'  {
   local dif = abs(`m`i'' - `m`j'')
   scalar `qfh' = `dif'/sqrt(`mse2' /`hmean')
   local nn = (1/`n`i'') + (1/`n`j'')
   local sig " "
   if `qfh' >= `q' { local sig "*" }
   display in yellow %3.0f `i' " vs " %3.0f `j' "  " %9.4f `m`i'' /*
     */ "  " %9.4f `m`j'' "  " %10.4f `dif' in yellow %9.4f `qfh'  in blue "`sig'"
   local j = `j' + 1
   }
   local ii = `ii' + 1
   local i = `ii'
   local j = `ii' + 1
   }
   quietly summ `1'
   if r(max) ~= `max' {
   display
   display in green "Note: the levels of `1' have been recoded."
   }
end
