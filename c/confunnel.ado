*! 1.0.5 Tom Palmer 27nov2008; based on con_funnel by Jaime Peters
* to do:	- eform labelling of x-axis - check how metan does this
* additions: - 'if' & 'in' bug fixed, spotted by AJS
*			- allow direct specification of twoway options via: syntax , [*]
* 			- shadedregions option
*			- clickable examples in helpfile using metan example dataset
*			- studylab option to label the points in the legend, requested by SGM
* 1.0.4 Tom Palmer 26oct2007; based on con_funnel by Jaime Peters
program confunnel
version 8.2
syntax varlist(min=2 max=2) [if] [in], [Contours(string) CONTCOLor(string) ///
			EXTRAplot(string) ///
			FUNCTIONLOWopts(string) FUNCTIONUPPopts(string) ///
			LEGENDLABels(string) LEGENDopts(string) ///
			Metric(string) ONEsided(string) ///
			SCATTERopts(string) SHADEDContours SOLIDContours TWOWAYopts(string) ///
			noSHADEDRegions STUDYLab(string) *]

marksample touse

tokenize `varlist'
local est `1'
local se `2'


/* process options */

* metric options
if "`metric'" != "se" & "`metric'" != "invse" & "`metric'" != "var" & "`metric'" != "invvar" & "`metric'" != "" { // metric error check
	di as error "metric() must be unspecified, se, invse, var or invvar"
	error 198
} 
if "`metric'" == "" { // y-axis
	local metric se
}

* one or two-sided statistical significance regions
if "`onesided'" != "" & "`onesided'" != "lower" & "`onesided'" != "upper" {
	di as error "onesided() must be unspecified, lower or upper"
	error 198
}

* contours
if "`contours'" == "" { // default significance contours
	local contours "1 5 10"
}
local ncontours = wordcount("`contours'")

* max & min values of effect size measure
qui su `est' `if' `in', meanonly
local estmin = r(min)
local estmax = r(max)

* shadedregions option - try recast option to recast i) overall plot, or ii) each plot on the plot
if "`shadedregions'" == "" {
	local shadedregions "shadedregions"
}
else if "`shadedregions'" == "noshadedregions" {
	local shadedregions ""
} // i.e. allows shadedregions option to produce shadedregions

if "`shadedregions'" == "shadedregions" & "`onesided'" != "" {
	di as txt "shadedregions and onesided options cannot currently be specified together, plot uses default onesided options"
	local shadedregions ""
}
if "`shadedregions'" == "shadedregions" {
	if "`solidcontours'" == "" { // must have solid contours for recast() option to work
		local solidcontours "solidcontours"
	}
	local recast "recast(area)"
	local alt "xscale(alt)"
}

* solid or dashed contours
if "`solidcontours'" == "solidcontours" { // use dashed or solid contours
	forvalues m = 1/`ncontours' {
		local linepatt `"`linepatt' solid"'
	}
}
else if "`solidcontours'" == "" {
	local linepatt "longdash dash shortdash dot shortdash_dot dash_dot longdash_dot" // line pattern styles for the contours
}
local n 0
foreach lp in `linepatt' {
	local lp`++n' `lp'
}

* shades for the shaded contours
forvalues j = 1/`ncontours' { // shades for shaded contours
	if "`contcolor'" == "" {
		local shadedcontcol black
	}
	else {
		local shadedcontcol `contcolor'
	}
	
	if "`shadedcontours'" == "shadedcontours" { 
		local lc`j' "`shadedcontcol'*`=1 - `j'/(`ncontours'*1.25)'"
	}
	else if "`shadedcontours'" == "" & "`contcolor'" == "" {
		local lc`j' "gs8"
	}
	else if "`shadedcontours'" == "" & "`contcolor'" != "" {
		local lc`j' "`contcolor'"
	}
	
	if "`shadedregions'" == "shadedregions" {  // color for the recast area plots
		if `j' == `ncontours' {
			local color`j' "white"
			local lc`j' "white"
		}
		else {
			local color`j' "`shadedcontcol'*`=`j'/(`ncontours'*1.25)'"
			local lc`j' "`shadedcontcol'*`=`j'/(`ncontours'*1.25)'"
		}
		local bgcolor "`shadedcontcol'*`=(1/(`ncontours'*1.25))*0.5'"
	}
}

* xtitle
local xtitle "Effect estimate" // default x-axis title

