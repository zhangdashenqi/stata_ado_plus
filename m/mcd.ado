program define mcd, eclass
version 10.0
 
* MCD
* By Vincenzo Verardi FNRS-FUNDP

syntax varlist(min=1 numeric) [if] [in] , [Generate(string) e(real 0.2) proba(real 0.99) trim(real 0.5) BESTsample(string) raw setseed(numlist max=1) outlier]

tempvar rand touse dist2 mah_dist hat y nobs res ord ww finsamp first Robust_distance MCD_outlier
tempname v tcand n dist2 bestdet eps maxit

mark `touse' `if' `in'
markout `touse' `varlist' `dummies'
qui count if `touse'
local nobs=r(N)
qui gen `ord'=_n
_rmcoll `varlist' if `touse'
local varlist `r(varlist)'

if "`trim'"!="" {
      if `trim'>0.5|`trim'<0 {
      display in r "Trimming must be between 0 and 0.5" 
      exit 198
      }

	else { 
	local h=ceil(`trim'*`nobs')
	}
}

else {
local h=ceil((`nobs'+`nvar1')/2)
}


if "`generate'"!="" {
	tokenize `"`generate'"'
	local nw: word count `generate'

	if `nw'==2 {  
		local marker `1'
		local Dvar `2'
		confirm new var `marker' `Dvar'
	}

	else {
	di in r "define 2 variables in option generate"
	exit 198
	}
}
gen `finsamp'=0
qui {
local nvar: word count `varlist'
local nvar1=`nvar'+1

if `nvar'==1 {
sum `varlist', detail
gen `first'=abs((`varlist'-r(p50))/(r(p75)-r(p25)))
gsort -`first'
local first=int((r(N)*`trim'))+1

sum `varlist' in `first'/l, detail
gen `mah_dist'=abs((`varlist'-r(mean))/r(sd))
qui centile(`mah_dist')
replace `mah_dist'=`mah_dist'/(r(c_1)/invchi2(1,0.5))
matrix covMCD=r(sd)^2
matrix locationMCD=r(mean)
replace `finsamp'=0
replace `finsamp'=1 in `first'/l

capture drop `Robust_distance'
gen `Robust_distance'=sqrt(`mah_dist'^2)
capture drop `MCD_outlier'
gen `MCD_outlier'=`Robust_distance'>2.25
sum `varlist' if `MCD_outlier'==0
matrix covRMCD=r(sd)^2
matrix locationRMCD=r(mean)
}

else {
local ivs `varlist'

if "`e'"!="" {
      if `e'>0.5|`e'<0 {
      noi display in r "e must be between 0 and 0.5"
      exit 198
      }

}

if "`proba'"!="" {
      if `proba'<0|`proba'>0.9999 {
      noi display in r "The probability must be between 0 and 0.9999"
      exit 198
      }
}


matrix accum Cov = `varlist' if `touse', deviations noconstant
matrix Cov = Cov/(r(N)-1)
gen `tcand'=abs(det(Cov))
gen `y'=invnorm(uniform()) if `touse'
gen `dist2'=0
gen `mah_dist'=0
scalar `bestdet'=abs(det(Cov))
scalar `maxit'=200
scalar `eps'=1e-12
capture drop `rand'
gen `rand'=0

local reps=max(ceil((log(1-`proba'))/(log(1-(1-`e')^(`nvar1')))),20)

      if `reps'>2000 {
      noi display in red "!!! The number of subsamples to check is " `reps' " it can take quite some time. Try changing 'e' or 'proba' in the options"
      }

      else {
      noi display in white "The number of subsamples to check is "`reps'
      }


