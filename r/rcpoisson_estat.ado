*! version 1.0.0  03jan2005
program rcpoisson_estat, rclass
	version 9

	if "`e(cmd)'" != "rcpoisson" {
		error 301
	}
	gettoken key rest : 0, parse(", ")
	local lkey = length(`"`key'"')
	if `"`key'"' == substr("gof",1,max(3,`lkey')) {
		rcpoisson_gof `rest'
	}
	else {
		estat_default `0'
	}
	return add
end

