*! version 1.0.0  23nov2010

* predict after -opreg-, based on -levpet_p-

program define opreg_p

	version 9.2
	
	syntax [anything] [if] [in] [, *]
	
	/* Command-specific options -- We'll ignore most of these */
	local myopts "tfp Cooksd Hat RSTAndard RSTUdent STDR STDF STDP"
	local myopts "`myopts' XB Index RESIDuals"
	
	/* Call _pred_se */
	_pred_se "`myopts'" `0'
	
	if `s(done)' == 1 {
		exit  /* Shouldn't happen since we're only allowing tfp */
	}
	local vtyp `s(typ)'
	local varn `s(varn)'
	local 0 `"`s(rest)'"'
	
	/* Parse syntax */
	syntax [if] [in] [, `myopts']
	
	marksample touse
	
	/* Now reject options we don't allow */
	local type "`cooksd'`hat'`rstandard'`rstudent'`stdr'`stdf'`stdp'"
	local type "`type'`xb'`index'`residuals'"
	
	if "`type'" != "" {
		di as error "option `type' not allowed"
		exit 198
	}
	
	/* At this point tfp should be the only possibility left. */
	if "`tfp'" == "" {
		local tfp tfp
		di as txt "(option tfp assumed)"
	}
	
	if "`tfp'" != "" {
		local lhs `e(dv2)'
		tempname beta
		mat `beta' = e(b)
		mat `beta' = `beta'[.,"`lhs':"]
		tempvar rhs 
		mat score double `rhs' = `beta' if `touse'
		qui gen `vtyp' `varn' = `lhs' - `rhs'
	}

end
