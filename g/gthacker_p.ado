// 10:29 PM 6/3/2006
// Rodrigo Alfaro (raalfaro@hotmail.com)

program define gthacker_p
	version 7
	local myopts "Residuals XB"
	_pred_se "`myopts'" `0'
	if `s(done)' { 
		exit
	}
	local vtyp  `s(typ)'
	local varn `s(varn)'
	local 0 `"`s(rest)'"'
	local typer2 = e(typer2)
	syntax [if] [in] [, `myopts' noOFFset]
	local type  "`residuals'`xb'"

//	if "`typer2'"=="normal" {
		if "`type'"=="residuals" {
			tempvar xb
			quietly {
				_predict `vtyp' `xb' `if' `in' if e(sample)
			}
			gen `vtyp' `varn' = `e(depvar)' - `xb' if e(sample)
			label var `varn' "residual"
			exit
		}
		else {
			di in gr "(option xb assumed; fitted values)"
			_predict `vtyp' `varn' `if' `in', xb `offset'
			label var `varn' "fitted values"
			exit
		}
//	}

//	if "`typer2'"=="within" {
//		di in gr "(only option xb is available for fixed-effects; fitted values)"
//		_predict `vtyp' `varn' `if' `in', xb `offset'
//		label var `varn' "fitted values"
//		exit
//	}	
end
