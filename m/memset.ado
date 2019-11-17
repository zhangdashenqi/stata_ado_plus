
program define memset /* # of obs */
	version 3.0
	quietly describe
	if _result(4)<`1'+1000 {
		local x = `1'+1000
		quietly set maxobs `x'
	}
end
