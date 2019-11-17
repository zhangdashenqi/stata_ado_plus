* VERSION 2.02
* MAY 13, 2005
* LAST REVISOR: SOB
*
*
program define pscore
version 8.0

syntax varlist [if] [in] [fweight iweight pweight], pscore(string) [blockid(string) DETail logit comsup level(real 0.01) numblo(int 5)]
tokenize `varlist'

tempvar touse
g `touse'=0
qui replace `touse'=1 `if' `in'

/* if weights are specified, create local variable */
if "`weight'" != "" { 
   tempvar wv
   qui gen double `wv' `exp'
   local w [`weight'=`wv']
   replace `touse'=0 if `wv'==0
}

/* retrieve the treatment indicator */
local T  `1' 

/*******/
/* NEW */
/*******/

confirm new variable `pscore'
if `"`blockid'"' != `""'  { /* BEGINDETAIL */
   confirm new variable `blockid'
} /* ENDDETAIL */
*confirm new variable `blockid'


if `"`detail'"' == `""'  { /* BEGINDETAIL */
   local qui "quietly"
} /* ENDDETAIL */


di in ye _newline(3) "**************************************************** "
di in ye	     "Algorithm to estimate the propensity score "
di in ye	     "**************************************************** "
 
di _newline(2) in ye "The treatment is `T'"

tab `T'  if `touse'==1




di _newline(3) "Estimation of the propensity score "

if `"`logit'"' != `""'  { 
   capture drop comsup
   logit `varlist' [`weight'`exp'] if `touse'==1       
}
else {
   capture drop comsup
   probit `varlist' [`weight'`exp'] if `touse'==1
}

tempvar epscore

qui predict double `epscore' if `touse'==1

/*******/
/* NEW */
/*******/

*capture drop `pscore'

qui gen double `pscore' = `epscore'
label var `pscore' "Estimated propensity score"



/* REGION OF COMMON SUPPORT */
if `"`comsup'"' != `""'  {
   qui sum `pscore' if `T'==1
   tempname mintreat maxtreat
   tempvar COMSUP
   scalar `mintreat'  = r(min)
   scalar `maxtreat'  = r(max)
   di in ye _newline(3)"Note: the common support option has been selected"
   di in ye "The region of common support is [" `mintreat' ", " `maxtreat' "]"

   qui g `COMSUP'=(`pscore'>=`mintreat' & `pscore'<=`maxtreat')
   qui replace `COMSUP'=. if `touse'==0
   qui replace `touse'=0 if `COMSUP'==0
}




di _newline(3) in ye "Description of the estimated propensity score "
if `"`comsup'"' != `""'  {
   di "in region of common support "
}
sum `pscore' if `touse'==1, detail



di _newline(3) "****************************************************** "
di             "Step 1: Identification of the optimal number of blocks "
di             "Use option detail if you want more detailed output "
di             "****************************************************** "


