*! xmerge    version 1.0     January 1996               (STB-29: dm37)
program define xmerge
quietly {
   version 4.0
   parse "`*'", parse(" ")
   
   local i 2
   while (("``i''"!="using") & ("``i''"!="")) {
      local i = `i'+1
   }
   if("``i''"!="using") {
      di in red "see help xmerge"
      exit
   }

   local vlast = `i'-1
   local ffirst = `i'+1
   
   local i = `i'+1
   while("``i''"!="") {
      local i = `i'+1
   }
   local flast = `i'-1
   if(`flast'==`ffirst') {
      di in red "see help xmerge"
      exit
   }
                         /* build vlist */
   local i = 1
   local vlist ""
   while(`i'<=`vlast') {
      local vlist  "`vlist'  ``i''"
      local i=`i'+1
   }
   
   local i = `ffirst'
   while(`i'<=`flast') {
      drop _all
      use ``i''
      sort `vlist'
      tempfile j`i'
      save `j`i'',replace
      local i = `i'+1
   }   

   use `j`ffirst''
   local i = `ffirst'+1
   while(`i'<=`flast') {
      merge `vlist' using `j`i''
      sort `vlist'
      drop _merge
      local i = `i'+1
   }
}
end
