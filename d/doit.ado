program define doit /* #-of-reps */
	version 3.0
	local reps = `1'
	set more 1
	quietly {
		gens
		describe
		if _result(1)<`reps' {
			set obs `reps'
		}
		local i=1
		while `i'<=`reps' {
			* noi di "`i'"
			replace y = p>=uniform() in 1/$N
			$MODEL in 1/$N
			if _result(1)>0 & _result(1)!=. {
				sto `i'
			}
			local i=`i'+1
		}
	}
end