* studylab
if "`studylab'" == "" {
	local studylab "Studies"
}


/* main loops for generating graph twoway command */

local i 1 // used as a counter for labelling the contours in the legend
tempvar yvar
if "`metric'" == "invse" { // y-axis variable: inverse standard error
	qui gen `yvar' = 1/`se'
	qui su `yvar' `if' `in', meanonly
	local ymax = r(max)
	local ymin = r(min)
	local ytitle "Inverse standard error"
	if "`onesided'" == "lower" {
		foreach c in `contours' {
			local i = `i' + 1
			local h = `i' - 1
			local Lz = invnorm(`c'/100)
			local function `"`function' function `Lz'/x, horizontal range(`yvar') lc(`lc`h'') lp(`lp`h'') lw(thin) `functionlowopts' || "'
			local Rz = invnorm(1 - `c'/100)
			local function `"`function' function `Rz'/x, horizontal range(`yvar') lc(none) || "'
			local contourlabels `"`contourlabels' `=2*`h' - 1' "`c'%""'
		}
	}
	else if "`onesided'" == "upper" {
		foreach c in `contours' {
			local i = `i' + 1
			local h = `i' - 1
			local Rz = invnorm(1 - `c'/100)
			local function `"`function' function `Rz'/x, horizontal range(`yvar') lc(`lc`h'') lp(`lp`h'') lw(thin) `functionuppopts' || "'
			local Lz = invnorm(`c'/100)
			local function `"`function' function `Lz'/x, horizontal range(`yvar') lc(none) || "'
			local contourlabels `"`contourlabels' `=2*`h' - 1' "`c'%""'
		}
	}
	else {
		if "`shadedregions'" == "shadedregions" {
			local function `"`function' function `ymax', xaxis(2) color(`bgcolor') base(`ymin') `recast' lw(thin) lc(`lc`h'') xscale(off axis(2)) xlabel(none, axis(2)) xtitle("", axis(2)) || "'
		}	
		foreach c in `contours' {
			local i = `i' + 1
			local h = `i' - 1
			local Lz = invnorm(`c'/(100*2))
			local Rz = invnorm(1 - `c'/(100*2))
			local function `"`function' function `Lz'/x, horizontal range(`yvar') lc(`lc`h'') lp(`lp`h'') lw(thin) `functionlowopts' `recast' color(`color`h'') || "'
			local function `"`function' function `Rz'/x, horizontal range(`yvar') lc(`lc`h'') lp(`lp`h'') lw(thin) `functionuppopts' `recast' color(`color`h'') || "'
			local contourlabels `"`contourlabels' `=2*`h'' "`c'%""'
			if "`shadedregions'" == "shadedregions" {
				if `i' == 2 {
					local regionlabels `"1 "p < `c'%""'
				}
				else{
					local regionlabels `"`regionlabels' `=2*(`h'-1)' "`cprev'% < p < `c'%""'
				}
				if `h' == `ncontours' {
					local regionlabels `"`regionlabels' `=2*(`h'-1) + 2' "p > `c'%""'
				}
			}
		local cprev `c'
		}
	}
}
else if "`metric'" == "se" { // y-axis variable: standard error
	qui gen `yvar' = `se'
	local reverse "reverse"
	local ytitle "Standard error"
	qui su `yvar' `if' `in', meanonly
	local ymax = r(max)
	if "`onesided'" == "lower" {
		foreach c in `contours' {
			local i = `i' + 1
			local h = `i' - 1
			local Lz = invnorm(`c'/100)
			local function `"`function' function x*`Lz', horizontal range(0 `=abs(`ymax')') lc(`lc`h'') lp(`lp`h'') lw(thin) `functionlowopts' || "'
			local Rz = invnorm(1 - `c'/100) // require invsible rhs contours to ensure symmetric plot
			local function `"`function' function x*`Rz', horizontal range(0 `=abs(`ymax')') lc(none) || "'
			local contourlabels `"`contourlabels' `=2*`h' - 1' "`c'%""'
		}
	}
	else if "`onesided'" == "upper" {
		foreach c in `contours' {
			local i = `i' + 1
			local h = `i' - 1
			local Rz = invnorm(1 - `c'/100)
			local function `"`function' function x*`Rz', horizontal range(0 `=abs(`ymax')') lc(`lc`h'') lp(`lp`h'') lw(thin) `functionuppopts' || "'
			local Lz = invnorm(`c'/100)
			local function `"`function' function x*`Lz', horizontal range(0 `=abs(`ymax')') lc(none) || "'
			local contourlabels `"`contourlabels' `=2*`h' - 1' "`c'%""'
		}
	}
	else {
		if "`shadedregions'" == "shadedregions" {	
			local function `"`function' function `ymax', xaxis(2) color(`bgcolor') `recast' lw(thin) lc(`lc`h'') xscale(off axis(2)) xlabel(none, axis(2)) xtitle("", axis(2)) || "' //
		}
		foreach c in `contours' {
			local i = `i' + 1
			local h = `i' - 1
			local Lz = invnorm(`c'/(100*2))
			local Rz = invnorm(1 - `c'/(100*2))
			local function `"`function' function x*`Rz', horizontal range(0 `=abs(`ymax')') lc(`lc`h'') lp(`lp`h'') lw(thin) `functionlowopts' `recast' color(`color`h'') || "'
			local function `"`function' function x*`Lz', horizontal range(0 `=abs(`ymax')') lc(`lc`h'') lp(`lp`h'') lw(thin) `functionuppopts' `recast' color(`color`h'') || "'
			local contourlabels `"`contourlabels' `=2*`h'' "`c'%""'
			if "`shadedregions'" == "shadedregions" {
				if `i' == 2 {
					local regionlabels `"1 "p < `c'%""'
				}
				else{
					local regionlabels `"`regionlabels' `=2*(`h'-1)' "`cprev'% < p < `c'%""'
				}
				if `h' == `ncontours' {
					local regionlabels `"`regionlabels' `=2*(`h'-1) + 2' "p > `c'%""'
				}
			}
		local cprev `c'
		}
	}
}
else if "`metric'" == "var" { // variance on y-axis
	qui gen `yvar' = `se'^2
	local reverse "reverse"
	local ytitle "Variance"
	qui su `if' `in' `yvar', meanonly
	local ymax = r(max)
	if "`onesided'" == "lower" {
		foreach c in `contours' {
			local i = `i' + 1
			local h = `i' - 1
			local Lz = invnorm(`c'/100)
			local function `"`function' function (sqrt(x)*`Lz'), horizontal range(0 `=abs(`ymax')') lc(`lc`h'') lp(`lp`h'') lw(thin) `functionlowopts' || "'
			local Rz = invnorm(1 - `c'/100)
			local function `"`function' function (sqrt(x)*`Rz'), horizontal range(0 `=abs(`ymax')') lc(none) || "'
			local contourlabels `"`contourlabels' `=2*`h' - 1' "`c'%""'
		}
	}
	else if "`onesided'" == "upper" {
		foreach c in `contours' {
			local i = `i' + 1
			local h = `i' - 1
			local Rz = invnorm(1 - `c'/100)
			local function `"`function' function (sqrt(x)*`Rz'), horizontal range(0 `=abs(`ymax')') lc(`lc`h'') lp(`lp`h'') lw(thin) `functionuppopts' || "'
			local Lz = invnorm(`c'/100)
			local function `"`function' function (sqrt(x)*`Lz'), horizontal range(0 `=abs(`ymax')') lc(none) || "'
			local contourlabels `"`contourlabels' `=2*`h' - 1' "`c'%""'
		}
	}
	else {
		if "`shadedregions'" == "shadedregions" {	
			local function `"`function' function `ymax', xaxis(2) color(`bgcolor') `recast' lw(thin) lc(`lc`h'') xscale(off axis(2)) xlabel(none, axis(2)) xtitle("", axis(2)) || "'
		}
		foreach c in `contours' {
			local i = `i' + 1
			local h = `i' - 1
			local Lz = invnorm(`c'/(100*2))
			local Rz = invnorm(1 - `c'/(100*2))
			local function `"`function' function (sqrt(x)*`Rz'), horizontal range(0 `=abs(`ymax')') lc(`lc`h'') lp(`lp`h'') lw(thin) `functionlowopts' `recast' color(`color`h'') || "'
			local function `"`function' function (sqrt(x)*`Lz'), horizontal range(0 `=abs(`ymax')') lc(`lc`h'') lp(`lp`h'') lw(thin) `functionuppopts' `recast' color(`color`h'') || "'
			local contourlabels `"`contourlabels' `=2*`h'' "`c'%""'
			if "`shadedregions'" == "shadedregions" {
				if `i' == 2 {
					local regionlabels `"1 "p < `c'%""'
				}
				else{
					local regionlabels `"`regionlabels' `=2*(`h'-1)' "`cprev'% < p < `c'%""'
				}
				if `h' == `ncontours' {
					local regionlabels `"`regionlabels' `=2*(`h'-1) + 2' "p > `c'%""'
				}
			}
		local cprev `c'
		}
	}

}
else { // inverse variance on y-axis
	qui gen `yvar' = (1/`se')^2
	qui su `yvar' `if' `in', meanonly
	local ymax = r(max)
	local ymin = r(min)
	local ytitle "Inverse variance"
	if "`onesided'" == "lower" {
		foreach c in `contours' {
			local i = `i' + 1
			local h = `i' - 1
			local Lz = invnorm(`c'/100)
			local function `"`function' function (`Lz'^2/x^2), horizontal range(`yvar') lc(`lc`h'') lp(`lp`h'') lw(thin) `functionlowopts' || "'
			local Rz = invnorm(1 - `c'/100)
			local function `"`function' function (`Rz'^2/x^2), horizontal range(`yvar') lc(none) || "'
			local contourlabels `"`contourlabels' `=2*`h' - 1' "`c'%""'
		}
	}
	else if "`onesided'" == "upper" {
		foreach c in `contours' {
			local i = `i' + 1
			local h = `i' - 1
			local Rz = invnorm(1 - `c'/100)
			local function `"`function' function (`Rz'^2/x^2), horizontal range(`yvar') lc(`lc`h'') lp(`lp`h'') lw(thin) `functionuppopts' || "'
			local Lz = invnorm(`c'/100)
			local function `"`function' function (`Lz'^2/x^2), horizontal range(`yvar') lc(none) || "'
			local contourlabels `"`contourlabels' `=2*`h' - 1' "`c'%""'
		}
	}
	else {
		if "`shadedregions'" == "shadedregions" {
			local function `"`function' function `ymax', xaxis(2) color(`bgcolor') base(`ymin') `recast' lw(thin) lc(`lc`h'') xscale(off axis(2)) xlabel(none, axis(2)) xtitle("", axis(2)) || "'
		}	
		foreach c in `contours' {
			local i = `i' + 1
			local h = `i' - 1
			local Lz = invnorm(`c'/(100*2))
			local Rz = invnorm(1 - `c'/(100*2))
			local function `"`function' function (`Lz'^2/x^2), horizontal range(`yvar') lc(`lc`h'') lp(`lp`h'') lw(thin) `functionlowopts' `recast' color(`color`h'') || "'
			local function `"`function' function (`Rz'^2/x^2), horizontal range(`yvar') lc(`lc`h'') lp(`lp`h'') lw(thin) `functionuppopts' `recast' color(`color`h'') || "'
			local contourlabels `"`contourlabels' `=2*`h'' "`c'%""'
			if "`shadedregions'" == "shadedregions" {
				if `i' == 2 {
					local regionlabels `"1 "p < `c'%""'
				}
				else{
					local regionlabels `"`regionlabels' `=2*(`h'-1)' "`cprev'% < p < `c'%""'
				}
				if `h' == `ncontours' {
					local regionlabels `"`regionlabels' `=2*(`h'-1) + 2' "p > `c'%""'
				}
			}
		local cprev `c'
		}
	}
}

* legend options for default plot
if "`legendopts'" != "off" {
	if "`legendopts'" == "" { // default legend options
		local legendopts "ring(0) pos(2) size(vsmall) symxsize(*0.3) cols(1)"
	}
	if "`shadedregions'" == "" {
		local legendopts `"order(`=2*`ncontours' + 1' "`studylab'" `contourlabels' `legendlabels') `legendopts'"'
	}
	else {
		local legendopts `"order(`=2*`ncontours' + 2' "`studylab'" `regionlabels' `legendlabels') `legendopts'"'
	}
}


/* final graph twoway command - contour enhanced funnel plot */

graph twoway ///
	`function' ///
	scatter `yvar' `est' if `touse', mc(black) `scatteropts' `alt' || ///
	`extraplot' ///
	, yscale(`reverse') ylabel(, angle(horizontal)) ///
	xtitle(`xtitle') ytitle(`ytitle') ///
	plotregion(margin(zero)) ///
	legend(`legendopts') ///
	`twowayopts' `options'

end