forvalues i=1(1)`reps' {

      local err=1e+12

      if "`setseed'"!="" {
      local counter=`setseed'*`reps'-ceil(log(`reps'))
      set seed `counter'
      }

      capture qui replace `rand'=uniform()

      gsort -`touse' `rand'
      _rmcoll `varlist' if `touse'
      matrix accum Cov = `r(varlist)' in 1/`nvar1', deviations noconstant
      matrix Cov = Cov/(r(N)-1)
      local det0=det(Cov)


            if `det0'==0  {
                  local det 1 
                  while `det'==0 {
                  local nvar1=`nvar1'+1
                  matrix accum Cov = `varlist'* in 1/`nvar1', deviations noconstant
                  matrix Cov = Cov/(r(N)-1)
                  scalar `det0'=det(Cov)
                  local det=(`det0'==0)
                  }
            }


                  reg `y' `varlist' in 1/`nvar1'
                  capture drop `hat'
                  capture qui predict `hat' if `touse', hat
                  capture drop `dist2'
                  capture qui gen `dist2'=(`nvar1'-1)*(`hat'-(1/`nvar1')) if `touse'&`hat'!=.
                  gsort -`touse' `dist2' 

                  local k 1
                  while `k'<=2 {
                  reg `y' `varlist' if `touse' in 1/`h'
                  capture drop `hat'
                  capture qui predict `hat' if `touse', hat
                  capture drop `dist2'
                  capture qui gen `dist2'=(`h'-1)*(`hat'-(1/`h')) if `touse'&`hat'!=.
                  gsort -`touse' `dist2' 
                  matrix accum Cov =`varlist' in 1/`h', deviations noconstant
                  matrix Cov = Cov/(r(N)-1)
                  local det=abs(det(Cov))
                  local k=`k'+1
                  }
   

                  sort `tcand'

                  if `det'<`tcand' in 10 {
                  replace `tcand'=`det' in 10

                  local k 1
                  while `k'<=`maxit'&`err'>`eps' {   
                  gsort -`touse' `dist2' 
                  reg `y' `varlist' in 1/`h'
                  capture drop `hat'
                  capture qui predict `hat' if `touse', hat
                  capture drop `dist2'
                  capture qui gen `dist2'=(`h'-1)*(`hat'-(1/`h')) if `touse'&`hat'!=.
                  sort `dist2'
                  matrix accum Cov =`varlist' in 1/`h', deviations noconstant
                  matrix Cov = Cov/(r(N)-1)
                  local det2=det(Cov)
                  local err=abs(`det2'/`det')-1
                  local det=`det2'
                  local k=`k'+1
                  }

                  if abs(`det')<abs(`bestdet'){
                  scalar `bestdet'=abs(`det')
                  capture qui replace `mah_dist'=`dist2'
                  matrix Covfull=Cov
                  capture qui replace `finsamp'=0
                  capture qui replace `finsamp'=1 in 1/`h'
            }
            }
}

centile(`mah_dist')
local par=r(c_1)/invchi2(`nvar',0.5)
matrix covMCD=`par'*Covfull
replace `mah_dist'=`mah_dist'/`par' if `touse'
capture drop `Robust_distance'
gen `Robust_distance'=`mah_dist' if `touse'
matrix accum Cov =`varlist' if `finsamp'==1, deviations noconstant mean(locationMCD)

gen `ww'=(`Robust_distance'<invchi2(`nvar'-1,0.975))

reg `y' `varlist' if `ww'==1
capture drop `hat'
predict `hat', hat
capture drop `dist2'
gen `dist2'=(e(N)-1)*(`hat'-(1/e(N)))

sum `ww'
local NN=r(sum)

matrix accum Cov =`varlist' if `ww'==1, deviations noconstant mean(locationRMCD)
matrix covRMCD = 0.975/chi2(`nvar'+2,invchi2(`nvar',0.975))*Cov/(`NN'-1)

capture drop `MCD_outlier'
capture qui gen `MCD_outlier'=(`Robust_distance'>invchi2(`nvar'-1,0.975)) if `touse'& `Robust_distance'!=.
replace `Robust_distance'=sqrt(`Robust_distance')
}
}

if "`bestsample'"!="" {
qui rename `finsamp' `bestsample'
}

if "`raw'"!="" {
matrix drop covRMCD
matrix drop locationRMCD
}

else {
matrix drop covMCD
matrix drop locationMCD
}

sort `ord'

if `nvar'>1 {
matrix drop Cov Covfull
}

if "`generate'"!="" {
rename `Robust_distance' `Dvar'
rename `MCD_outlier' `marker'
}

if "`outlier'"!="" {
capture drop Robust_distance MCD_outlier
gen Robust_distance=`Robust_distance'
gen MCD_outlier=`MCD_outlier'
}
sort `ord'
ereturn clear

end