local sizblo = 1/`numblo'  




tempvar inf sup BLO INFBLO SUPBLO
qui gen `BLO' = 0 if `touse'==1 
label var `BLO' "Blocks of the pscore for treatment `T' "
qui gen `INFBLO' = 0  if `touse'==1
label var `INFBLO' "Inferior of block of pscore "
qui gen `SUPBLO' = 0  if `touse'==1
label var `SUPBLO' "Superior of block of pscore "
local iblo = 1
while `iblo' <= `numblo'{
   local linf = 0 + (`iblo'-1)*`sizblo'
   local lsup = 0 + (`iblo')*`sizblo'
   qui replace `BLO'=`iblo' if `linf' <= `pscore' & `pscore'< `lsup' & `touse'==1
   qui replace `INFBLO' = `linf' if `BLO'==`iblo' 
   qui replace `SUPBLO' = `lsup' if `BLO'==`iblo' 
	local iblo= `iblo' + 1
}

/* deal with obs with estimated pscore == 1 */
/*
di _newline(3) in red "Block " `iblo'
di _newline(1) in red "linf " `linf'
di _newline(1) in red "lsup " `lsup'
*/
qui replace `BLO'=`iblo' if `pscore'==1 & `touse'==1
qui replace `INFBLO' = `linf' if `BLO'==`iblo' 
qui replace `SUPBLO' = `lsup' if `BLO'==`iblo' 

/****************************************************************/
/* BEGINNING OF TEST THAT THE PROPENSITY SCORE IS NOT DIFFERENT */
/****************************************************************/


if `"`detail'"' != `""'  { /* BEGINDETAIL */

   di _newline(3) "Distribution of treated and controls across blocks" 
   tab `BLO' `T'

   di _newline(3) "Test that the mean propensity score is not different for treated and controls"

} /* ENDDETAIL */


local iblo = 1
while `iblo' <= `numblo' { /* BEGINOFWHILE */

    
   if `"`detail'"' != `""'  {  
      di _newline(3) in ye "Test in block " `iblo' 
      di _newline(1) in ye "Observations in block " `iblo' 
   }   	
	
   quietly count if `BLO' == `iblo'
   local nobs = r(N)
   
   quietly count if `BLO' == `iblo' & `T' == 0
   local nc = r(N)

   quietly count if `BLO' == `iblo' & `T' == 1
   local nt = r(N)

   if `"`detail'"' != `""'  { /* BEGINDETAIL */
      di " obs: `nobs',  control: `nc',  treated: `nt'"
   } /* ENDDETAIL */

   if `nobs' == 0 | `nc' == 0 | `nt' == 0 { /* BEGINOFIF1 */
      if `"`detail'"' != `""'  { /* BEGINDETAIL */
         if `nobs' == 0 {
         local mistyp "observations"
         }
         else if `nc' == 0 {
         local mistyp "controls"
         }
         else if `nt' == 0 {
         local mistyp "treated"
         }

         di _newline (1) "Block `iblo' does not have `mistyp'"
         di "Move to next block"
      } /* ENDDETAIL */
      
      local iblo= `iblo' + 1

   } /* ENDOFIF1 */
  
   else { /* BEGINOFELSE1 */

      if `"`detail'"' != `""'  { /* BEGINDETAIL */
         di _newline(2)  "Test for block " `iblo'
      } /* ENDDETAIL */

      `qui' ttest `pscore' if `BLO'==`iblo', by(`T')
      
      if r(p) < `level' { /* BEGINIF OF ttest */

         if `"`detail'"' != `""'  { /* BEGINDETAIL */
            di _newline(3) "The mean propensity score is different for 
            di             "treated and controls in block " `iblo'
            di             "Split the block " `iblo' " and retest"
	 } /* ENDDETAIL */
	 
         qui replace `BLO' = `BLO' + 1 if `BLO' > `iblo' & `BLO'!=.
         
         if `"`detail'"' != `""'  { /* BEGINDETAIL */
            di _newline(2) "Check that blocks have shifted "
            tab `BLO' `T'
         } /* ENDDETAIL */
            
         local numblo = `numblo' + 1

         `qui' sum `INFBLO' if `BLO' == `iblo' , meanonly
         local tmpinf = r(mean)
         `qui' sum `SUPBLO' if `BLO' == `iblo' , meanonly
         local tmpsup = r(mean)
         local split = (`tmpinf' + `tmpsup')/2
    
         qui replace `BLO' = `BLO' + 1 if `BLO' == `iblo' & `pscore' >= `split' & `pscore'<= `SUPBLO'  
         qui replace `SUPBLO' = `split' if `BLO' == `iblo'   /* replace supremum of lower sub-block */
         qui replace `INFBLO' = `split' if `BLO' == `iblo'+1 /* replace infimum  of upper sub-block */
      
      } /* ENDIF OF ttest */
      
      else { /* BEGINELSE OF ttest */
      
         if `"`detail'"' != `""'  { /* BEGINDETAIL */
            di _newline(2) "The mean propensity score is not different for 
            di             "treated and controls in block " `iblo'
         } /* ENDDETAIL */
      
         local iblo= `iblo' + 1
      
      } /* ENDELSE OF ttest */
      
   } /* ENDELSE1 */
	    
} /* ENDOFWHILE */


qui sum `BLO'
local maxblo = r(max)

