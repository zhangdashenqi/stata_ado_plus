*! version 1.0.0  31oct2006
program define gpois_lf
        version 6.0
	args todo b lnf g H sc1 sc2

/* Calculate the log-likelihood. */

	tempvar  eta
	tempname del tau m

	mleval `eta' = `b', eq(1)
	mleval `tau' = `b', eq(2) 

	local y "$ML_y1"
	scalar `del' = (exp(2*`tau')-1)/(exp(2*`tau')+1)

	tempname maxdel mindel 
	tempvar  chk
	if 0 {
		qui gen double `chk' = (exp(`eta')-`y') 
		summ `chk' if $ML_samp, meanonly
		
		scalar `mindel' = max(-1, r(min))
	
		if `mindel' > -.001 {
			scalar `mindel' = -0.001
		}
	}
	else {
		qui gen double `chk' = exp(`eta')
		qui summ `chk'
		scalar `mindel' = max(-1, -r(max)/4)
	}
	scalar `mindel' = `mindel' + 0.001
	scalar `maxdel' =  0.999

	if `tau' > 300 | `del' > `maxdel' {
		scalar `del' = `maxdel'
	}
	if `del' < `mindel' {
		scalar `del' = `mindel'
	}

	tempname onemd
	scalar `onemd' = 1.0 - `del'

	tempvar mu den
	qui gen double `mu' = exp(`eta')             if $ML_samp
	qui gen double `den'= `onemd'*`mu'+`del'*`y' if $ML_samp

	mlsum `lnf' = -`den' + (`y'-1)*log(`den') + `eta' + log(`onemd') - lngamma(`y'+1)

	if `todo' == 0 | `lnf'==. { exit }


/* Calculate the scores and gradient. */

	tempname dddt d2ddt2

	scalar `dddt'   = (1+`del')*`onemd'
	scalar `d2ddt2' = -2*`del'*`dddt'
	quietly {
		replace `sc1' = (-`onemd' + `onemd'*(`y'-1)/`den' + /*
			*/ 1.0/`mu')*`mu' if $ML_samp
		replace `sc2' = (`mu'-`y'+(`y'-`mu')*(`y'-1)/`den' - /*
			*/ 1/`onemd')*`dddt' if $ML_samp
	}

	tempname g1 g2
	mlvecsum `lnf' `g1' = `sc1', eq(1)
	mlvecsum `lnf' `g2' = `sc2', eq(2)
	matrix `g' = (`g1',`g2')

	if `todo' == 1 | `lnf'==. { exit }

/* Calculate negative hessian. */

	tempname d11 d12 d22

	mlmatsum `lnf' `d11' = `mu'*`onemd' - /*
		*/ (`y'-1)*`onemd'*`mu'/`den' + /*
		*/ (`y'-1)*`onemd'*`onemd'*`mu'*`mu'/`den'/`den', eq(1)

	mlmatsum `lnf' `d12' = (-1 + (`y'-1)/`den' + /*
		*/ `onemd'*(`y'-1)*(`y'-`mu')/`den'/`den')*`mu'*`dddt', eq(1,2)

	mlmatsum `lnf' `d22' = (1/(`onemd'*`onemd') + /*
		*/ (`y'-`mu')*(`y'-`mu')*(`y'-1)/`den'/`den')*`dddt'*`dddt' - /*
		*/ `sc2'/`dddt'*`d2ddt2', eq(2)
	
	matrix `H' = (`d11',`d12' \ `d12'',`d22')
end
