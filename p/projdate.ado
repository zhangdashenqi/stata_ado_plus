*! projdate -- set the first projection date            STB-24: sts7.6
*! version 1.0     Sean Becketti     January 1995
program define projdate
	version 3.1
	local date "`*'"
	parse "`date'", parse(" ,")
        local d
	while "`1'"!="" {
		if "`1'"!="," { local d "`d' `1'" }
		mac shift
	}
        if "`d'"!="" { global S_D_bpro "`d'" }
	if "$S_D_bpro"!="" {
                local y : word 1 of $S_D_bpro
                local m : word 2 of $S_D_bpro
                qui mnthname `m'
                local m "$S_1"
                local string "First projection date: `m' `y'"
        }
        else { local string "No projection date" }
	di "`string'"
        global S_1 "$S_D_bpro"
        global S_2 "`string'"
	global S_3
end

