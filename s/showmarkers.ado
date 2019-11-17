capture program drop showmarkers
program showmarkers
	syntax , over(string) [msymbol(string) msize(string) mcolor(string) mfcolor(string) ///
            mlpattern(string) mlwidth(string) mlcolor(string) SCHeme(passthru)]
display "`msymbol'"

  preserve
	set more off
	qui drop _all
  if "`over'" == "msymbol" {
    local lista O  Oh o oh D Dh d dh T Th t th S Sh s sh + smplus X x p
    local w : word count of `symlist'
    local xmax = 4
    local targname msymbol
    local title "Showing different symbols by varying mymbol(  )"
  }
  else if "`over'" == "msize" {
    local lista vtiny tiny vsmall small medsmall medium medlarge large large huge vhuge ehuge      
    local w : word count of `symlist'
    local xmax = 4
    local targname msize
    local title "Showing different symbol sizes by varying msize(  )"
  }
    
  else if "`over'" == "mlpattern" {
    local lista solid dash dot dash_dot shortdash shortdash_dot longdash longdash_dot blank              
    local w : word count of `symlist'
    local xmax = 3
    local targname mlpattern
    local title "Showing different marker line patterns by varying mlpattern(  )"
  }
  else if "`over'" == "mlwidth" {
    local lista none vvthin vthin thin medthin medium medthick thick vthick vvthick vvvthick 
    local w : word count of `symlist'
    local xmax = 3
    local targname mlwidth
    local title "Showing different marker line widths by varying mlwidth(  )"
  }
  else if "`over'" == "mcolor" {
    local lista black gs0 gs1 gs2 gs3 gs4 gs5 gs6 gs7 gs8 gs9 gs10 gs11 gs12 gs13 gs14 gs15 gs16 white blue bluishgray brown cranberry cyan dimgray dkgreen dknavy dkorange eggshell emerald forest_green gold gray green khaki lavender lime ltblue ltbluishgray ltkhaki magenta maroon midblue midgreen mint navy olive olive_teal orange orange_red pink purple red sand sandb sienna stone teal yellow ebg ebblue edkblue eltblue eltgreen emidblue erose   
    local xmax = 6
    local targname mcolor
    local title "Showing different marker colors by varying mcolor(  )"
  }
  else if "`over'" == "mfcolor" {
    local lista black gs0 gs1 gs2 gs3 gs4 gs5 gs6 gs7 gs8 gs9 gs10 gs11 gs12 gs13 gs14 gs15 gs16 white blue bluishgray brown cranberry cyan dimgray dkgreen dknavy dkorange eggshell emerald forest_green gold gray green khaki lavender lime ltblue ltbluishgray ltkhaki magenta maroon midblue midgreen mint navy olive olive_teal orange orange_red pink purple red sand sandb sienna stone teal yellow ebg ebblue edkblue eltblue eltgreen emidblue erose   
    local xmax = 6
    local targname mfcolor
    local title "Showing different marker fill colors by varying mfcolor(  )"
  }
  else if "`over'" == "mlcolor" {
    local lista black gs0 gs1 gs2 gs3 gs4 gs5 gs6 gs7 gs8 gs9 gs10 gs11 gs12 gs13 gs14 gs15 gs16 white blue bluishgray brown cranberry cyan dimgray dkgreen dknavy dkorange eggshell emerald forest_green gold gray green khaki lavender lime ltblue ltbluishgray ltkhaki magenta maroon midblue midgreen mint navy olive olive_teal orange orange_red pink purple red sand sandb sienna stone teal yellow ebg ebblue edkblue eltblue eltgreen emidblue erose   
    local xmax = 6
    local targname mlcolor
    local title "Showing different marker outline colors by varying mlcolor(  )"
  }
  else {
    display as error "Over option not recognized"
    display as text "Valid values are..."
    display "msymbol, msize, mlpattern, mlwidth, mcolor, mfcolor and mlcolor"
    exit 
  }
  local cmd
	qui set obs 0
	qui gen x = .
	qui gen y = .
  qui gen str10 s = ""
  local x = 0
  local y = 1
	foreach ela of local lista {
    local `targname' `ela'
    local x = `x'+1
    if `x' > `xmax' {
      local y = `y' + 1
      local x = 1
    }
    local obs = `=_N'+1 
		qui set obs `obs' 
		qui replace y = `y' in l
		qui replace x = `x' in l
		qui replace s = "`ela'" in l
		local c "sc y x in `=_N', pstyle(p1) mlabel(s) msymbol(`msymbol') msize(`msize') mcolor(`mcolor') mfcolor(`mfcolor') mlpattern(`mlpattern') mlwidth(`mlwidth') mlcolor(`mlcolor')"
		local cmd "`cmd' (`c')"
	}
	* di "`cmd'"
  local topx = `xmax' + 1
  local topy = `y' + 1
	twoway `cmd', ysca(r(0 `topy')) xsca(r(0 `topx')) ///
		xlab(none) ylab(none) ysca(reverse) ///
		xtitle("") ytitle("") title("`title'") ///
		legend(nodraw) `scheme'
end
