*! findsmpl -- display sample coverage for varlist
*! version 1.0.0     Sean Becketti     June 1992                STB-15: sts4
program define findsmpl
	version 3.1
	local varlist "opt ex"
	local if "opt pre"
	local in "opt pre"
	local weight "aweight fweight iweight pweight"
	local options "Date(str)"
	parse "`*'"
	if ("`date'"!="") {local d "date(`date')"}
	_ts_dsmp `varlist' `if' `in' `weight'`exp', `d'
end
