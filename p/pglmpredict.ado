*! 1.0.0 Anirban Basu 18Oct 2005
program define pglmpredict, sclass
	version 8.0
sret clear
gettoken varn 0: 0, parse(" , ")
gettoken varn: varn

	syntax [if] [in] /*
		*/ [, MU XB ME(varname) IE(varname) SCale(real 1) Level(integer `c(level)') /*
		*/ se(passthru) VARiance(passthru) Wald(passthru) /* 
		*/ p(passthru) ci(passthru) g(string) FORCE /*
		*/ ITERate(integer 100)]  


tempvar touse 
mark `touse' `if' `in'

qui count if `touse'
	if r(N) == 0 {
		error 2000
	}


if "`e(cmd)'" != "pglm" {
 	di as error "Last estimates not from PGLM command"
 	 exit 198
}

local y=e(depvar)

/* Check if ie variable is an indicator variable */
qui {

if "`ie'" != "" {
	tempvar minus1
	gen `minus1' =`ie'- 1
	inspect `minus1' if `touse'
	local zero1 = r(N_0)
	inspect `ie' if `touse'
 	if r(N_pos) !=`zero1' | r(N_0) ==0 | r(N_unique) !=2 {
 		  noi di as error "IE of Variable specified is not an indicator (dummy) variable"
  		 exit 198
	}
}

if "`me'" != "" {
inspect `me' if `touse'
	if r(N_unique) ==2 {
 		  noi di in ye "NOTE: ME calculated for variable with only two unique values"
	}
}

}



local rem = "level(`level') `se' `variance' `wald' `p' `ci' `g' `force' iterate(`iterate')"   

tempvar __xb
qui predict `__xb' if `touse', xb
   
if "`mu'" != ""  {
	predictnl "`varn'"= ((`__xb'*_b[lambda:_cons]+1)^(1/_b[lambda:_cons]))*`scale' if `touse', `rem'
}
else if "`me'" != "" {
	predictnl "`varn'"= `scale'*_b[`y':`me']*(`__xb'*_b[lambda:_cons]+1)^((1 -_b[lambda:_cons])/_b[lambda:_cons]) if `touse', `rem'
}
else if "`ie'" != "" {
	predictnl "`varn'"= (((`__xb' - _b[`y':`ie']*`ie' + _b[`y':`ie'])*_b[lambda:_cons]+1)^(1/_b[lambda:_cons]))*`scale'  /*
	*/	- (((`__xb' - _b[`y':`ie']*`ie')*_b[lambda:_cons]+1)^(1/_b[lambda:_cons]))*`scale' if `touse', `rem'
}
else {
	predict `varn' if `touse', xb
}


if "`mu'" != ""  {
	sreturn local pred "mu"
}
else if "`me'" != "" {
	sreturn local pred "me"
	sreturn local mevar "`me'"
}
else if "`ie'" != "" {
	sreturn local pred "ie"
	sreturn local ievar "`ie'"
}
else {
	sreturn local pred "xb"
}

	sreturn local predvar "`varn'"

qui summ `varn' if `touse'
sreturn local predvar_mn=r(mean)
sreturn local predvar_sd=r(sd)



end

