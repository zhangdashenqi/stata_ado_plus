*! tabw     version 3.1.1      5-Apr-95                 (STB-25: sg36)
program define tabw
	version 3.1
	local varlist "req ex min(1)"
	local if "opt"
	local in "opt"
	parse "`*'"
	parse "`varlist'", parse(" ")
quietly{
	count `if' `in'
	local obs = _result(1)
	if `obs'<1 {
		noi di in bl "(no observations)"
		exit
	}
	tempvar touse
	gen byte `touse' = 1 `if'
	if `obs'>9999 {
	  if `obs'>99999 {
		local warn1 ", similarly 99999 in any other column means" 
		local warn2 _newline
		local warn3 "         at least 99999 such observations"
	  }
	  #delimit ;
	  noisily di "WARNING: 9999 in the column labelled **** "
		"means at least 9999 " _quote "other" _quote ; 
	  noisily di "         observations" 
		"`warn1'" `warn2' "`warn3'""." _newline ;
	  #delimit cr
	}
	#delimit ;
	noisily di in gr  "Variable|    0     1     2     3     4     5   "
		"  6     7     8     9 ****     ." ;
	noisily di in gr  "--------+" _dup(70) "-" ;
	#delimit cr
	while "`1'"!=""{
	  local type : type `1'
	  if substr("`type'",1,3) !="str"{
		count if `1' == . & `touse'!=. `in'
		local nm = min(_result(1),99999)
		local no = `obs' - _result(1)
		local i 0
		while `i'<10 {
		   if `no'>0 {
			count if `1' == `i' & `touse'!=. `in'
			local no=`no'-_result(1)
			local n`i' = min(_result(1),99999)
		   }
		   else {
			local n`i' 0
		   }
		   local i = `i' + 1
		}
		local no = min(`no',9999)
		#delimit ;
		noisily di in gr "`1'" _col(9) "|" %5.0f `n0' 
	_col(16) %5.0f `n1' _col(22) %5.0f `n2' _col(28) %5.0f `n3' 
	_col(34) %5.0f `n4' _col(40) %5.0f `n5' _col(46) %5.0f `n6' 
	_col(52) %5.0f `n7' _col(58) %5.0f `n8' _col(64) %5.0f `n9' 
	_col(70) %4.0f `no' _col(75) %5.0f `nm';
		#delimit cr
	  }
	  else {
		local str1 "String variable(s):-"
		local str2 "`str2', `1'"
	  }
	mac shift
	}
	local str2 = substr("`str2'",3,.)
	if "`str1'" !="" {noisily di in gr "`str1' `str2'" }

}
end


