* VERSION 2
* OCTOBER 23, 2003
* LAST REVISOR: AI
*
*
program define attr, rclass
version 8.0

syntax varlist [if] [in] [fweight iweight pweight], [ pscore(varname) logit index radius(real 0.1) comsup DETail BOOTstrap * ]
tokenize `varlist'

local Y  `1'
local T  `2'

preserve

if `"`if'"'!="" | "`in'"!="" {
   qui keep `if' `in'
}


if "`weight'" != "" & `"`bootstrap'"' != `""' { 

   di as error "Warning: You are using weights in the estimation of the propensity score together with the bootstrap option. Note that Stata 8 does not allow the use of weights with bootstrap because with pweights, when the program randomly resamples the data to create a bootstrap dataset, the weight variable would not sum to the population size. Similar problems would arise with fweight and aweight. Arguably the parameter estimates based on the bootstrap samples would therefore have no useful interpretation. In the current version of the program, the only possibility to use weights in the estimation of the propensity score together with the bootstrap option is to first estimate the pscore with weights using pscore.ado and to provide the estimated propensity score to the att*.ado. However keep in mind that by doing this, bootstrapping will not re-estimate the propensity score in each bootstrap data set."
   exit 198

}


if `"`detail'"' != `""'  {  

   di in ye _newline(2) "***************************************************** "
   di in ye             "Estimation of the ATT with the radius matching method "
   di in ye             "***************************************************** "

}

macro shift
local rest `*'


/* if pscore is not user-provided, it has to be estimated */

if `"`pscore'"' == `""'  {   
   if `"`detail'"' != `""'  {  
      di in ye _newline(2) " Estimation of the propensity score"
   }

   tempvar PSCORE

   if `"`detail'"' != `""'  {  
      if `"`logit'"' != `""'  { 
         logit `rest' [`weight'`exp'], nolog    
      }
      else {
         probit `rest' [`weight'`exp'], nolog 
      }
   }
   else {
      if `"`logit'"' != `""'  { 
         qui logit `rest' [`weight'`exp'], nolog    
      }
      else {
         qui probit `rest' [`weight'`exp'], nolog 
      }
   }

   if `"`index'"' != `""'  { 
      qui predict double `PSCORE', index
   }
   else {
      qui predict double `PSCORE'
   }
}                        
else {
local PSCORE `pscore'
}


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

   di in ye _newline(2) " The radius is " `radius'
}


di in ye _newline(2) " The program is searching for matches of treated units within radius. "
di in ye " This operation may take a while."


qui count if `Y' != .
local ntot = r(N)


tempvar psdifi psdif_i  YCRi MCRi YCR_i MCR_i numYCR denYCR WCRi WCR_i WCR SWCR YCR

sort `PSCORE'

local i = 1
local stopi = 0
local stop_i = 0
gen `psdifi' = 0  
gen `psdif_i' = 0  
gen `YCRi' = 0  
gen `MCRi' = 0  
gen `YCR_i' = 0  
gen `MCR_i' = 0  
gen `WCRi' = 0  
gen `WCR_i' = 0  
gen `WCR' = 0  
gen `numYCR' = 0  
gen `denYCR' = 0  


