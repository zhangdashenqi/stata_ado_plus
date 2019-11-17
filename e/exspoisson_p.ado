*! version 1.0  Alfonso Miranda-Caso-Luengo, June 2003          (SJ4-1: st0057)
program define exspoisson_p, sort
	version 7

	local myopts "n"

	_pred_se "`myopts'" `0'
	if `s(done)' { exit }
	local vtyp  `s(typ)'
	local varn `s(varn)'
	local 0 `"`s(rest)'"'

	syntax [if] [in] [, `myopts' noOFFset]

	local type "`n'"
	marksample touse 
	
	if  "`type'"=="n" | "`type'"=="" {
		
	tempname mu zu lnsigma kappa 
	qui _predict double `mu' if `touse', xb `offset' eq(#1)
	qui _predict double `zu' if `touse', xb `offset' eq(#2)
	qui _predict double `lnsigma' if `touse', xb eq(#3)

	local d "`e(edummy)'"

	tempvar sma u rho
 	gen double `sma' = exp(`lnsigma')  
 	
	tempvar p eta 
	gen double `p'=0 if `touse'
	gen double `eta'=0 if `touse'
	qui replace `mu'=exp(`mu'-0.5*`sma'^2) if `touse'
	qui replace `eta' = 1 
	qui replace `p'=`mu'*`eta' if `touse'
	qui gen `vtyp' `varn'=`p' if `touse'
	label var `varn' "predicted number of events of `e(depvar)'"
	exit
	}
end





