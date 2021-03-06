*! enlarge: 1 obs per group -> whole group. Stas Kolenikov, 06.2001, v.1.1
program define enlarge
   version 6
   syntax varname, BY(varlist) [force]
   local wassort: sortedby
   sort `by' `varlist'
   cap by `by': assert `varlist'[1]~=.
   if _rc~=0 {
      di in red "Warning: there are groups with no observations on `varlist'."
   }
   cap by `by': assert `varlist'[2]==. | _N==1
   if _rc~=0 {
      di in red "There are groups with more than one observation on `varlist'"
      if "`force'"=="" { exit 9 }
      else {
         cap by `by' : assert `varlist' == `varlist'[1] | `varlist' == .
         if _rc!=0 { di in red "There are groups with different values of `varlist'." _n "I'm taking the smallest one." }
      }
   }
   qui by `by': replace `varlist'=`varlist'[1]
   if "`wassort'"~="" { sort `wassort' }
end
