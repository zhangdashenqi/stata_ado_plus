*!  version 1.0.0  4mar1996
program define xtrchh
	version 5.0
	local options "Level(integer $S_level)"
	if (substr("`1'",1,1)=="," | "`*'"=="") { 
		if "$S_E_cmd"~="xtrchh" { 
			error 301
		}
		parse "`*'"
		if "`level'" != "" {
			if `level' < 10 | `level' > 99 {
				local level = 95
			}
			global S_level = `level'
		}
	}
	else {
		local varlist	"req"
		local if	"opt"
		local in	"opt"
		local options	"noCONS I(string) T(string)"
		local options	"`options' Level(int $S_level)"
		parse "`*'"

		xt_iis `i'
		local ivar "$S_1"
		xt_tis `t'
		local tvar "$S_1"

		if "`cons'"!="" {
			local opt "nocons"
		}
		else {
			local opt ""
		}

		if "`level'" != "" {
			if `level' < 10 | `level' > 99 {
				local level = 95
			}
			global S_level = `level'
		}

		parse "`varlist'", parse(" ")
		global S_E_depv "`1'"
		mac shift
		global S_E_varl "`varlist'"

		quietly {
			tempvar touse
			mark `touse' `if' `in'
			markout `touse' `varlist'

			parse "`varlist'", parse(" ")
			local depv "`1'"
			mac shift
			local indv "`*'"

			tempvar g  
			egen `g' = group(`ivar') if `touse'
			summ `g' if `touse'
			local ng = _result(6)
			count if `touse'
			local nobs = _result(1)
			local nt = `nobs' / `ng'
			if `nt' != int(`nobs'/`ng') {
				noi di in red "unequal sample sizes not allowed"
				exit 198
			}

			tempname xtx b1 v1 bbar gam1 tmp vs bt
			reg `depv' `indv' if `touse' & `g'==1
			mat `b1' = get(_b)
			mat `v1' = get(VCE)
			mat `vs' = syminv(`v1')
			mat `bt' = `vs' * `b1' '
			mat `gam1' = `b1' ' * `b1' 
			mat `bbar' = `b1'
			local i = 2
			while `i' <= `ng' {
				tempname b`i' v`i' 
				reg `depv' `indv' if `touse' & `g'==`i'
				mat `b`i'' = get(_b)
				mat `bbar' = `bbar' + `b`i''
				mat `tmp' = `b`i'' ' * `b`i''
				mat `gam1' = `gam1' + `tmp'
				mat `v`i'' = get(VCE)
				mat `tmp' = syminv(`v`i'')
				mat `vs' = `vs' + `tmp'
				mat `tmp' = `tmp' * `b`i'' '
				mat `bt' = `bt' + `tmp'
				local i = `i' + 1
			}
			mat `vs' = syminv(`vs')
			mat `bt' = `vs' * `bt'
			local ngg = 1/`ng'
			mat `bbar' = `bbar' * `ngg'
			tempname gam gam2 
			mat `gam2' = `bbar' ' * `bbar'
			mat `gam2' = `gam2' * `ng'
			mat `gam' = `gam1' - `gam2'
			local ngg = 1/(`ng'-1)
			mat `gam' = `gam' * `ngg'


			tempname den w1 bm tmp2
			mat `w1' = `gam' + `v1'
			mat `w1' = syminv(`w1')
			mat `den' = `w1'
			mat `bt' = `bt' '
			mat `tmp' = `b1' - `bt'
			mat `tmp2' = syminv(`v1')
			mat `bm' = `tmp' * `tmp2'
			mat `bm' = `bm' * `tmp''
			local i 2
			while `i' <= `ng' {
				tempname w`i'
				mat `w`i'' = `gam' + `v`i''
				mat `w`i'' = syminv(`w`i'')
				mat `den' = `den' + `w`i'' 
				mat `tmp' = `b`i'' - `bt'
				mat `tmp2' = syminv(`v`i'')
				mat `tmp2' = `tmp' * `tmp2'
				mat `tmp2' = `tmp2' * `tmp''
				mat `bm' = `bm' + `tmp2'
				local i = `i'+1
			}
			local k = colsof(`b1')
			local chival = `bm'[1,1]
			local df = `k'*(`ng'-1)
			local chiprob = chiprob(`df',`chival')

			tempname vce
			mat `den' = syminv(`den')
			mat `vce' = `den'

			local i 1
			while `i' <= `ng' {
				mat `w`i'' = `den' * `w`i''
				local i = `i'+1
			}

			mat drop `den'
			tempname beta
			mat `beta' = `w1' * `b1' '
			local i 2
			while `i' <= `ng' {
				mat `den' = `w`i'' * `b`i'' '
				mat `beta' = `beta' + `den'
				local i = `i'+1
			}
			local ng = 1/`ng'
			mat `beta' = `beta' '
			mat post `beta' `vce', obs(`nobs') /*
			*/ depname(`depv')

			global S_E_cmd = "xtrchh"
			global S_E_nobs = `nobs' 
			global S_E_ng = `ng'  
			global S_E_nt = `nt'  
			global S_E_depv = "`depv'"
			global S_E_vl  "`indv'"
			global S_E_ivar "`ivar'"
			global S_E_tvar "`tvar'"
			global S_E_if "`if'"
			global S_E_in "`in'"
			mat S_E_om = `gam'
		}
	}

	noi di 
	noi di in gr "Hildreth-Houck Random coefficients regression"
	mat mlout
	noi di
	noi di in gr "Test of parameter constancy"
	noi di in gr _col(4) "chi(" in ye `df' in gr ")" _col(14) "= " /*
	*/ in ye %8.0g `chival'
	noi di in gr _col(3) "P(X > chi)" _col(14) "= " /*
	*/ in ye %8.4f `chiprob'
	global S_1 = `chival'
	global S_2 = `chiprob'
end

exit
