*! version 1.1.0  26aug2009
program define rcpoisson_p
	version 6, missing

	syntax [anything] [if] [in] [, SCores * ]
	
	if `"`scores'"' != "" {
		//ml score `0'
		di as err "option -scores- is not supported at the moment"
		exit 198
	}
		/* Step 1:
			place command-unique options in local myopts
			Note that standard options are
			LR:
				Index XB Cooksd Hat 
				REsiduals RSTAndard RSTUdent
				STDF STDP STDR noOFFset
			SE:
				Index XB STDP noOFFset
		*/
	local myopts "N IR NP"


		/* Step 2:
			call _propts, exit if done,
			else collect what was returned.
		*/
	_pred_se "`myopts'" `0'
	if `s(done)' { exit }
	local vtyp  `s(typ)'
	local varn `s(varn)'
	local 0 `"`s(rest)'"'


		/* Step 3:
			Parse your syntax.
		*/
	syntax [if] [in] [, `myopts' noOFFset]


		/* Step 4:
			Concatenate switch options together
		*/
	local type "`n'`ir'`np'"


		/* Step 5:
			quickly process default case if you can 
			Do not forget -nooffset- option.
		*/

		/* Step 6:
			mark sample (this is not e(sample)).
		*/
	marksample touse


		/* Step 7:
			handle options that take argument one at a time.
			Comment if restricted to e(sample).
			Be careful in coding that number of missing values
			created is shown.
			Do all intermediate calculations in double.
		*/


		/* Step 8:
			handle switch options that can be used in-sample or 
			out-of-sample one at a time.
			Be careful in coding that number of missing values
			created is shown.
			Do all intermediate calculations in double.
		*/
	
	// ++++++++++++++++++++++++++ default: mean of (right) CENSORED Poisson
	if "`type'"=="n" | "`type'"=="" {
		if "`type'"=="" {
			di in gr /*
			*/ "(option n assumed; predicted number of events)"
		}
		tempvar xb mu rlimit
		qui gen `vtyp' `varn' = . // to be filled in in mata
		qui _predict double `xb' if `touse', xb nooffset
		gen double `mu' = exp(`xb') if `touse'
		gen `rlimit' = `e(ulopt)'
		mata: _rcpoisson_mean("`varn'","`mu'","`rlimit'")
		label var `varn' "Predicted number of events"
		exit
	}
	
	// +++++++++++++++++++++++++++++++++++++++++ mean of UNCENSORED Poisson
	if "`type'"=="np" {
		tempvar xb
		qui _predict double `xb' if `touse', xb `offset'
		gen `vtyp' `varn' = exp(`xb') if `touse'		
		label var `varn' ///
			"Predicted number of events from uncensored Poisson"
		exit
	}
	
	if "`type'"=="ir" {
		tempvar xb
		qui _predict double `xb' if `touse', xb nooffset
		gen `vtyp' `varn' = exp(`xb') if `touse'
		label var `varn' "Predicted incidence rate"
		exit
	}
	
	error 198
end


version 11
mata:

void _rcpoisson_mean(string scalar mean,
		     string scalar mu,
		     string scalar rlimit
		    )
{
	
	real colvector ybar
	real colvector lambda
	real colvector rc
	
	use = st_local("touse")
	
	st_view(ybar,.,mean,use)
	st_view(lambda,.,mu,use)
	st_view(rc,.,rlimit,use)

	ybar[.] = rc

	for (i=1; i<=rows(ybar); i++) {
		for (j=0; j<rc[i]; j++) {
			ybar[i] = ybar[i] - poissonp(lambda[i],j)*(rc[i]-j)
		}
	}
}

end
























