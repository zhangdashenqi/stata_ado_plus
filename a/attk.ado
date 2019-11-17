* VERSION 2
* OCTOBER 23, 2003
* LAST REVISOR: AI
*
*
program define attk, rclass
version 8.0

syntax varlist [if] [in] [fweight iweight pweight], [ pscore(varname) logit index comsup DETail EPan BWidth(real 0) BOOTstrap * ]
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

   di in ye _newline(2) "******************************************************"
   di in ye             "Estimation of the ATT with the kernel matching method "
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




* CHECKS

if `bwidth' == 0 { 
	local bwidth = 0.06                                               
}                                                     



if `"`detail'"' != `""'  {  

   di in ye _newline(2) " The outcome is `Y'"
   sum `Y'

   di in ye _newline(2) " The treatment is `T'"
   tab `T'

   di in ye _newline(2) " The distribution of the pscore is"
   sum `PSCORE', detail 

}

di in ye _newline(2) " The program is searching for matches of each treated unit. "
di in ye " This operation may take a while."


tempname maxid m_out	

qui count if `T'==1
scalar `maxid'=r(N)

tempvar  dif newweight 

cap drop m_out
				
qui gen `m_out'=.

gsort -`T'   

local i=1
	while `i'<=`maxid'   {

		cap drop `dif'

		gen `dif'=abs(`PSCORE'-`PSCORE'[`i'])
		
		if `"`epan'"'!= `""'  {
			qui gen `newweight' = 1-(`dif'/ `bwidth')^2 if abs(`dif'/`bwidth')<=1 
			}
		else  {
			qui gen `newweight' = normden(`dif'/ `bwidth') 
			}

		sum `Y' [aw=`newweight'] if `T'==0, meanonly
		qui replace `m_out' = r(mean) in `i'    
		
		drop `newweight' 
			
/*		if `"`count'"' == `""'  {       
		n di _skip(6) `maxid'-`i' 
		} 
*/
		local i = `i'+1

	} 

lab var `m_out' "matched smoothed `outcome'"

tempname mean1 mean0 attk

qui sum `Y'  if `T'==1 & `m_out'!=.
scalar `mean1'  = r(mean)

qui count if `T'==1
local nttot = r(N)

qui sum `m_out' 
scalar `mean0'  = r(mean)
qui count if `T'==0
local nc = r(N)

scalar `attk' = `mean1' - `mean0'



if `"`detail'"' != `""'  {  

   di in ye _newline(2) "**************************************************** "
   di in ye            "Display of final results "
   di in ye            "**************************************************** "





di _newline(3) _skip(3) in g "Mean `Y' of matched treated  = " in y `mean1'                        
di _newline(1) _skip(3) in g "Mean `Y' of matched controls = " in y `mean0'                        
di _newline(1) _skip(3) in g "Effect of treatment  = " in y  `attk' 

}

return scalar mean1 = `mean1'
return scalar mean0 = `mean0'
return scalar attk= `mean1'-`mean0' /* need this for bootstrap part */
return scalar ntk = `nttot'
return scalar nck = `nc'

di _newline(3) _column(1)  in ye "ATT estimation with the Kernel Matching method " 
di in gr _newline(1) in text "{hline 57}"
di             _column(1)   in gr "n. treat." /*
*/             _column(13)  in gr "n. contr." /*
*/             _column(25)  in gr "      ATT" /*
*/	       _column(37) in gr "Std. Err." /*
*/	       _column(49) in gr "        t"
di in gr             in text "{hline 57}"
di _newline(1) _column(1)   in ye %9.0f return(ntk) /*
*/             _column(13)  in ye %9.0f return(nck) /*
*/             _column(25)  in ye %9.3f return(attk) /*
*/	       _column(37) in ye %9.3f return(seattk) /*
*/	       _column(49) in ye %9.3f return(tsattk)
di in gr _newline(1) in text "{hline 57}"
di in gr "Note: Analytical standard errors cannot be computed. Use"
di in gr "the bootstrap option to get bootstrapped standard errors."


restore

if `"`bootstrap'"' != `""'  {  

di _newline(5) in gr "Bootstrapping of standard errors "

bs "attk `varlist' `if' `in', pscore(`pscore') `logit' `index' `comsup' `epan' bwidth(`bwidth')" attk=r(attk), nowarn `options'

}

if `"`bootstrap'"' != `""'  {  

/* both e(b) and e(se) are matrices */
return scalar attk = _b[attk]
return scalar bseattk = _se[attk]
return scalar btsattk = return(attk) / return(bseattk)

di _newline(3) _column(1)  in ye "ATT estimation with the Kernel Matching method" 
di             _column(1)  in ye "Bootstrapped standard errors" 
di in gr _newline(1) in text "{hline 57}"
di             _column(1)  in gr "n. treat." /*
*/             _column(13) in gr "n. contr." /*
*/             _column(25) in gr "      ATT" /*
*/	     _column(37) in gr "Std. Err." /*
*/	     _column(49) in gr "        t"
di in gr             in text "{hline 57}"
di _newline(1) _column(1)  in ye %9.0f return(ntk) /*
*/             _column(13) in ye %9.0f return(nck) /*
*/             _column(25) in ye %9.3f return(attk) /*
*/	     _column(37) in ye %9.3f return(bseattk) /*
*/	     _column(49) in ye %9.3f return(btsattk)
di in gr _newline(1) in text "{hline 57}"



if `"`detail'"' != `""'  {  

   di _newline(3) " Saving results in r()"

}


qui attk `varlist' `if' `in' [`weight'`exp'], pscore(`pscore') `logit' `index' `comsup' `epan' bwidth(`bwidth')

}


if `"`detail'"' != `""'  {  
   di _newline (3) "******************************************************"
   di              "End of the estimation with the kernel matching method "
   di              "******************************************************"
}

end










