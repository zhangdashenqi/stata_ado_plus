*! date2obs -- return observation number corresponding to a date  (STB-24: sts7.6)
*! version 1.0     Sean Becketti     January 1995
program define date2obs
	version 3.1
	local date "`*'"
	parse "`date'", parse(" ,")
        local d
	while "`1'"!="" {
		if "`1'"!="," { local d "`d' `1'" }
		mac shift
	}
	local date "`d'"
	local args : word count `date'
	if `args'==0 {
		global S_1 0
		exit
	}
	qui datevars
	local i 1
	while "${S_`i'}"!="" {
		local dvars "`dvars' ${S_`i'}"
		local i = `i' + 1
	}
	local dargs : word count `dvars'
	if `args'!=`dargs' {
		global S_1 0
		di in re "date2obs: wrong number of arguments"
		exit 98
	}
	while "`date'"!="" {
		parse "`dvars'", parse(" ")
		local test "`test' (`1'=="
		mac shift
		local dvars "`*'"
		parse "`date'", parse(" ")
		local test "`test'`1')"
		mac shift
		local date "`*'"
		if "`date'"!="" { local test "`test' &" }
	}
	tempvar n
	gen long `n' = sum(cond(`test',_n,0))
	global S_1 = `n'[_N]
	global S_2
end
