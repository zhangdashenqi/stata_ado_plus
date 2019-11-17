* (STB-26: dm32)
program define nmatch        
	version 3.0
	local varlist "req ex min(2) max(2)"
	local if "opt"
	local in "opt"
	parse "`*'"
	parse "`varlist'", parse(" ")
	local name1 `1'
	local name2 `2'
	local aname : var lab `1'
	if "`aname'"=="" {local aname "`1'"}
	local bname : var lab `2'
	if "`bname'"=="" {local bname "`2'"}
	gen long _nn=_n
	sort _nn
	tempfile s1
	quietly save `s1'
	keep `name1' `name2' _nn `if' `in'
	quietly {
		sort `name1' `name2' 
		g long _m1=(`name1'!=`name1'[_n-1] | `name2'!=`name2'[_n-1])
		replace _m1=sum(_m1)
		sort _m1
		quietly by _m1:replace _m1=_m1[2]
		sort `name1' `name2' 
		gen long _m2=(`name2'!=`name2'[_n-1])
		replace _m2=sum(_m2)
		sort _m2
		quietly by _m2:replace _m2=_m2[2] 
		sort _m2 _m1
		by _m2:replace _m2=. if _m1[_N]!=.
		sort `name2' `name1' 
		gen long _m3=(`name1'!=`name1'[_n-1])
		replace _m3=sum(_m3)
		sort _m3 
		quietly by _m3:replace _m3=_m3[2] 
		sort _m3 _m1 _m2
		quietly by _m3:replace _m3=. if _m1[_N]!=. | _m2[_N]!=.
		local t1: type `name1'
		local t2: type `name2'
		local np=real(substr("`t1'",4,.))+real(substr("`t2'",4,.))
		tempvar name
		gen str`np' `name'=`name1' + `name2'
		replstr "Y" "I" . `name'
		replstr "IE" "I" . `name'
		replstr "EI" "I" . `name'
		replstr "OU" "O" . `name'
		replstr "Z" "S" . `name'
		replstr "LL" "L" . `name'
		replstr "NN" "N" . `name'
		replstr "TT" "T" . `name'
		replstr "FF" "F" . `name'
		replstr "PH" "V" . `name'
		replstr "HN" "N" . `name'
		replstr "MAC" "MC" . `name'
		sort `name' 
		gen long _m4=(`name'!=`name'[_n-1])
		replace _m4=sum(_m4)
		sort _m4
		by _m4:replace _m4=_m4[2] 
		sort _m4 _m1 _m2 _m3
		by _m4:replace _m4=. if _m1[_N]!=.|_m2[_N]!=.|_m3[_N]!=.
*
	       tempvar n1 n2 stack
	       gen byte `stack'=1
	       desc,sh
	       local nobs=_result(1)
	       local np1=`nobs'+1
	       gen `t1' `n1'=`name1'
	       gen `t2' `n2'=`name2'
	       expand 2
	       replace `n1'=`n2' in `np1'/l
	       replace `n2'=`n1'[_n-`nobs'] in `np1'/l
	       replace `stack'=2 in `np1'/l
	       sort `n1' `n2' 
	       gen long _m5=(`n2'!=`n2'[_n-1])
	       replace _m5=sum(_m5)
	       sort _m5 
	       by _m5:replace _m5=_m5[2]
	       sort _m5 _m1 _m2 _m3 _m4
	       by _m5:replace _m5=. if (_m1[1]==_m1[_N] & _m1!=.) /*
*/ | (_m2[1]==_m2[_N] & _m2!=.) |(_m3[1]==_m3[_N] & _m3!=.)/*
*/ | (_m4[1]==_m4[_N] & _m4!=.)
		sort `stack' _nn
		replace _m5=min(_m5,_m5[_n+`nobs']) if `stack'==1
		keep if `stack'==1
		drop `name' `n1' `n2' `stack'
		compress _m1 _m2 _m3 _m4 _m5
		lab var _m1 "Exact match"
		lab var _m2 "`bname' match"
		lab var _m3 "`aname' match"
		lab var _m4 "Sound match"
		lab var _m5 "Reverse match"
		sort _nn
		merge _nn using `s1'
		}
		erase `s1'
		quietly  drop _nn _merge
end