di in gr _newline(2) "The final number of blocks is " `maxblo'

di in gr _newline(1) "This number of blocks ensures that the mean propensity score" 
di in gr             "is not different for treated and controls in each blocks"





di in ye _newline(3) "********************************************************** "
di                   "Step 2: Test of balancing property of the propensity score "
di                   "Use option detail if you want more detailed output "
di                   "********************************************************** "


local iblo = 1
local problem = 0
while `iblo' <= `numblo' { /* BEGINOFWHILE */

   if `"`detail'"' != `""'  { /* BEGINDETAIL */ 
      di _newline (3) "**************************************************** "
      di              "Testing the balancing property in block " `iblo'
      di              "**************************************************** "
   } /* ENDDETAIL */ 

   quietly count if `BLO' == `iblo'
   local nobs = r(N)
   
   quietly count if `BLO' == `iblo' & `T' == 0
   local nc = r(N)

   quietly count if `BLO' == `iblo' & `T' == 1
   local nt = r(N)

   if `"`detail'"' != `""'  { /* BEGINDETAIL */
      di " obs: `nobs',  control: `nc',  treated: `nt'"
   } /* ENDDETAIL */

   if `nobs' == 0 | `nc' == 0 | `nt' == 0 { /* BEGINOFIF1 */
      if `"`detail'"' != `""'  { /* BEGINDETAIL */
         if `nobs' == 0 {
         local mistyp "observations"
         }
         else if `nc' == 0 {
         local mistyp "controls"
         }
         else if `nt' == 0 {
         local mistyp "treated"
         }

         di _newline (1) "Block `iblo' does not have `mistyp'"
         di "Move to next block"
      } /* ENDDETAIL */
   } /* ENDOFIF1 */
  
   else { /* BEGINOFELSE1 */
      foreach var of local varlist { /* BEGINOFFOREACH */
         if "`var'" == "`T'" { /* DO NOTHING */
         }
         else { /* BEGINOFELSE2 */
        
            if `"`detail'"' != `""'  { /* BEGINDETAIL */
               di _newline (3) "Testing the balancing property for variable `var' in block " `iblo'
	    } /* ENDDETAIL */

            `qui' ttest `var' if `BLO' == `iblo', by(`T')
      
            if r(p) < `level' {
               di _newline (1) "Variable `var' is not balanced in block " `iblo'
               local problem = 1
            }
      
            else { /* BEGINOFELSE3 */
        
               if `"`detail'"' != `""'  { /* BEGINDETAIL */
                  di _newline (1) "Variable `var' is  balanced  in block " `iblo'
	       } /* ENDDETAIL */

            } /* ENDOFELSE3 */
        
         } /* ENDOFELSE2 */
      
      } /* ENDOFFOREACH */
    
   } /* ENDOFELSE1 */  
  
  local iblo = `iblo' + 1 

} /* ENDOFWHILE */


if `problem' == 0 {

   di in gr _newline(2) "The balancing property is satisfied "
   di in gr _newline(2) "This table shows the inferior bound, the number of treated 
   di in gr             "and the number of controls for each block "
   if `"`comsup'"' != "" {
      qui replace `INFBLO' = `mintreat' if `INFBLO'==0
   } 
   tab `INFBLO' `T'
   if `"`comsup'"' != "" {
      di in gr "Note: the common support option has been selected"

   }

}
else {

   di _newline(1) in red  "The balancing property is not satisfied "
   di _newline(1) in red  "Try a different specification of the propensity score "

   tab `INFBLO' `T'
   if `"`comsup'"' != "" {
      di in gr "Note: the common support option has been selected"
   }
}


if "`blockid'" != "" {
   *capture drop `blockid'
   qui g `blockid' = `BLO'
   label var `blockid' "Number of block"
}

if `"`comsup'"' != "" {
   qui g comsup = `COMSUP'
   label var comsup "Dummy for obs. in common support"
}



di in ye _newline(2) "******************************************* "
di                   "End of the algorithm to estimate the pscore "
di                   "******************************************* "

end

