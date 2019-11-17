program define finirr_d0
	version 7

	args todo b ll

	tempname irr
	scalar `irr' = `b'[1,1]

	local cashflow $ML_y1
	local t        $ML_y2
	local ball0    $ML_y3

	tempvar npv
	qui gen double `npv' = `cashflow' / (1+`irr')^`t'  if $ML_samp
	sum `npv', meanonly

	scalar `ll' = -((r(sum) + `ball0'[1])^2)

end"
