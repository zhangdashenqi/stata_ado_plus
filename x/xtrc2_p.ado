*! version 2.0.0  09jul2003         (SJ3-3: st0046)
program define xtrc2_p 
	version 8

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

	/* Just the options _pred_se takes for now. */
	
	local myopts "XB Index STDP XBI GRoup(integer 1)"


		/* Step 2:
			call _propts, exit if done, 
			else collect what was returned.
		*/
			/* takes advantage that -myopts- produces error
			 * if -eq()- specified w/ other that xb and stdp */

	_pred_se "`myopts'" `0'
        if `s(done)' {
        	exit
        }
        local vtyp  `s(typ)'
        local varn `s(varn)'
        local 0 `"`s(rest)'"'

		/* Step 3:
			Parse your syntax.
		*/

	syntax [if] [in] [, `myopts' noOFFset ]
	

		/* Step 4:
			Concatenate switch options together
		*/

	local type  `xb'`index'`stdp'`xbi'
	local args


		/* Step 5:
			quickly process default case if you can 
			Do not forget -nooffset- option.
		*/

	if "`type'" == "" | "`type'" == "index" | "`type'" == "xb" {
		if "`type'" == "" {
			di in gr "(option xb assumed; fitted values)"
		}
                _predict `vtyp' `varn' `if' `in', `offset'
                label var `varn' "Fitted values"
		exit
	}


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

	if "`type'" == "stdp" {
                _predict `vtyp' `varn' `if' `in', `offset' stdp
                label var `varn' "S.E. of prediction of `e(depvar)'"
		exit
	}

	if "`type'" == "xbi" {
		if ( `group' < 1 | `group' > e(N_g) ) {
			/* Issue r(198) for equation # out of range */
			di as error "Equation number out of range."
			error 198
		}
		tempname beta
		matrix `beta' = e(beta_`group')
		matrix score `vtyp' `varn' = `beta' `if' `in'
		if "`e(offset)'" != "" {
			if "`offset'" != "" {
				replace `varn' = `varn' + `e(offset)'
			}
		}
		exit
	}

		/* Step 10.
			handle switch options that can be used in-sample only.
			Same comments as for step 8.
		*/
		/* Step 9:
			Issue r(198), syntax error.
			The user specified more than one option
		*/
	error 198
end