while `stopi' == 0 | `stop_i' == 0  {


   qui replace `psdifi' = abs(`PSCORE' - `PSCORE'[_n + `i']) 
   qui replace `psdif_i' = abs(`PSCORE' - `PSCORE'[_n - `i']) 


   qui replace `YCRi' = 0
   qui replace `MCRi' = 0
   qui replace `YCR_i' = 0
   qui replace `MCR_i' = 0
   qui replace `WCRi' = 0
   qui replace `WCR_i' = 0

   qui replace `YCRi' = `Y'[_n + `i'] if `T'==1 & `T'[_n + `i']==0 & `psdifi' < `radius'
   qui replace `MCRi' = `T'==1 & `T'[_n + `i']==0 & `psdifi' < `radius'

   * weight WCR is mirror image of the rest
   qui replace `WCRi' = `T'==0 & `T'[_n - `i']==1 & `psdifi'[_n-`i'] < `radius'
   qui count if `MCRi'== 0
   if r(N) == `ntot' {
      local stopi = 1
   }


   qui replace `YCR_i' = `Y'[_n - `i'] if `T'==1 & `T'[_n - `i']==0  & `psdif_i' < `radius'
   qui replace `MCR_i' = `T'==1 & `T'[_n - `i']==0 & `psdif_i' < `radius'

   * weight WCR is mirror image of the rest
   qui replace `WCR_i' = `T'==0 & `T'[_n + `i']==1 & `psdif_i'[_n+`i'] < `radius'
   qui count if `MCR_i'== 0
   if r(N) == `ntot' {
      local stop_i = 1
   }


   qui replace `numYCR' = `numYCR' + `YCRi' + `YCR_i' 
   qui replace `denYCR' = `denYCR' + `MCRi' + `MCR_i' 
   qui replace `WCR' = `WCR' + `WCRi' + `WCR_i' 


   local i = `i' + 1
*   di " i = " `i'
*   di " stopi is " `stopi'
*   di " stop_i is " `stop_i'
}


if `"`detail'"' != `""'  {  
   di in ye _newline(2) "**************************************************** "
   di in ye            "Display of final results "
   di in ye            "**************************************************** "
}

if `"`detail'"' != `""'  {  
   di _newline(2) "The number of treated is"
   count if `T'==1

   qui gen `YCR' = `numYCR' / `denYCR' if `T==1'

   di _newline(2) "The number of treated which have been matched is "
   count if `YCR' != .
   local nttot = r(N)

gen sascha1=`WCR'
   qui egen `SWCR' = sum(`WCR')
   qui replace `WCR' = `nttot'*(`WCR'/`SWCR') 
gen sascha2=`WCR'
list
   di _newline(2) "Average outcome of the matched treated"
   sum `Y' if `T'==1 & `YCR' != .
   local myt = r(mean)
   local varyt = r(Var)

   di _newline(2) "Average outcome of the matched controls"
   sum `Y' [aweight=`WCR'] if `T'==0
   local myc = r(mean)
   local nc = r(N)

   qui sum `Y' if `T'==0 & `WCR'!=0
   local  varyc = r(Var)

   tempvar sqweight nweight
   qui gen `sqweight'=`WCR'^2 if `T'==0
   qui sum `sqweight'
   scalar `nweight' = r(sum)

   return scalar seattr = sqrt( `varyt'/`nttot' + (`nweight'/(`nttot'^2))*`varyc' )

   return scalar attr   = `myt'-`myc'
   return scalar tsattr = return(attr)/return(seattr)

   return scalar ntr = `nttot'
   return scalar ncr = `nc'
}
else {  

   qui gen `YCR' = `numYCR' / `denYCR' if `T==1'

   qui count if `YCR' != .
   local nttot = r(N)

   qui egen `SWCR' = sum(`WCR')
   qui replace `WCR' = `nttot'*(`WCR'/`SWCR') 

   qui sum `Y' if `T'==1 & `YCR' != .
   local myt = r(mean)
   local varyt = r(Var)

   qui sum `Y' [aweight=`WCR'] if `T'==0
   local myc = r(mean)
   local nc = r(N)

   qui sum `Y' if `T'==0 & `WCR'!=0
   local  varyc = r(Var)

   tempvar sqweight nweight
   qui gen `sqweight'=`WCR'^2 if `T'==0
   qui sum `sqweight'
   scalar `nweight' = r(sum)

   return scalar seattr = sqrt( `varyt'/`nttot' + (`nweight'/(`nttot'^2))*`varyc' )

   return scalar attr   = `myt'-`myc'
   return scalar tsattr = return(attr)/return(seattr)
  
   return scalar ntr = `nttot'
   return scalar ncr = `nc'

}


di _newline(3) _column(1)  in gr "ATT estimation with the Radius Matching method" 
di             _column(1)  in gr "Analytical standard errors" 
di in gr _newline(1) in text "{hline 57}"
di             _column(1)   in gr "n. treat." /*
*/             _column(13)  in gr "n. contr." /*
*/             _column(25)  in gr "      ATT" /*
*/	       _column(37) in gr "Std. Err." /*
*/	       _column(49) in gr "        t"
di in gr             in text "{hline 57}"
di _newline(1) _column(1)   in ye %9.0f return(ntr) /*
*/             _column(13)  in ye %9.0f return(ncr) /*
*/             _column(25)  in ye %9.3f return(attr) /*
*/	       _column(37) in ye %9.3f return(seattr) /*
*/	       _column(49) in ye %9.3f return(tsattr)
di in gr _newline(1) in text "{hline 57}"
di in gr "Note: the numbers of treated and controls refer to actual"
di in gr "matches within radius"

restore

if `"`bootstrap'"' != `""'  {  

di _newline(5) in gr "Bootstrapping of standard errors "

bs "attr `varlist' `if' `in', pscore(`pscore') `logit' `index' `comsup' radius(`radius')" attr=r(attr), nowarn `options'

}

if `"`bootstrap'"' != `""'  {  

/* both e(b) and e(se) are matrices */
return scalar attr = _b[attr]
return scalar bseattr = _se[attr]
return scalar btsattr = return(attr) / return(bseattr)

di _newline(3) _column(1)  in gr "ATT estimation with the Radius Matching method" 
di             _column(1)  in gr "Bootstrapped standard errors" 
di in gr _newline(1) in text "{hline 57}"
di             _column(1)  in gr "n. treat." /*
*/             _column(13) in gr "n. contr." /*
*/             _column(25) in gr "      ATT" /*
*/	     _column(37) in gr "Std. Err." /*
*/	     _column(49) in gr "        t"
di in gr             in text "{hline 57}"
di _newline(1) _column(1)  in ye %9.0f return(ntr) /*
*/             _column(13) in ye %9.0f return(ncr) /*
*/             _column(25) in ye %9.3f return(attr) /*
*/	     _column(37) in ye %9.3f return(bseattr) /*
*/	     _column(49) in ye %9.3f return(btsattr)
di in gr _newline(1) in text "{hline 57}"
di in gr "Note: the numbers of treated and controls refer to actual" 
di in gr "matches within radius"

if `"`detail'"' != `""'  {  
   di _newline(3) " Saving results in r()"
}


qui attr `varlist' `if' `in' `fweight' `iweight' `pweight', pscore(`pscore') `logit' `index' `comsup' radius(`radius')

}


if `"`detail'"' != `""'  {  
   di in ye _newline (3) "***************************************************** "
   di in ye              "End of the estimation with the radius matching method "
   di in ye              "***************************************************** "
}

end



