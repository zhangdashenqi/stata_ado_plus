*! mixdom version 1.0 Jan 15, 2014 Joseph N. Luchman

program define mixdom, eclass

syntax varlist(min = 2 fv) [pw fw] if, id(varlist max = 1 min = 1) [REopt(string) XTMopt(string) ///
noConstant]

tempname estmat r2w r2b sizes harm

gettoken dv ivs: varlist

quietly xtmixed `dv' `ivs' [`weight'`exp'] `if' , `constant' || `id':, `reopt' `xtmopt'

matrix `estmat' = e(b)

scalar `r2w' = exp(`estmat'[1, `=colsof(`estmat') - 1'])^2 + exp(`estmat'[1, `=colsof(`estmat')'])^2

quietly tabulate `id', matcell(`sizes')

mata: st_numscalar("`harm'", (colsum(st_matrix("`sizes'"):^-1)*rowsum(st_matrix("e(N_g)"))^-1)^-1)

scalar `r2b' = exp(`estmat'[1, `=colsof(`estmat') - 1']/`harm')^2 + exp(`estmat'[1, `=colsof(`estmat')'])^2

capture assert scalar(base_u) == scalar(base_e)

if (_rc == 111) {

	quietly xtmixed `dv' [`weight'`exp'] `if' , `constant' || `id':, `reopt' `xtmopt'

	matrix `estmat' = e(b)

	scalar `r2w' = 1 - (exp(`estmat'[1, `=colsof(`estmat') - 1'])^2 + exp(`estmat'[1, `=colsof(`estmat')'])^2)^-1*`r2w'

	scalar `r2b' = 1 - (exp(`estmat'[1, `=colsof(`estmat') - 1']/`harm')^2 + exp(`estmat'[1, `=colsof(`estmat')'])^2)^-1*`r2b'
	
}

else {

	scalar `r2w' = 1 - (exp(scalar(base_u))^2 + exp(scalar(base_e))^2)^-1*`r2w'

	scalar `r2b' = 1 - (exp(scalar(base_u)/`harm')^2 + exp(scalar(base_e))^2)^-1*`r2b'

}

ereturn scalar r2_w = `r2w'

ereturn scalar r2_b = `r2b'

capture assert scalar(base_e)

if (_rc == 111) scalar base_e = `estmat'[1, `=colsof(`estmat')']

capture assert scalar(base_u)

if (_rc == 111) scalar base_u = `estmat'[1, `=colsof(`estmat') - 1']

end
