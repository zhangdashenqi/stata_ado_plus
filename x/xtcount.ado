*! 1.2.0  22mar1999  jw/ics
program define xtcount, rclass
	version 6.0
  
	syntax if [, i(varname) by(str) * ] 
   
	if "`by'" ~= "" {
		di in re "option by() not permiited in xtcount. Use i() instead"
		exit 198
	}	
		
	if "`i'" ~= "" { 
		iis `i' 
	}
	else if "`_dta[iis]'" == "" { 
		di in re "i() required"
		exit 198
	}

	countby `if' , by(`_dta[iis]') namerec(time point) nameby(panel) `options'
	return add
end
