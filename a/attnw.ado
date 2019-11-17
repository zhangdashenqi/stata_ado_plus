* VERSION 2
* OCTOBER 23, 2003
* LAST REVISOR: AI
*
*
program define attnw, rclass
version 8.0

syntax varlist [if] [in] [fweight iweight pweight], [ pscore(varname) id(string) matchdta(string) matchvar(string) logit index comsup DETail BOOTstrap * ]
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

   di in ye _newline(2) "****************************************************************"
   di in ye             "Estimation of the ATT with the nearest neighbor matching method "
   di in ye             "Equal weights version "
   di in ye             "****************************************************************"

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

}

di in ye _newline(2) " The program is searching the nearest neighbor of each treated unit. "
di in ye " This operation may take a while."


tempvar flag ycnew sameps newweight mfweight mbweight foweight bweight fpsdif bpsdif pscoref pscoreb fdiff bdiff tweight stweight

sort `PSCORE' `T'


/* ties in pscore of treated and controls */
g `flag'=0
replace `flag'=1 if `PSCORE'==`PSCORE'[_n-1] & `T'!=`T'[_n-1]
qui sum `flag'
if r(max)==1 {

   di as error "Warning: there are treated and controls with the same pscore value. In this case, it is advisable to use attnd.ado instead of attnw.ado because otherwise the same control would be used both in the forward and backward search as if there were two different controls with that pscore."
   exit 198

}
   
   
qui egen `ycnew' = mean(`Y') , by(`PSCORE' `T')
qui egen `sameps' = count(`Y') , by(`PSCORE' `T')
qui gen `newweight' = 1/`sameps' /* multiple best matches get lower weight according to number of colleagues */

/* determine if forward or backward controls are best match */

qui g `pscoreb'=`PSCORE' if `T'==0 /* generates missings in all treated records */
qui replace `pscoreb'=`pscoreb'[_n-1] if `pscoreb'==. /* fills pscore of closest controls in treated records */


gsort -`PSCORE' `T'

qui g `pscoref'=`PSCORE' if `T'==0 /* generates missings in all treated records */
qui replace `pscoref'=`pscoref'[_n-1] if `pscoref'==. /* fills pscore of closest controls in treated records */

qui g `fdiff'=abs(`pscoref'-`PSCORE') /* fdiff is "property" of the treated records */
qui g `bdiff'=abs(`pscoreb'-`PSCORE') /* bdiff is "property" of the treated records */










gsort `PSCORE' -`T'

