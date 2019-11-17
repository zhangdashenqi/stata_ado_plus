program define splagvar_randper
	version 9.2
	syntax varlist
	mata: CalcMoran("`varlist'", "`touse'")
end
