*! v.1.0.0 23mar2011 N.Orsini, M.Bottai 

capture program drop lqregpred
program define lqregpred
version 9.2

syntax  anything [if] [in] [ , for(varlist) at(str asis) plotvs(varlist min=1 max=1)  *  ]

if "`e(cmd)'"!="lqreg" {
	error 301
}

marksample touse
	
local depv = e(depvar) 
 
local nc : word count `for' 

local stubname = "`anything'"
local nquant = e(n_q)
local ymin = e(ymin)
local ymax = e(ymax)

forv i = 1/`nquant' {
	local q`i' = round(e(q`i')*100,.05)
}

if "`for'" == "" & "`at'" == "" {
	forv i = 1/`nquant' {
		qui predict `stubname'`q`i'' if `touse', eq(q`q`i'')
		qui replace `stubname'`q`i'' = (exp(`stubname'`q`i'')*`ymax' + `ymin')/(1 + exp(`stubname'`q`i'')) if `touse'
		label var `stubname'`q`i'' "Predicted q`q`i''"
	}
}

if "`for'" != "" & "`at'" == "" {

	forv i = 1/`nquant' {
			
		local lp "[q`q`i'']_b[_cons]"
				
		foreach v of local for  {
									local lp "`lp' + [q`q`i'']_b[`v']*`v'"	
		}
	
		qui predictnl `stubname'`q`i'' = `lp' if `touse'
		qui replace `stubname'`q`i'' = (exp(`stubname'`q`i'')*`ymax' + `ymin')/(1 + exp(`stubname'`q`i'')) if `touse'
		label var `stubname'`q`i'' "Predicted q`q`i''"
	}

}

if "`for'" != "" & "`at'" != "" {

	forv i = 1/`nquant' {
			
		local lp = "[q`q`i'']_b[_cons]"
				
		foreach v of local for  {
								 local lp "`lp' + [q`q`i'']_b[`v']*`v'"	
		}
	
		local lpat = ""
		local at : subinstr local at " =" "=", all
		local at : subinstr local at "= " "=", all
		local k_at : word count `at'
					
		tokenize `at'
		forvalues z = 1/`k_at' {
			gettoken var : `z', parse("=")	
			local toreplace "``z''"
			local inlp : subinstr local toreplace  "=" "*"
		    local inlp2 : subinstr local inlp  "`var'" "[q`q`i'']_b[`var']"
			local lpat = "`lpat' + `inlp2'"
		}
		
	local lp "`lp' `lpat'"
	
	qui predictnl `stubname'`q`i'' = `lp' if `touse'
	qui replace `stubname'`q`i'' = (exp(`stubname'`q`i'')*`ymax' + `ymin')/(1 + exp(`stubname'`q`i'')) if `touse'
	label var `stubname'`q`i'' "Predicted q`q`i''"	
	
	}
			
}

if "`for'" == "" & "`at'" != "" {
		di as err "either you specify for() what variables you want the predicted values or remove at()"
		exit 198
}
     

		
if "`plotvs'" != "" {

	forv i = 1/`nquant' {
				local listvar "`listvar' `stubname'`q`i''"
				local linewidth "`linewidth' thick"
	}	

	local step = round((`ymax'-`ymin')/5,.05)
	
	tw  /// 
	(scatter `depv' `plotvs', msize(tiny) mc(gs12)) ///
	(line `listvar' `plotvs', sort lw(`linewidth') ) if `touse' , ///
	graphregion(style(none) color(white)) ///
	plotregion(style(none) color(white))  name(f_pred, replace) /// legend(ring(1) col(1) pos(3))
	ytitle("`depv'") yline(`ymin' `ymax', lc(black) lw(thick))  ///
	ylabel(`ymin'(`step')`ymax', format(%3.0fc) angle(horiz) )  
}


end
exit

