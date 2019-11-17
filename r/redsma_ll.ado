*! version 1.3.0        25 Jan 2006        Mark Stewart
program define redsma_ll /* b log_likelihood */
	version 8
	args todo b f
	local y    = trim("$ML_y1")
	local doit "$S_sample"
	local i    "$S_ivar"
	local t    "$S_tvar"
	local Tper "$S_TT"
	tempname beta piv u lam theta ma1 omega u2 vcm sa2
	tempvar xb F p zp a eta FF
	local col = colnumb(`b',"logitlam:_cons")
	scalar `sa2' = exp(`b'[1,`col'])
	local col = `col'+1
	scalar `ma1' = `b'[1,`col']
	scalar `omega' = `ma1'/(1+(`ma1'^2))
	local col = `col'+1
	scalar `theta' = exp(`b'[1,`col'])
	mat `vcm' = I(`Tper')*(`sa2'+1)
	mat `vcm'[1,1] = ((`theta'^2)*`sa2')+1
	forvalues row=2/`Tper' {
		mat `vcm'[`row',1] = `theta'*`sa2'
		mat `vcm'[1,`row'] = `vcm'[`row',1]
		local r1 = `row'-1
		forvalues col=2/`r1' {
			mat `vcm'[`row',`col'] = `sa2'
			mat `vcm'[`col',`row'] = `sa2'
		}
		mat `vcm'[`row',`r1'] = `vcm'[`row',`r1'] - `omega'
		mat `vcm'[`r1',`row'] = `vcm'[`row',`r1']
	}
	capture mat $S_C = cholesky(`vcm')
	if _rc~=0 {
		di "Warning: cannot do Cholesky factorization. Previous factor used."
	}
	forval s = 1/`Tper' {
		forval j = 1/`s' {
			tempname c`s'`j'
			scalar `c`s'`j'' = $S_C[`s',`j']
		}
	}
	matrix `beta' = `b'[1,"`y':"]
	local k1 = colsof(`beta')+1
	local k2 = colsof(`b')-2
	matrix `piv' = `b'[1,`k1'..`k2']

	quietly {
	matrix score double `xb' = `beta' if `doit' & `t'~=1
	matrix score double `zp' = `piv' if `doit' & `t'==1
	gen double `a' = `zp'/`c11' if `t'==1
	gen double `p' = cond(`y'==1, norm(`a'), norm(-`a')) if `t'==1
	gen double `eta' = . in 1
	by `doit' `i': gen double `F' = cond(_n==_N,0,.) if `doit'
	gen double `FF' = . in 1

	forvalues r = 1/$S_rep {
		forvalues s = 2/`Tper' {
			local s1 = `s'-1
			replace `eta'=cond(`y'==1,invnorm((1-mu1`r')*norm(-`a')+mu1`r'), /*
			*/			invnorm(mu1`r'*norm(-`a'))) if `t'==`s1'
			replace `a'=`xb'/`c`s'`s'' if `t'==`s'
			forvalues j = 1/`s1' {
				by `doit' `i': replace `a'=`a'+(`c`s'`j''*`eta'[`j']/`c`s'`s'') if `doit' & `t'==`s'
			}
			by `doit' `i': replace `p'=`p'[_n-1]*cond(`y'==1,norm(`a'),norm(-`a')) if `doit' & _n>1			
		}
		by `doit' `i': replace `F' = `F'+`p' if `doit' & _n==_N
	}
	replace `FF' = sum(log(`F'/$S_rep)) if `doit'
	scalar  `f' = `FF'[_N]
	}
end
