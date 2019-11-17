*! version 1.0  2001.08.15 JRC

capture program drop jonter
program define jonter
    version 7.0
    syntax varlist(max=1), BY(varname)
preserve     /* Preserving original dataset for restoration at the end */
set more off
quietly drop if `varlist'==.
sort `by'     /* Get the number of groups */
quietly summarize `by'
local max_grp=r(max)
quietly by `by': generate int ctr=_n  /* Counter for getting group sample
sizes later */
local grp=1     /* Initialize the first lower group ID number */
local cum_n_grp=0    /* Zero-initialize the cumulative n counter for lower groups */
local J=0     /* Initializing the J statistic */
while `grp'<=`max_grp'-1 {   /* Lower group (outer-most) loop */
 quietly summarize ctr if `by'==`grp' /* Get sample size for lower group */
 local max_n_grp=`cum_n_grp'+r(max)
 local cum_n_nex=`max_n_grp'  /* Zero-initialize the cumulative n counter for comparison groups */
 local nex=`grp'+1   /* Initialize the comparison group ID number */
 while `nex'<=`max_grp' {  /* Comparison group (next-outer-most) loop */
  quietly summarize ctr if `by'==`nex' /* Getting sample size for comparison group */
  local max_n_nex=`cum_n_nex'+r(max)
  local U=0   /* Zero-initializing the Mann-Whitney U cumulator */
  local n_grp=`cum_n_grp'+1 /* Initializing the n counter for the lower group */
  while `n_grp'<=`max_n_grp' { /* For each value in the lower group, . . . */
   local n_nex=`cum_n_nex'+1 /* Initializing the n counter for comparison group */
   local Phi=0  /* Initializing cumulator for phi */
   while `n_nex'<=`max_n_nex' { /* Inner-most loop */
*
*   Determine phi and cumulate them
*
    if `varlist'[`n_grp']<`varlist'[`n_nex'] {
     local phi=1
    }
    else {
     if `varlist'[`n_grp']==`varlist'[`n_nex'] {
      local phi=0.5
     }
    }
    else {
     if `varlist'[`n_grp']>`varlist'[`n_nex'] {
      local phi=0
     }
    }
    local Phi=`Phi'+`phi' /* Cumulating phi's for each pair */
*
*
*
    local n_nex=`n_nex'+1 /* Incrementing n counter for comparison group */
   }
   local U=`U'+`Phi' /* Cumulating U's for each value of lower group */
   local n_grp=`n_grp'+1 /* Incrementing n counter for lower group */
  }
  local cum_n_nex=`max_n_nex' /* Zero-update the cumulative n counter for comparison groups */
      /* to the next comparison group */
  display "U"`grp'`nex' " = " `U' /* Display the lower-comparison groups' U statistic */
  local J=`J'+`U'   /* Cumulating the U's into the Jonckheere-Terpstra J statistic */
  local nex=`nex'+1  /* Next comparison group (Incrementing comparison group ID number) */
 }
 local cum_n_grp=`max_n_grp'  /* This lower group finished; zero-update cumulative n counter */
      /* for lower groups to next lower group */
 local grp=`grp'+1   /* Next lower group (Incrementing lower group ID number) */
}
display "J = " `J'
*
*   Calculating J-star
*
quietly by `by': keep if _n==_N
generate long nj2=ctr*ctr
generate long bot=nj2*(2*ctr+3)
quietly summarize nj2, detail
local a=r(sum)
quietly summarize bot, detail
local b=r(sum)
quietly summarize ctr, detail
local N=r(sum)
display "J* = " %4.2f (`J'-((`N'*`N'-`a')/4))/sqrt((`N'*`N'*(2*`N'+3)-`b')/72)
display "P = " %6.5f 1.0-norm((`J'-((`N'*`N'-`a')/4))/sqrt((`N'*`N'*(2*`N'+3)-`b')/72))
*
*
*
restore
end
