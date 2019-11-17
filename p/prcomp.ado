program define prcomp
*! version 1.0.1     <JRG;28Sep98>    STB-47 sg101
** text mode paired comparisons of means
   version 5.0

   local varlist "req ex min(2) max(2)"
   local if "opt"
   local in "opt"
   local weight "aweight fweight"
   #delimit ;
   local options "ANOva GRaph LEVel(real 0) noLABel noLEGend noLIST
      noMEans NU(real 0) ORDer(string) REFresh SIGma(real 0)
      SAving(string) STDRng TUKey TEst UNEqual *";
   #delimit cr

   parse "`*'"
   parse "`varlist'", parse(" ")
   local weight "[`weight'`exp']"

   local a "`varlist' `weight' `if'`in'"
   if "`tukey'" != "" {
      local stdrng "stdrng"
   }
   if "`stdrng'" == "" { local stdrng "t" }
   else {
      qui cap which qsturng
      if _rc {
         di in red "qsturng.ado not found"
         error 499
      }
      if "`unequal'" != "" {
         di in red "options unequal and stdrng cannot be combined"
         error 499
      }
   }
   local order = substr("`order'", 1, 1)
   if index(" LMN", upper("`order'")) < 2 { local order "N" }
   local lbl : value label `2'
   if "`label'" != "" { local lbl }
   if "`refresh'" != "" { macro drop PrCmp* }
   prcmp0 `a'

   local R = rowsof(PrCmp0)
   if `sigma'+`nu' == 0 {
      local sigma = PrCmp0[`R',3]
      local nu = PrCmp0[`R',1]
   }
   else if (`sigma'==0) | (`nu'==0) {
      di in re "Must supply both nu() and sigma()"
      error 499
   }
   local R = `R' - 1
   prcmp1x 1 `test'
   if "`anova'" != "" { noi oneway `a' }
   if "`means'" == "" { prcmp4 `R' `order' `varlist' `lbl' }
   if `level' == 0.0 { local level "$S_level" }
   if `level' > 1 { local level = `level' / 100 }
   local a "`level' `stdrng'"
   if "`unequal'" == "" { local a "`a' `sigma' `nu'" }

   prcmp1 `a'
   prcmp1x 2 `test'
   local graph = ("`graph'" != "")
   local list = ("`list'" == "")
   if !(`graph' + `list') { exit }
   local legend = ("`legend'" == "")
   if "`test'" != "" { local test 2 }
   else { local test 3 }
   if `graph' {
      global PrComp_G "`options'"
      if "`saving'" != "" { global PrComp_g ",saving(`saving')" }
   }
   prcmp`test' `R' `order' `list' `graph' `legend' `lbl'
   macro drop PrComp_G PrComp_g PrCmp1x
end


