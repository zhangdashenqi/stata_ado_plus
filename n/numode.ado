*! version 1.00 97/02/19  STB-38 snp13
program define numode
version 5.0
*First written: 97/02/19; last revised 01/04/97
*Authors: Salgado-Ugarte I.H., M. Shimizu, and T. Taniuchi
*This program calculates the number of modes of a density estimation or
*a frequency distribution and if desired lists their estimated values

local varlist "req ex min(2) max(2)"
local if "opt"
local in "opt"
local options "MOdes"

parse "`*'"
parse "`varlist'", parse(" ")
quietly {
preserve

tempvar difvar inmo sumo
gen `difvar'=`1'[_n+1] - `1'[_n] `if' `in'
gen `inmo' = 0
replace `inmo'=1 if `difvar'[_n]>=0 & `difvar'[_n+1] < 0
gen `sumo' = sum(`inmo')
local numo= `sumo'[_N]
noi di _newline "Number of modes = " `numo'

if "`modes'"~="" {
   tempvar modes
   gen `modes'=.
   replace `modes'=`2' if `inmo'[_n-1]==1 
   sort `modes'
   local i = 1
   noi di _newline _dup(75) "_"
   local title " Modes in density/frequency estimation"
   noi di "`title'"
   noi di _dup(75) "-"
   while `i'<`numo'+1 {
      noi di " Mode ( " %4.0f `i' " ) = " %12.4f `modes'[`i']
      local i = `i'+1
      }
   noi di _dup(75) "_"
   sort `2'
   }


}

end
