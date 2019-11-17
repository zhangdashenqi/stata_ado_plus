*! version 0.0.2  27feb98   statalist distribution
program define heckman2
   /*  Performs Heckman's two-step estimation of the model w/ 
    *  Heckman's estimate of the covariance matrix. */
   version 5.0
   local options "Level(integer $S_level)"
   if "`1'"!="" & substr("`1'",1,1)!="," {
      parse "`*'", parse(" ,")
      local regeq `1'
      local probit `2'
      mac shift 2

      local options /*
      */ "`options' noConstant DACC(real 1e-5) HOLDrho noLOg TRace TWOstep *"
      local in "opt"
      local if "opt"
      local weight "fweight aweight"
      parse "`*'"

      if "`log'"=="" { local log "noisily" }
      else local log 

      if "`trace'"!="" { local noi "noisily" }

      eq ? `regeq'
      local regeq $S_3
      parse "$S_1", parse(" ")
      local dv `1'
      if "`dv'"=="" { local dv $S_3 }
      mac shift
      local vreg "`*'"

      eq ? `probit'
      local probit $S_3
      local vprobit "$S_1"

      tempvar touse touse2 mysamp isobs pxb 
      tempvar mills delthat rho2del          /* vw */
      tempname pb rb sigma rho f V bb   
      tempname b n deltbar sigmae2 sigmae Vprob XpX1 F Q VBm    /* vw */ 
      mark `touse' [`weight'`exp'] `if' `in'
      markout `touse' `vprobit' 
      mark `touse2'
      markout `touse2' `vreg' /* only matters if `dv'!=. */

      quietly {
         replace `touse' = 0 if `touse2'==0 & `dv'!=.

         /* Check that `dv' has missing values. */

         count if `dv'==. & `touse'
         if _result(1)==0 { 
            di in red "`dv' is never missing"
            exit 499
         }
   
         /* Do probit. */

         gen byte `isobs' = (`dv'!=.) if `touse'

         `noi' probit `isobs' `vprobit' [`weight'`exp'] /*
         */   if `touse', `constan' nolog

         local df = _result(3)
         local df1prob = _result(3) + 1
         predict `pxb' if `touse', index
         mat `pb' = get(_b)
         matrix `Vprob' = get(VCE)                 /* vw */
         mat coleq `pb' = `probit'

         /* Compute Mills ratio. */

         gen double `mills' = exp(-0.5*`pxb'^2) /*
         */         /(sqrt(2*_pi)*normprob(`pxb')) if `touse'

         /* Compute delta-bar */
         g double `delthat' = `mills' * (`mills' + `pxb')
         qui sum `delthat'
         scalar `deltbar' = _result(3)

         /* Do initial regression with Mills' ratio. */

         `noi' di _n in gr "Mills' ratio coefficient estimate from regression"

         `noi' reg `dv' `vreg' `mills' [`weight'`exp'] /*
         */   if `touse', `constan'

         `noi' di _n in gr "Coefficient of Mills' ratio " /*
         */ in ye %9.0g _b[`mills']

         mat `b' = get(_b)
         local df = `df' + _result(3) - ("`holdrho'"!="")

         /* modified computation of rho, ala greene, vw */
         local n = _result(1)
         local sse = _result(4)
         scalar `sigma' = _result(9)
         scalar `sigmae2' = (`sse' / `n') + `deltbar'*_b[`mills']*_b[`mills']
         scalar `sigmae' =  sqrt(`sigmae2')
         scalar `rho' = _b[`mills'] / `sigmae'
         disp "rho :  "`rho'

         /* Get X'X inverse */
         matrix `XpX1' = get(VCE)
         local fctr = 1 / (`sigma' * `sigma')
         matrix `XpX1' = `fctr' * `XpX1'
         /* end, vw */

      }

      /*  Compute the variance of the parameters */

      /*  Heckman's Q adjusment, vw  */
      tempvar one
      g byte `one' = 1
      local lx : word count `vreg'
      local lx = `lx' + 2
      local lx1 = `lx' + 1
      qui mat accum `F' = `vreg' `mills' `one' `vprobit' [iweight=`delthat']
      mat `F' = `F'[1..`lx', `lx1'...]
      local fulnam "`vreg' `mills' _cons"
      mat rowname `F' = `fulnam'
      local rho2 = `rho' * `rho'
      mat `Q' = `F'*`Vprob'
      mat `Q' = `Q'*`F''
      mat `Q' = `rho2' * `Q'

      /* Finish the variance computation */
      g double `rho2del' = 1 - `rho2' * `delthat'  if `touse'
      qui mat accum `VBm' = `vreg' `mills' [iweight=`rho2del']
      mat `VBm' = `VBm' + `Q'
      mat `VBm' = `XpX1' * `VBm'
      mat `VBm' = `VBm' * `XpX1'
      mat `VBm' = `sigmae2' * `VBm'

      local fulnam "`vreg' mills _cons"
      mat rowname `VBm' = `fulnam'
      mat colname `VBm' = `fulnam'
      mat colname `b' = `fulnam'

      mat post `b' `VBm', obs(`n')
      global S_1 = `rho'
   }
   else {
      if "$S_E_cmd"!="heckman" {error 301}
      parse "`*'"
   }

   mat mlout, level(`level')
   disp "rho :  "`rho'
end

exit
