*!version 1.0.3  03may2006
program define _tobsimdta, rclass
	version 7.0
	
	syntax newvarname [if] [in], 			/*
		*/ [ 					/*
		*/ Bmat(string) 			/*
		*/ tobvers(numlist integer max=1)	/*
		*/ ]

	marksample touse, nov

	tempname ll0
	if "`bmat'" == "" {
		if "`e(cmd)'" != "tobit" {
			di as err "_tobsimdta only works after tobit or "/*
				*/"with bmat()"
			exit 198
		}	
		if "`e(llopt)'" == "" {
			di as err "ll() not specified in tobit"
			exit 198
		}	
		if `e(llopt)' != 0 {
			di as err "ll(0) not specified in tobit"
			exit 198
		}	
		if  "`e(ulopt)'" != "" {
			di as err "ul() specified in tobit"
			exit 198
		}	
					
			scalar `ll0' = e(llopt)
		tempname bmat
		mat `bmat' = e(b)
	}
	else { 
		scalar `ll0' = 0
			
	}

	if "`bmat'" == "" {
		if "`e(version)'" != "2" {
			local tobvers 1
		}
		else {
			local tobvers 2
		}
	
	}
	else {
		if "`tobvers'" == "" {
			di as err 				/*
			*/ "{cmd:tobvers()} must be specified with {cmd:bmat()}}
			exit 498
		}
	}

	if `tobvers' < 2 {
		local xnames : colnames `bmat'
		local cnt_x : word count `xnames'

		local cksig : word `cnt_x' of `xnames' 
		if "`cksig'" != "_se" {
			di as err "_se not found in `bmat'"
			exit 198
		}
	
		local xnames : subinstr local xnames "_se" "",		/*
			*/ count(local cntse)
		local xnames : subinstr local xnames "_cons" "", 	/*
			*/ count(local cntcons)
	}
	else {

		local xnames : colfullnames `bmat'
		local cnt_x : word count `xnames'

		local cksig : word `cnt_x' of `xnames' 
		if "`cksig'" != "sigma:_cons" {
			di as err "sigma:_cons not found in `bmat'"
			exit 198
		}
	
		local xnames : subinstr local xnames "sigma:_cons" "",	/*
			*/ count(local cntse)
		local xnames : subinstr local xnames "model:_cons" "", 	/*
			*/ count(local cntcons)

		local xnames : subinstr local xnames "model:" "", all

	}

	if `cntcons' == 0 {
		local ncon "noconstant
	}	
	
	tempname sig b2
	
	scalar `sig' = `bmat'[1,`cnt_x']
	local b2els  = `cnt_x' -1
	
	mat `b2'=`bmat'[1,1..`b2els']
	
	tempvar e x ystar 

	qui gen `e' = invnorm(uniform()) if `touse'
	qui replace  `e' = `sig' * `e'  if `touse'

	qui mat score double `x' =  `b2' if `touse'

	qui gen double `ystar' = `x' + `e'

	qui gen `typlist' `varlist' = cond( `ystar' > `ll0', `ystar', `ll0')

	ret local xvars "`xnames'"
	if "`ncon'" != "" {
		ret local nocons "noconstant"
	}	
end

