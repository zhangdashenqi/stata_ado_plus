* VERSION 2
* OCTOBER 23, 2003
* LAST REVISOR: AI
*
*
program define atts, rclass
version 8.0

syntax varlist [if] [in], pscore(string) blockid(string) [ comsup DETail BOOTstrap * ]
tokenize `varlist'

local Y  `1'
local T  `2'

preserve

if `"`if'"'!="" | "`in'"!="" {
   qui keep `if' `in'
}


if `"`detail'"' != `""'  {  
   di in ye _newline(2) "*****************************************************"
   di in ye            "Estimation of the ATT with the stratification method "
   di in ye            "*****************************************************"
}


local BLO `blockid'
local PSCORE `pscore'


/* REGION OF COMMON SUPPORT */
if `"`comsup'"' != `""'  {
   qui sum `PSCORE' if `T'==1
   tempname mintreat maxtreat
   tempvar COMSUP
   scalar `mintreat'  = r(min)
   scalar `maxtreat'  = r(max)

   if `"`detail'"' != `""'  {  
      di  _newline(2) in ye " Note: the common support option has been selected"
      di  in ye " The region of common support is [" `mintreat' ", " `maxtreat' "]"
   }

   qui g `COMSUP'=(`PSCORE'>=`mintreat' & `PSCORE'<=`maxtreat')
   qui drop if `COMSUP'!=1
}


if `"`detail'"' != `""'  {  

   di in ye _newline(2) " The outcome is `Y'"
   sum `Y'

   di in ye _newline(2) " The treatment is `T'"
   tab `T'

   di in ye _newline(2) " The distribution of the pscore is"
   sum `PSCORE', detail 


   di in ye _newline(2) " The structure of blocks is"
   tab `BLO' `T'   , col m
   sort `BLO' `PSCORE'
   by `BLO': sum `PSCORE'

}

tempname maxblo
egen `maxblo' = max(`BLO')
sum `maxblo', meanonly
local numblo = r(mean)


local iblo = 1
local ntot = 0
local nctot = 0
local nttot = 0
local numatt = 0
local att = 0
local numseatt = 0
local tsatt = 0


if `"`detail'"' != `""'  {  
      di _newline(2) " Computation of treatment effect block by block "
}

while `iblo' <= `numblo' {

   qui count if `BLO' == `iblo' 
   local n`iblo' = r(N)

   if r(N)== 0 {

      if `"`detail'"' != `""'  {  
         di _newline(1) " Block  `iblo'  does not have observations "      
         di             " Move to next block "
      }
      
      local nt`iblo' = 0
      local se`iblo' = 0
      local te`iblo' = 0
   }
   else if r(N)!= 0 { 
      qui count if `BLO' == `iblo' & `T' == 0
      local nc`iblo' = r(N)

      if r(N)== 0 {
      
         if `"`detail'"' != `""'  {  
            di _newline(1) " Block  `iblo'  does not have controls "
            di             " The effect of treatment is set to 0 "    
         }
      
         local te`iblo' = 0
         local se`iblo' = 0
         /* ntiblo needs to be defined if the programs jumps */
         /* to display of intermediate results */
         /* without looking computation for treated in this block */
         local nt`iblo' = 0 

      }
      else { 
         qui count if `BLO' == `iblo' & `T' == 1
         local nt`iblo' = r(N) 

         if r(N)== 0 {
         
            if `"`detail'"' != `""'  {  
               di _newline(1) " Block " `iblo' " does not have treated "
               di             " The effect of treatment is set to 0 " 
            }
         
            local te`iblo' = 0
            local se`iblo' = 0
         }
         else {
            qui sum `Y' if `BLO'==`iblo'&`T'==1
            local tmean`iblo' = r(mean)
            local tvar`iblo' = r(Var)
            qui sum `Y' if `BLO'==`iblo'&`T'==0
            local cmean`iblo' = r(mean)
            local cvar`iblo' = r(Var)
            local te`iblo' = `tmean`iblo'' - `cmean`iblo''
            local se`iblo' = `tvar`iblo'' / `nt`iblo'' + `cvar`iblo'' / `nc`iblo''
         }  
      }
   }


   local ntot = `ntot' + `n`iblo''
   local nttot = `nttot' + `nt`iblo''
   local numatt = `numatt' + `nt`iblo'' * `te`iblo''
   local numseatt = `numseatt' + (`nt`iblo'')^2 * `se`iblo''
   local seatt = sqrt(`numseatt'/(`nttot')^2)
   
   local iblo = `iblo' + 1
}

if `"`detail'"' != `""'  {
   di in gr _newline(3) "***************************************************** "
   di in gr             "Display of final results "
   di in gr             "***************************************************** "
}

return scalar atts = `numatt'/`nttot'
return scalar seatts = `seatt'
return scalar tsatts = return(atts) / return(seatts)
return scalar nts = `nttot'
return scalar ncs = `ntot' - `nttot'


di _newline(3) _column(1)  in gr "ATT estimation with the Stratification method" 
di             _column(1)  in gr "Analytical standard errors" 
di in gr _newline(1) in text "{hline 57}"
di             _column(1)  in gr "n. treat." /*
*/             _column(13) in gr "n. contr." /*
*/             _column(25) in gr "      ATT" /*
*/	     _column(37) in gr "Std. Err." /*
*/	     _column(49) in gr "        t"
di in gr             in text "{hline 57}"
di _newline(1) _column(1)  in ye %9.0f return(nts) /*
*/             _column(13) in ye %9.0f return(ncs) /*
*/             _column(25) in ye %9.3f return(atts) /*
*/	     _column(37) in ye %9.3f return(seatts) /*
*/	     _column(49) in ye %9.3f return(tsatts)
di in gr _newline(1) in text "{hline 57}"

restore

if `"`bootstrap'"' != `""'  {  

di _newline(5) in gr "Bootstrapping of standard errors "

bs "atts `varlist' `if' `in', pscore(`pscore') blockid(`blockid') `comsup' " atts=r(atts), nowarn `options'

}

if `"`bootstrap'"' != `""'  {  

/* both e(b) and e(se) are matrices */
return scalar atts = _b[atts]
return scalar bseatts = _se[atts]
return scalar btsatts = return(atts) / return(bseatts)

di _newline(3) _column(1)  in gr "ATT estimation with the Stratification method" 
di             _column(1)  in gr "Bootstrapped standard errors"
di in gr _newline(1) in text "{hline 57}"
di             _column(1)  in gr "n. treat." /*
*/             _column(13) in gr "n. contr." /*
*/             _column(25) in gr "      ATT" /*
*/	     _column(37) in gr "Std. Err." /*
*/	     _column(49) in gr "        t"
di in gr             in text "{hline 57}"
di _newline(1) _column(1)  in ye %9.0f return(nts) /*
*/             _column(13) in ye %9.0f return(ncs) /*
*/             _column(25) in ye %9.3f return(atts) /*
*/	     _column(37) in ye %9.3f return(bseatts) /*
*/	     _column(49) in ye %9.3f return(btsatts)
di in gr _newline(1) in text "{hline 57}"

if `"`detail'"' != `""'  {
   di in gr _newline(3) " Saving results in r()"
}

qui atts `varlist' `if' `in', pscore(`pscore') blockid(`blockid') `comsup'  

}


if `"`detail'"' != `""'  {
di in ye _newline (3) "*****************************************************"
di in ye              "End of the estimation with the stratification method "
di in ye             "*****************************************************"
}

end