if `"`detail'"' != `""'  {  

   di _newline(1) " **************************************************** "
   di             " Forward search"
   di             " "

}


local i = 1
local fstop = 0
local fcount = 0
qui gen `fpsdif' = .
qui gen `foweight' = 0 /* starting value zero and NOT missing */

/* new idea: construct weights as the mirror image of the rest of the procedure,
  so while we write info about ATT etc into the treated records, write
  info about weights into the control records
  NEW stopping rule: stop if no more weights are being updated */


while `fstop' == 0 {
   local lastfcount = `fcount'
   qui count if `fpsdif'==. & `T'==1 
   local fcount = r(N)
   if `fcount' == `lastfcount' {
      local fstop = 1
   }
   else {
      if r(N) != 0 {
      
       
      	 /* further if-statement: update weights only if a control is really a best match */

         qui replace `foweight' = `foweight' + `newweight' if `T'==0 & `T'[_n - `i']==1 & `fpsdif'[_n-`i']==. & `fdiff'[_n-`i']<=`bdiff'[_n-`i'] /* changes entry in first control record but not in controls with equal pscore */
         
         qui replace `fpsdif' = `PSCORE' - `PSCORE'[_n + `i'] if `T'==1 & `T'[_n + `i']==0 & `fpsdif'==.
         local i = `i' + 1
      }
      else if r(N)== 0 {
         local fstop = 1
      }
   }
}


sort `PSCORE' `T'
by `PSCORE' `T': egen `mfweight' = max (`foweight') 
qui replace `foweight'=`mfweight'
/* since weights are being built up over all loops but the loop stops 
   once all treated have found their first control, for multiple best 
   matches some control units will not have the right weight yet 
   (because we exit the loop before their weights are correct 
   => write the correct weight into all records of multiple best matches 
   taking the maximum weight which should be the weight of the "first" 
   best match*/


if `"`detail'"' != `""'  {  

   di _newline(1) " **************************************************** "
   di             " Backward search"
   di             " "

}


local i = 1
local bstop = 0
local bcount = 0
qui gen `bpsdif' = .
qui gen `bweight' = 0 /* starting value zero and NOT missing */


while `bstop' == 0 {
   local lastbcount = `bcount'
   qui count if `bpsdif'==.&`T'==1 
   local bcount = r(N)
   if `bcount' == `lastbcount' {
      local bstop = 1
   }
   else {
      if r(N) != 0 {
         qui replace `bweight' = `bweight' + `newweight' if `T'==0 & `T'[_n + `i']==1 & `bpsdif'[_n+`i']==. & `bdiff'[_n+`i']<=`fdiff'[_n+`i'] /* changes entry in first control record but not in controls with equal pscore */
         
         qui replace `bpsdif' = `PSCORE' - `PSCORE'[_n - `i'] if `T'==1 & `T'[_n - `i']==0&`bpsdif'==.
         local i = `i' + 1
      }
      else if r(N)== 0 {
         local bstop = 1
      }
   }
}


qui by `PSCORE' `T': egen `mbweight' = max (`bweight') 
qui replace `bweight'=`mbweight'
/* since weights are being built up over all loops but the loop stops 
   once all treated have found their first control, for multiple best 
   matches some control units will not have the right weight yet 
   (because we exit the loop before their weights are correct 
   => write the correct weight into all records of multiple best matches 
   taking the maximum weight which should be the weight of the "first" 
   best match */


/* TOTAL WEIGHT */

qui g `tweight'=`foweight'+`bweight'
                                   
/* foweight==0 if a control is never a forward best match
bweight==0 if a control is never a backward best match
=> only for controls that are both forward and backward best matches
tweight is the sum of two positive weights */


if `"`detail'"' != `""'  {  

   di _newline(2) " **************************************************** "
   di             " Choice between backward or forward match"
   di             " "

}

capture drop PSDIF
qui gen PSDIF = .

qui replace PSDIF =abs(`fpsdif') if abs(`bpsdif') > abs(`fpsdif') & `T'==1 
qui replace PSDIF =abs(`bpsdif') if abs(`bpsdif') < abs(`fpsdif') & `T'==1  
qui replace PSDIF =abs(`bpsdif') if abs(`bpsdif') == abs(`fpsdif') & `T'==1  



if `"`detail'"' != `""'  {  

   di _newline(2) "**************************************************** "
   di             "Display of final results "
   di             "**************************************************** "


   di _newline(2) "The number of treated is"
   count if `T'==1
   local nttot = r(N)

   di _newline(2) "The number of treated which have been matched is "
   count if PSDIF != .

   di _newline(2) "Average absolute pscore difference between treated and controls"
   sum PSDIF if `T'==1


   di _newline(2) "Average outcome of the matched treated"
   sum `Y' if `T'==1 & PSDIF!=.
   local myt = r(mean)
   local varyt = r(Var)
   di " "


   /* RESCALING OF THE WEIGHT SO THAT IT SUMS UP TO NTTOT */
   qui egen `stweight' = sum(`tweight')
   qui replace `tweight' = `nttot'*(`tweight'/`stweight')


   di _newline(2) "Average outcome of the matched controls"
   sum `Y' [aweight=`tweight'] if `T'==0
   local  myc = r(mean)
   local nc = r(N)

   qui sum `Y' if `T'==0 & `tweight'!=0
   local  varyc = r(Var)

   tempvar sqweight nweight
   qui gen `sqweight'=`tweight'^2 if `T'==0
   qui sum `sqweight'
   scalar `nweight' = r(sum)
}
else {
   qui count if `T'==1
   local nttot = r(N)

   qui sum `Y' if `T'==1 & PSDIF!=.
   local myt = r(mean)
   local varyt = r(Var)
 
   /* RESCALING OF THE WEIGHT SO THAT IT SUMS UP TO NTTOT */
   qui egen `stweight' = sum(`tweight')
   qui replace `tweight' = `nttot'*(`tweight'/`stweight')

   qui sum `Y' [aweight=`tweight'] if `T'==0
   local  myc = r(mean)
   local nc = r(N)

   qui sum `Y' if `T'==0 & `tweight'!=0
   local  varyc = r(Var)

   tempvar sqweight nweight
   qui gen `sqweight'=`tweight'^2 if `T'==0
   qui sum `sqweight'
   qui scalar `nweight' = r(sum)
}

/* NEW 1 */
if "`matchvar'" != "" {

   if "`matchdta'" == "" {
      di in red "Since you used the matchvar(newvar) option,"
      di in red "you also have to specify the matchdta(filename) option!"
      exit 198      
   }
   
   qui g `matchvar' = 0
   replace `matchvar' = 1 if (`T'==0 & `tweight'!=0)
   replace `matchvar' = 1 if (`T'==1 & PSDIF!=.)
   label var `matchvar' "Observation entered ATT"
   qui outfile `id' `T' `PSCORE' `matchvar' using `matchdta', replace
}

return scalar attnw   = `myt'-`myc'
return scalar seattnw = sqrt( `varyt'/`nttot' + (`nweight'/(`nttot'^2))*`varyc' )
return scalar tsattnw = return(attnw) / return(seattnw)
return scalar ntnw = `nttot'
return scalar ncnw = `nc'


di _newline(3) _column(1)  in ye "ATT estimation with Nearest Neighbor Matching method" 
di in ye       _column(1)  "(equal weights version)" 
di             _column(1)  in ye "Analytical standard errors" 
di in gr _newline(1) in text "{hline 57}"
di             _column(1)  in gr "n. treat." /*
*/             _column(13) in gr "n. contr." /*
*/             _column(25) in gr "      ATT" /*
*/	     _column(37) in gr "Std. Err." /*
*/	     _column(49) in gr "        t"
di in gr             in text "{hline 57}"
di _newline(1) _column(1)  in ye %9.0f return(ntnw) /*
*/             _column(13) in ye %9.0f return(ncnw) /*
*/             _column(25) in ye %9.3f return(attnw) /*
*/	     _column(37) in ye %9.3f return(seattnw) /*
*/	     _column(49) in ye %9.3f return(tsattnw)
di in gr _newline(1) in text "{hline 57}"
di in gr "Note: the numbers of treated and controls refer to actual"
di in gr "nearest neighbour matches"

restore

if `"`bootstrap'"' != `""'  {  

di _newline(5) in gr "Bootstrapping of standard errors "

bs "attnw `varlist' `if' `in', pscore(`pscore') `logit' `index' `comsup' " attnw=r(attnw), nowarn `options'

}

if `"`bootstrap'"' != `""'  {  

/* both e(b) anw e(se) are matrices */
return scalar attnw = _b[attnw]
return scalar bseattnw = _se[attnw]
return scalar btsattnw = return(attnw) / return(bseattnw)

di _newline(3) _column(1)  in ye "ATT estimation with Nearest Neighbor Matching method" 
di             _column(1)  "(equal weights version)" 
di             _column(1)  in ye "Bootstrapped standard errors" 
di in gr _newline(1) in text "{hline 57}"
di             _column(1)   in gr "n. treat." /*
*/             _column(13)  in gr "n. contr." /*
*/             _column(25)  in gr "      ATT" /*
*/	       _column(37) in gr "Std. Err." /*
*/	       _column(49) in gr "        t"
di in gr             in text "{hline 57}"
di _newline(1) _column(1)   in ye %9.0f return(ntnw) /*
*/             _column(13)  in ye %9.0f return(ncnw) /*
*/             _column(25)  in ye %9.3f return(attnw) /*
*/	       _column(37) in ye %9.3f return(bseattnw) /*
*/	       _column(49) in ye %9.3f return(btsattnw)
di in gr _newline(1) in text "{hline 57}"
di in gr "Note: the numbers of treated and controls refer to actual"
di in gr "nearest neighbour matches"


if `"`detail'"' != `""'  {  

   di _newline(3) " Saving results in r()"

}


qui attnw `varlist' `if' `in' [`weight'`exp'], pscore(`pscore') `logit' `index' `comsup'

}

/* NEW 2 */
if "`matchvar'" != "" {
   
   preserve
   
   if `"`pscore'"' != `""'  {   
      qui infile `id' `T' `PSCORE' `matchvar' using `matchdta'.raw, clear
   }
   else {
      qui infile `id' `T' pscore `matchvar' using `matchdta'.raw, clear
   }
   
   if "`id'" != "" {
      sort `id'
   }
   qui save `matchdta'.dta, replace
   erase `matchdta'.raw
restore
}


if `"`detail'"' != `""'  {  
   di _newline (3) "******************************************************************************* "
   di              "End of the estimation with the nearest neighbor matching (equal weights) method "
   di              "******************************************************************************* "
}

end















