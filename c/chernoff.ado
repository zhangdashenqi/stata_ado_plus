*! program to draw chernoff faces
*! version 1.0.0   20jul2009

*author: Rafal Raciborski
*contact: rraciborski@gmail.com

/*
 * Credits
 *
 * Translated from the program FACES.SAS written by Michael Friendly
 * http://www.math.yorku.ca/SCS/sasmac/faces.html
 * Original source: M. Schupbach (1987) ASYMFACE Asymmetrical Faces in TURBO PASCAL, Bern University
 *
 */

*! sortpreserve does not work when nocombine is specified, why?

program define chernoff, sortpreserve
version 9.0
syntax [ ,                                 /*
            */ ISize(passthru)             /*   1. eye size
            */ PSize(passthru)             /*   2. pupil size
            */ PPos(passthru)              /*   3. pupil position
            */ IAngle(passthru)            /*   4. eye slant
            */ IHor(passthru)              /*   5. eye horizontal position
            */ IVert(passthru)             /*   6. eye vertical position
            */ BCurv(passthru)             /*   7. brow curvature
            */ BDens(passthru)             /*   8. brow density
            */ BHor(passthru)              /*   9. brow horizontal position
            */ BVert(passthru)             /*   10. brow vertical position
            */ HUpper(passthru)            /*   11. upper hair line
            */ HLower(passthru)            /*   12. lower hair line
            */ FLine(passthru)             /*   13. face line
            */ HDark(passthru)             /*   14. hair darkness
            */ HSlant(passthru)            /*   15. hair shading slant
            */ NOse(passthru)              /*   16. nose
					  */ MSize(passthru)             /*   17. mouth size
					  */ MCurv(passthru)             /*   18. mouth curvature
					         ********** INDIVIDUAL FACE GRAPH OPTIONS **********
					  */ ORder(varlist)              /*   order faces by varlist
					  */ SHow                        /*   draw individual face graphs
					  */ LHalf                       /*   draw only left half of face  ++++++++++++++++++++++++++++++++++++ NEW
					  */ RHalf                       /*   draw only right half of face ++++++++++++++++++++++++++++++++++++ NEW
					     ASpectratio(passthru)            aspect ratio ++++++++++++++++++++++++++++++++++++++++++++++++++++ NEW
					  */ HSPace(real .75)            /*   space between half face graphs, .5 will make them really close ++ NEW
					         ********** FACE TITLES, LABELS, ETC **********
					  */ ITitle(varname)             /*   title for individual face graph +++++++++++++++++++++++++++++++++ NEW
					  */ INote(varname)              /*   note for individual face graph ++++++++++++++++++++++++++++++++++ NEW
					  */ ILabel(varname)             /*   label faces with varname
					  */ XLabel(real 64)             /*   position of face label x
					  */ YLabel(real -10)            /*   position of face label y
					  */ LSize(passthru)             /*   size of label text - default is large
					  */ PLacement(integer 64)       /*   where to place the label relative to (y, x) position
					  */ JUstification(string)       /*   justification of face label (left, center, right)
					  */ ISCale(varname)             /*   scale for individual graphs +++++++++++++++++++++++++++++++++++++ NEW
					  */ IMargin(passthru)           /*   same as graphregion(margin()) in twoway graph
					  */ IRegion(passthru)           /*   same as plotregion(margin()) in twoway graph ++++++++++++++++++++ NEW
					  */ XFace(real 5.00)            /*   X size of FACE graph ---------------------------------------- DELETE?
					  */ YFace(real 6.00)            /*   Y size of FACE graph ---------------------------------------- DELETE?
					  */ saveall                     /*   save individual face graphs
					  */ REscale(real 1)             /*   restrict the range of transformed variables to less than [0,1]
					  */ gmin(numlist max=1)         /*   global theoretical minimum
					  */ gmax(numlist max=1)         /*   global theoretical maximum
					        ********* COMBINED GRAPH OPTIONS *********
					  */ ROws(passthru)              /*   number of rows in combined graph
					  */ COls(passthru)              /*   number of columns in combined graph
					  */ XCombined(passthru)         /*   X size of COMBINED graph
					  */ YCombined(passthru)         /*   Y size of COMBINED graph
					     FYsize(real 100)                 forced size option ++++++++++++++++++++++++++++++++++++++++++++++ NEW
					     FXSIZE(real 100)                 forced size option ++++++++++++++++++++++++++++++++++++++++++++++ NEW
					  */ LEgend (string)             /*   adds legend - can be legend(2|3 [nolabel]) ++++++++++++++++++++++ NEW
					  */ NOCombine                   /*   do not draw a combined graph
					  */ COLFirst                    /*   display down columns
					  */ TItle(passthru)             /*   title of combined graph
					  */ SUbtitle(passthru)          /*   subtitile of combined graph
					  */ note(passthru)              /*   note for combined graph
					  */ nodraw                      /*   do not draw final combined graph
					  */ SAving(string)              /*   save the combined graph
					  */ timer ]                     /*   shows time to completion 
					  */

//isize psize ppos iangle ihor ivert bcurv bdens bhor bvert hupper hlower fline hdark hslant nose msize mcurv

tempvar z1 z2 z3 z4 z5 z6 z7 z8 z9 z10 z11 z12 z13 z14 z15 z16 z17 z18 nfaces
tempvar X1 Y1 X1L X2 Y2 X2L X3 Y3 X3L X4 Y4 X4L X7 Y7 X7L X16 Y16 X16L X17 Y17 X17L X18 Y18 X18L
tempvar Xface Yface XfaceL Xlow Ylow XlowL Xup Yup XupL XXU YYU XXL YYL XT1 YT1 XT2 YT2

capture sort `order'

qui gen `nfaces' = _n
qui summ `nfaces'
local faces = r(max) // use it later as a counter in loops

if ("`lhalf'" != "" & "`rhalf'" != "") {
	di in yellow "lhalf " as err "and " in yellow "rhalf " as err "cannot be specified together."
	exit
}

if (`hspace' < .50 | `hspace' > 1) {
	di in yellow "hspace " as error "must be within [.50, 1.00]."
	exit
}

if (`rescale' <= .50 | `rescale' > 1) {
  di as error "The value of " in yellow "rescale " as error "must be within (.50, 1.00]."
  exit
}

// do everything in terms of a single face, even if it involves recalculating some statistics,
// as processing all faces at once generates too many vars and you run into memory issues

di in yellow _n "Processing " in green `faces' in yellow " observations...." _n

tempvar one
gen byte `one' = 1 // to mark original observations
capture set obs 121 // need that many obs for hair coordinates
qui replace `one' = 0 if `one' == .

local shift = 1 - `rescale'

// rescale all variables to [0,1] range, the default being .50
local facef "isize psize ppos iangle ihor ivert bcurv bdens bhor bvert hupper hlower fline hdark hslant nose msize mcurv"
local c = 1
foreach f of local facef {
	
	// each face feature is specified as f(varname|.|_null_ [, #|. #|.])
	
  tokenize `"``f''"', parse("(), ")
	macro shift
	macro shift
	local v1 `1'
	macro shift
	macro shift
	local lmin `1'
	local lmax `2'
	
	/*
	di as err "v1 is `v1'"
	di as err "lmin is `lmin'"
	di as err "lmax is `lmax'"
	di as err "gmin is `gmin'"
	di as err "gmax is `gmax'"
	*/
	
	if ("`v1'" != "" & "`v1'" != "." & "`v1'" != "_null_") {
		qui count if `v1' == . & `one' == 1
		if `r(N)' > 0 {
			di as err "Warning: variable " in green "`v1' " as err "contains missing values."
		}
	}
	
	if ("`v1'" == "" | "`v1'" == "." | "`v1'" == "_null_") {
		qui gen double `z`c'' = .5
	}
	else {
		
		qui su `v1'
		local varmin = `r(min)'
		local varmax = `r(max)'
		if ("`lmin'"==")") local lmin = `varmin'
		if ("`lmax'"==")") local lmax = `varmax'
		
		// check theoretical global and local min and max
		if ("`gmin'" != "" ) {
			if (`gmin' > `varmin') {
				di as err "Warning `f': gmin(" in green "`gmin'" as err ") > min_`v1'(" in green "`varmin'" _c 
				di as err ") - min_`v1' will be used."
			}
			else {
				local varmin = `gmin'
			}
		}
		else {
			if ("`lmin'" != "" & "`lmin'" != ".") {
				if (`lmin' > `varmin') {
					di as err "Warning `f': " in green "`lmin'" as err " > min_`v1'(" in green "`varmin'" _c 
					di as err ") -- min_`v1' will be used."
				}
				else {
					local varmin = `lmin'
				}
			}
		}
		
		if ("`gmax'" != "" ) {
			if (`gmax' < `varmax') {
				di as err "Warning `f': gmax(" in green "`gmax'" as err ") < max_`v1'(" in green "`varmax'" _c 
				di as err ") - max_`v1' will be used."
			}
			else {
				local varmax = `gmax'
			}
		}
		else {
			if ("`lmax'" != "" & "`lmax'" != ".") {
				if (`lmax' < `varmax') {
					di as err "Warning `f': " in green "`lmax'" as err " < max_`v1'(" in green "`varmax'" _c 
					di as err ") -- max_`v1' will be used."
				}
				else {
					local varmax = `lmax'
				}
			}
		}
		
		chscale `v1' `z`c'' `varmin' `varmax'
		// reverse the values of hslant to match Flury & Riedwyl (1981)
		// if hslant, hdark, and hlower are all 1, a hair is drawn over the face - force all three down to .99
		if ("`f'"=="hslant") qui replace `z`c'' = abs(`z`c''-1)*.99
		if ("`f'"=="hdark" | "`f'"=="hlower") qui replace `z`c'' = `z`c''*.99
	  qui replace `z`c'' = (`rescale' - `shift')*`z`c'' + `shift'
  	qui replace `z`c'' = .5 if `z`c'' == .
  }
  local c = `c'+1
}

if "`timer'" == "timer" {
  capture timer clear 1
  timer on 1
}

serset clear
local nsersets = 0

forval f = 1/`faces' {
  
	//di as err "processing face `f'"
	
  // begin construction of face +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  
  //list in 1
  
  local z1F = `z1'[`f']
  local z2F = `z2'[`f']
  local z3F = `z3'[`f']
  local z4F = `z4'[`f']
  local z5F = `z5'[`f']
  local z6F = `z6'[`f']
  local z7F = `z7'[`f']
  local z8F = `z8'[`f']
  local z9F = `z9'[`f']
  local z10F = `z10'[`f']
  local z11F = `z11'[`f']
  local z12F = `z12'[`f']
  local z13F = `z13'[`f']
  local z14F = `z14'[`f']
  local z15F = `z15'[`f']
  local z16F = `z16'[`f']
  local z17F = `z17'[`f']
  local z18F = `z18'[`f']
  
  ********************************************* EYES Z1-Z6 ++++++++++++++++++++++++++++++++++
  
  local h = 1.5
  local dmin = .2
  local dmax = 1.2
  local rpmin = .2
  local rpmax = 1.2
  local pshift = 1
  
  local xm = 2 + 2*`z5F'
  local ym = 2*`z6F' - 1
  local xl = `xm' - `h'
  local xr = `xm' + `h'
  
  local psi = (`z4F' - .5)*(_pi/2)
  local cospsi = cos(`psi')
  local sinpsi = sin(`psi')
  
  local d = `dmin' + `z1F'
  
  if `d' <= .05 {
    rotate `xl' `xm' `cospsi' `sinpsi' `xm' `ym'
    local xl = `r(outx)'
    local ym = `r(outy)'
    rotate `xr' `xm' `cospsi' `sinpsi' `xm' `ym'
    local xr = `r(outx)'
    local ym = `r(outy)' // same as ym above
  }
  else {
    if `d' > `h' local d = `h'
    
    qui gen `X1' = . // upper eye line xxx
    qui gen `Y1' = .
    qui gen `X2' = . // lower eye line
    qui gen `Y2' = .
    
    local y0 = `ym' - (`h'+`d')*(`h'-`d') / (2*`d')
    local rad2 = (`ym' - `y0' + `d')^2
    
    // upper eye line
    local xx = `xl'
    local yy = `y0' + sqrt(max(0, `rad2' - (`xx'-`xm')^2))
    rotate `xx' `yy' `cospsi' `sinpsi' `xm' `ym'
    local xx = `r(outx)'
    local yy = `r(outy)'
    
    qui replace `X1' = `xx' in 1
    qui replace `Y1' = `yy' in 1
    
    forval i = 2/26 {
      local xx = `xl' + (`i'-1)*(`h'/25)
      local yy = `y0' + sqrt(max(0, `rad2' - (`xx'-`xm')^2))
      rotate `xx' `yy' `cospsi' `sinpsi' `xm' `ym'
      local xx = `r(outx)'
      local yy = `r(outy)'
      
      qui replace `X1' = `xx' in `i'
      qui replace `Y1' = `yy' in `i'
    }
    
    forval i = 27/51 {
      local ii = 52 - `i'
      local x1 = `xl' + (`ii'-1)*(`h'/25)
      
      local xx = 2*`xm' - `x1'
      local yy = `y0' + sqrt(max(0, `rad2' - (`x1'-`xm')^2))
      rotate `xx' `yy' `cospsi' `sinpsi' `xm' `ym'
      local xx = `r(outx)'
      local yy = `r(outy)'
      
      qui replace `X1' = `xx' in `i'
      qui replace `Y1' = `yy' in `i'
    }
    
    qui gen `X1L' = -`X1'
    
    // lower eye line
    local xx = 2*`xm' - `xl'
    local yy = 2*`ym' - `y0' - sqrt(max(0, `rad2' - (`xl'-`xm')^2))
    rotate `xx' `yy' `cospsi' `sinpsi' `xm' `ym'
    local xx = `r(outx)'
    local yy = `r(outy)'
    
    qui replace `X2' = `xx' in 1
    qui replace `Y2' = `yy' in 1
    
    forval i = 2/26 {
      local x1 = `xl' + (`i'-1)*(`h'/25)
      local xx = 2*`xm' - `x1'
      local y1 = `y0' + sqrt(max(0, `rad2' - (`x1'-`xm')^2))
      local yy = 2*`ym' - `y1'
      
      rotate `xx' `yy' `cospsi' `sinpsi' `xm' `ym'
      local xx = `r(outx)'
      local yy = `r(outy)'
      
      qui replace `X2' = `xx' in `i'
      qui replace `Y2' = `yy' in `i'
    }
    
    forval i = 27/51 {
      local ii = 52 - `i'
      local xx = `xl' + (`ii'-1)*(`h'/25)
      local y1 = `y0' + sqrt(max(0, `rad2' - (`xx'-`xm')^2))
      local yy = 2*`ym' - `y1'
      
      rotate `xx' `yy' `cospsi' `sinpsi' `xm' `ym'
      local xx = `r(outx)'
      local yy = `r(outy)'
      
      qui replace `X2' = `xx' in `i'
      qui replace `Y2' = `yy' in `i'
    }
    
    qui gen `X2L' = -`X2'
    
    qui gen `X3' = . // upper pupil line
    qui gen `Y3' = .
    
    qui gen `X4' = . // lower pupil line
    qui gen `Y4' = .
    
    local rpup = `rpmin' + `z2F' // pupil size
    if `rpup' < 0 local rpup = 0
    
    local xpup = `xm' + (`z3F' - .5)*`pshift' // pupil position
    
    // upper pupil line
    local xx = `xpup' - `rpup'
    if `xx' < `xl' local xx = `xl'
    if `xx' > `xr' local xx = `xr'
    
    local yy = `ym'
    local hp = `y0' + sqrt(max(0, `rad2' - (`xx'-`xm')^2))
    local yy = min(`yy',`hp')
    
    rotate `xx' `yy' `cospsi' `sinpsi' `xm' `ym'
    local xx = `r(outx)'
    local yy = `r(outy)'
    
    forval i = 2/51 {
      local fi = (_pi/2)*(`i'-1)/25
      local xx = `xpup' - `rpup'*cos(`fi')
      if `xx' < `xl' local xx = `xl'
      if `xx' > `xr' local xx = `xr'
      local yy = `ym' + `rpup'*sin(`fi')
      local hp = `y0' + sqrt(max(0, `rad2' - (`xx'-`xm')^2))
      local yy = min(`yy',`hp')
      
      rotate `xx' `yy' `cospsi' `sinpsi' `xm' `ym'
      local xx = `r(outx)'
      local yy = `r(outy)'
      
      qui replace `X3' = `xx' in `i'
      qui replace `Y3' = `yy' in `i'
    }
    
    qui gen `X3L' = -`X3'
    
    // lower pupil line
    local fi = (_pi/2)
    local xx = `xpup' - `rpup'*cos(`fi')
    if `xx' < `xl' local xx = `xl'
    if `xx' > `xr' local xx = `xr'
    local yy = `ym' + `rpup'*sin(`fi')
    local hp =  `y0' + sqrt(max(0, `rad2' - (`xx'-`xm')^2))
    local yy = min(`yy',`hp')
    local yy = 2*`ym' - `yy'
    
    rotate `xx' `yy' `cospsi' `sinpsi' `xm' `ym'
    local xx = `r(outx)'
    local yy = `r(outy)'
    
    forval i = 2/51 {
      local ii = 52-`i'
      
      local fi = (_pi/2)*(`ii'-1)/25
      local xx = `xpup' - `rpup'*cos(`fi')
      if `xx' < `xl' local xx = `xl'
      if `xx' > `xr' local xx = `xr'
      
      local yy = `ym' + `rpup'*sin(`fi')
      local hp = `y0' + sqrt(max(0, `rad2' - (`xx'-`xm')^2))
      local yy = min(`yy',`hp')
      local yy = 2*`ym' - `yy'
      
      rotate `xx' `yy' `cospsi' `sinpsi' `xm' `ym'
      local xx = `r(outx)'
      local yy = `r(outy)'
      
      qui replace `X4' = `xx' in `i'
      qui replace `Y4' = `yy' in `i'
    }
    
    qui gen `X4L' = -`X4'
  }
  
  ***************************************** EYEBROWS Z7-Z10 ++++++++++++++++++++++++++++++++
  qui gen `X7' = .
  qui gen `Y7' = .
  
  local xb = 2 + 2*`z9F'
  local yb = 1 + 2*`z10F'
  local dens = `z8F'/2
  local xl = `xb'-2
  local dmin = -1
  local dmax = .5
  local d = `dmin' + 1.5*`z7F'
  local c = `d' / (`h')^2
  
  qui replace `X7' = `xl' in 1
  qui replace `Y7' = `yb' + `c'*(`xl' - `xb')^2 - `dens' in 1
  
  forval i = 2/25 {
    local xx = `xl' + (`i'-1)*(2/12)
    qui replace `X7' = `xx' in `i'
    
    local yy = `yb' + `c'*(`xx' - `xb')^2 + ((-1)^`i')*`dens'
    qui replace `Y7' = `yy' in `i'
  }
  
  qui gen `X7L' = -`X7'
  
  
  ********************************************* FACE & HAIRLINE ++++++++++++++++++++++++++++
  
  ************************************************ FACE LINE Z13
  qui gen `Xface' = .
  qui gen `Yface' = .
  qui replace `Xface' = 7 in 1
  qui replace `Yface' = 0 in 1
  
  forval i = 2/96 {
  	local r = -1 + (`i'-1)/48
  	
  	poly5 `r' 4.6951 -2.6606 .1939 -1.3368 -1.4519 .5025
  	local min = `r(out)'
  	poly5 `r' 6.3767 -2.1462 -4.1037 -2.9179 1.2404 1.5972
  	local max = `r(out)'
  	qui replace `Xface' = `min' + `z13F'*(`max' - `min') in `i'
  	
  	poly5 `r' -4.7097 -5.4093 -2.2439 .2125 1.9345 .2350
  	local min = `r(out)'
  	poly5 `r' -6.5371 -8.7286 1.2045 7.5676 .3321 -3.8549
  	local max = `r(out)'
  	qui replace `Yface' = `min' + `z13F'*(`max' - `min') in `i'
  }
  
  qui replace `Xface' = 0 in 97
  qui replace `Yface' = -10 in 97
  qui gen `XfaceL' = -`Xface'
  
  
  ********************************************** LOWER HAIR LINE Z12
  qui gen `Xlow' = .
  qui gen `Ylow' = .
  qui replace `Xlow' = 0 in 1
  qui replace `Ylow' = 6.5 in 1
  
  forval i = 2/120 {
    local k = -1 + (`i'-1)/22
    local h = -1 + (`i'-1)/60
    
    if `i' < 45 {    
      poly5 `k' 2.3096 2.7696 -.2053 -.2040 .3026 -.1693
      local min = `r(out)'
      poly5 `h' 3.5608 4.0885 .2812 -.5919 -.3595 .0412
      local max = `r(out)'
      qui replace `Xlow' = `min' + `z12F'*(`max' - `min') in `i'
      
      poly5 `k' 8.1185 .3246 -1.5201 .3933 .1948 -.4255
  	  local min = `r(out)'
  	  poly5 `h' 3.9792 -1.9186 -.8270 -.9849 .1044 -.3504
  	  local max = `r(out)'
  	  qui replace `Ylow' = `min' + `z12F'*(`max' - `min') in `i'
  	}
  	else if `i' > 44 & `i' < 102 {
  	  poly5 `h' 5.5221 3.7880 -3.0211 -.2974 .9965 .0660
  	  local min = `r(out)'
  	  poly5 `h' 3.5608 4.0885 .2812 -.5919 -.3595 .0412
  	  local max = `r(out)'
  	  qui replace `Xlow' = `min' + `z12F'*(`max' - `min') in `i'
  	  
  	  poly5 `h' 6.1704 -5.6920 -.5460 .9206 -.6389 -.2504 
  	  local min = `r(out)'
  	  poly5 `h' 3.9792 -1.9186 -.8270 -.9849 .1044 -.3504
  	  local max = `r(out)'
  	  qui replace `Ylow' = `min' + `z12F'*(`max' - `min') in `i'
  	}
  	else {
  	  local obs = `i'-101
  	  
  	  local sub = `Xface'[`obs']
  	  qui replace `Xlow' = `sub' in `i'
  	  
  	  local sub = `Yface'[`obs']
  	  qui replace `Ylow' = `sub' in `i'
  	}
  }
  
  local sub = `Xface' in 20
  qui replace `Xlow' = `sub' in 121
  local sub = `Yface' in 20
  qui replace `Ylow' = `sub' in 121
  
  qui gen `XlowL' = -`Xlow'
  
  
  ************************************************ UPPER HAIR LINE Z11
  
  qui gen `Xup' = .
  qui gen `Yup' = .
  qui replace `Xup' = 0 in 1
  qui replace `Yup' = 9.9 in 1
  
  forval i = 2/120 {
    local h = -1 + (`i'-1)/51
    local t = -1 + (`i'-1)/60
    
    if `i' < 102 {
      poly5 `h' 5.5221 3.7880 -3.0211 -.2974 .9965 .0660
      local min = `r(out)'
      poly5 `t' 8.1147 2.7487 -7.3495 4.2360 2.8299 -3.5240
      local max = `r(out)'
      qui replace `Xup' = `min' + `z11F'*(`max' - `min') in `i'
      
      poly5 `h' 6.1704 -5.6920 -.5460 .9206 -.6389 -.2504
  	  local min = `r(out)'
  	  poly5 `t' 6.7029 -10.3740 -3.6243 5.8058 .5964 -1.5585
  	  local max = `r(out)'
  	  qui replace `Yup' = `min' + `z11F'*(`max' - `min') in `i'
  	}
  	else {
  	  local obs = `i'-101
  	  
  	  local sub = `Xface'[`obs']
  	  poly5 `t' 8.1147 2.7487 -7.3495 4.2360 2.8299 -3.5240
  	  local max = `r(out)'
  	  qui replace `Xup' = `sub' + `z11F'*(`max' - `sub') in `i'
  	  
  	  local sub = `Yface'[`obs']
  	  poly5 `t' 6.7029 -10.3740 -3.6243 5.8058 .5964 -1.5585
  	  local max = `r(out)'
  	  qui replace `Yup' = `sub' + `z11F'*(`max' - `sub') in `i'
  	}
  }
  
  local sub = `Xface' in 20
  qui replace `Xup' = `sub' in 121
  local sub = `Yface' in 20
  qui replace `Yup' = `sub' in 121
  
  qui gen `XupL' = -`Xup'
  
  
  ****************************************** HAIR DENSITY Z14 & SHADING SLANT Z15
  local dd = 3*(1 - `z14F'*.9)
  if `dd' < .1 local dd = .1
  
  local angle = 45 - `z15F'*90
  local t1 = `angle' * (_pi/180)
  local co = cos(`t1')
  local si = sin(`t1')
  local xmin = 10000
  local xmax = -`xmin'
  
  qui gen `XXU' = .
  qui gen `YYU' = .
  qui gen `XXL' = .
  qui gen `YYL' = .
  
  qui gen `XT1' = .
  qui gen `YT1' = .
  qui gen `XT2' = .
  qui gen `YT2' = .
  
  forval i = 2/121 {
    
    local j = `i'-1
    local xupj = `Xup'[`j']
    local yupj = `Yup'[`j']
    local xlowj = `Xlow'[`j']
    local ylowj = `Ylow'[`j']
    
    rot `xupj' `yupj' `co' `si'
    local xxui = `r(out)'
    qui replace `XXU' = `xxui' in `i'
    if `xxui' > `xmax' local xmax = `xxui'
    if `xxui' < `xmin' local xmin = `xxui'
    
    rot `xupj' `yupj' -`si' `co'
    local yyui = `r(out)'
    qui replace `YYU' = `yyui' in `i'
    
    rot `xlowj' `ylowj' `co' `si'
    local xxli = `r(out)'
    qui replace `XXL' = `xxli' in `i'
    if `xxli' > `xmax' local xmax = `xxli'
    if `xxli' < `xmin' local xmin = `xxli'
    
    rot `xlowj' `ylowj' -`si' `co'
    local yyli = `r(out)'
    qui replace `YYL' = `yyli' in `i'
  }
  
  qui replace `XXL' = `XXL'[2] in 1
  qui replace `YYL' = `YYL'[2] in 1
  qui replace `XXU' = `XXL'[2] in 1
  qui replace `YYU' = `YYL'[2] in 1
  
  local xxu2 = `XXU'[2]
  local yyu2 = `YYU'[2]
  local xxl2 = `XXL'[2]
  local xup2 = `Xup'[2]
  
  if (`xxu2' < `xxl2' & `xup2' > 0 ) | (`xxu2' > `xxl2' & `xup2' < 0) {
    qui replace `XXL' = `XXU'[2] in 1
    qui replace `YYL' = `YYU'[2] in 1
    qui replace `XXU' = `XXU'[2] in 1
    qui replace `YYU' = `YYU'[2] in 1
  }
  
  if `xup2' > 0 {
    local x0 = `dd' + `xmin'
  }
  else {
    local x0 = `xmax' - `dd'
  }
  
  local hair = " || pci 0 0 0 0 "
  local DONE = 0
  while `DONE' == 0 {
    
    local nl = 0
    local nu = 0
    
    forval i = 1/120 {
      local j = `i'+1
      local xxui = `XXU'[`i']
      local xxuj = `XXU'[`j']
      local yyui = `YYU'[`i']
      local yyuj = `YYU'[`j']
      
      if (`xxui' < `x0' & `xxuj' > `x0') | (`xxui' > `x0' & `xxuj' < `x0') {
        local nu = `nu'+1
        qui replace `XT1' = `x0' in `nu'
        qui replace `YT1' = ((`yyui'-`yyuj')*`x0' -(`yyui'*`xxuj' - `yyuj'*`xxui')) / (`xxui'-`xxuj') in `nu'
      }
      
      local xxli = `XXL'[`i']
      local xxlj = `XXL'[`j']
      local yyli = `YYL'[`i']
      local yylj = `YYL'[`j']
      
      if (`xxli' < `x0' & `xxlj' > `x0') | (`xxli' > `x0' & `xxlj' < `x0') {
        local nl = `nl'+1
        qui replace `XT2' = `x0' in `nl'
        qui replace `YT2' = ((`yyli'-`yylj')*`x0' -(`yyli'*`xxlj' - `yylj'*`xxli')) / (`xxli'-`xxlj') in `nl'
      }
    }
    
    local xt11 = `XT1'[1]
    local xt12 = `XT1'[2]
    local yt11 = `YT1'[1]
    local yt12 = `YT1'[2]
    
    local xt21 = `XT2'[1]
    local xt22 = `XT2'[2]
    local yt21 = `YT2'[1]
    local yt22 = `YT2'[2]
    
    //di in red "nl = `nl', nu = `nu'"
    
    if (`nl'==0 & `nu'==2) {    	
      rot `xt11' `yt11' `co' -`si'
      local x1 = `r(out)'
      
      rot `xt11' `yt11' `si' `co'
      local y1 = `r(out)'
      
      rot `xt12' `yt12' `co' -`si'
      local x2 = `r(out)'
      
      rot `xt12' `yt12' `si' `co'
      local y2 = `r(out)'
      
      if ("`lhalf'" == "") {
      	//local hair "`hair' || pci `y1' `x1' `y2' `x2', lcolor(black)"
	local hair "`hair' `y1' `x1' `y2' `x2' "
      }
      
      if ("`rhalf'" == "") {
      	local x1 = -`x1' // left-hand side
      	local x2 = -`x2'
      	//local hair "`hair' || pci `y1' `x1' `y2' `x2', lcolor(black)"
	local hair "`hair' `y1' `x1' `y2' `x2' "
      }
    }
    else if (`nl'==2 & `nu'==0) {    	
      rot `xt21' `yt21' `co' -`si'
      local x1 = `r(out)'
      
      rot `xt21' `yt21' `si' `co'
      local y1 = `r(out)'
      
      rot `xt22' `yt22' `co' -`si'
      local x2 = `r(out)'
      
      rot `xt22' `yt22' `si' `co'
      local y2 = `r(out)'
      
      if ("`lhalf'" == "") {
      	//local hair "`hair' || pci `y1' `x1' `y2' `x2', lcolor(black)"
	local hair "`hair' `y1' `x1' `y2' `x2' "
      }
      
      if ("`rhalf'" == "") {
      	local x1 = -`x1' // left-hand side
      	local x2 = -`x2'
      	//local hair "`hair' || pci `y1' `x1' `y2' `x2', lcolor(black)"
	local hair "`hair' `y1' `x1' `y2' `x2' "
      }
    }
    else if (`nl' >= 1 & `nu'==1) | (`nl'==1 & `nu' >= 1) {    	
      rot `xt11' `yt11' `co' -`si'
      local x1 = `r(out)'
      
      rot `xt11' `yt11' `si' `co'
      local y1 = `r(out)'
      
      rot `xt21' `yt21' `co' -`si'
      local x2 = `r(out)'
      
      rot `xt21' `yt21' `si' `co'
      local y2 = `r(out)'
      
      if ("`lhalf'" == "") {
      	//local hair "`hair' || pci `y1' `x1' `y2' `x2', lcolor(black)"
	local hair "`hair' `y1' `x1' `y2' `x2' "
      }
      
      if ("`rhalf'" == "") {
      	local x1 = -`x1' // left-hand side
      	local x2 = -`x2'
      	//local hair "`hair' || pci `y1' `x1' `y2' `x2', lcolor(black)"
	local hair "`hair' `y1' `x1' `y2' `x2' "
      }
    }
    else if (`nl'==2 & `nu'==2) {    	
      if (`yt11' < `yt12' & `yt21' < `yt22') | (`yt11' > `yt12' & `yt21' > `yt22') {
        rot `xt11' `yt11' `co' -`si'
        local x1 = `r(out)'
        
        rot `xt11' `yt11' `si' `co'
        local y1 = `r(out)'
        
        rot `xt21' `yt21' `co' -`si'
        local x2 = `r(out)'
        
        rot `xt21' `yt21' `si' `co'
        local y2 = `r(out)'
        
        if ("`lhalf'" == "") {
        	//local hair "`hair' || pci `y1' `x1' `y2' `x2', lcolor(black)"
		local hair "`hair' `y1' `x1' `y2' `x2' "
        }
        
        if ("`rhalf'" == "") {
        	local x1 = -`x1' // left-hand side
        	local x2 = -`x2'
        	//local hair "`hair' || pci `y1' `x1' `y2' `x2', lcolor(black)"
		local hair "`hair' `y1' `x1' `y2' `x2' "
        }
        
        rot `xt12' `yt12' `co' -`si'
        local x1 = `r(out)'
        
        rot `xt12' `yt12' `si' `co'
        local y1 = `r(out)'
        
        rot `xt22' `yt22' `co' -`si'
        local x2 = `r(out)'
        
        rot `xt22' `yt22' `si' `co'
        local y2 = `r(out)'
        
        if ("`lhalf'" == "") {
        	//local hair "`hair' || pci `y1' `x1' `y2' `x2', lcolor(black)"
		local hair "`hair' `y1' `x1' `y2' `x2' "
        }
        
        if ("`rhalf'" == "") {
        	local x1 = -`x1' // left-hand side
        	local x2 = -`x2'
        	//local hair "`hair' || pci `y1' `x1' `y2' `x2', lcolor(black)"
		local hair "`hair' `y1' `x1' `y2' `x2' "
        }
      }
      else {      	
        rot `xt11' `yt11' `co' -`si'
        local x1 = `r(out)'
        
        rot `xt11' `yt11' `si' `co'
        local y1 = `r(out)'
        
        rot `xt22' `yt22' `co' -`si'
        local x2 = `r(out)'
        
        rot `xt22' `yt22' `si' `co'
        local y2 = `r(out)'
        
        if ("`lhalf'" == "") {
        	//local hair "`hair' || pci `y1' `x1' `y2' `x2', lcolor(black)"
		local hair "`hair' `y1' `x1' `y2' `x2' "
        }
        
        if ("`rhalf'" == "") {
        	local x1 = -`x1' // left-hand side
        	local x2 = -`x2'
        	//local hair "`hair' || pci `y1' `x1' `y2' `x2', lcolor(black)"
		local hair "`hair' `y1' `x1' `y2' `x2' "
        }
        
        rot `xt12' `yt12' `co' -`si'
        local x1 = `r(out)'
        
        rot `xt12' `yt12' `si' `co'
        local y1 = `r(out)'
        
        rot `xt21' `yt21' `co' -`si'
        local x2 = `r(out)'
        
        rot `xt21' `yt21' `si' `co'
        local y2 = `r(out)'
        
        if ("`lhalf'" == "") {
        	//local hair "`hair' || pci `y1' `x1' `y2' `x2', lcolor(black)"
		local hair "`hair' `y1' `x1' `y2' `x2' "
        }
        
        if ("`rhalf'" == "") {
        	local x1 = -`x1' // left-hand side
        	local x2 = -`x2'
        	//local hair "`hair' || pci `y1' `x1' `y2' `x2', lcolor(black)"
		local hair "`hair' `y1' `x1' `y2' `x2' "
        }
      }
    }
    
    local xup = `Xup'[2]
    
    if `xup' > 0 {
      local x0 = `x0' + `dd'
      if `x0' >= `xmax' local DONE = 1
    }
    else {
      local x0 = `x0' - `dd'
      if `x0' <= `xmin' local DONE = 1
    }
  }
  
  if (`z15F' < .51 & `z15F' > .49) { // xxx
    local xx2 = `XXL'[1]
    local yy2 = `YYL'[1]
    //local hair "`hair' || pci 9.9 0 `yy2' `xx2', lcolor(black)"
    local hair "`hair' 9.9 0 `yy2' `xx2' "
  }
  
  local hair "`hair', lcolor(black)"
  //di as err "hair is" _n as err "`hair'"
  
  ************************************ NOSE LINE Z16
  local ti = 2.282
  
  poly5 `ti' 1.2245 -.4339 .1431 -.0135 -.1396 .0537
  local x1t = `r(out)'
  local xx = .3 + `z16F'*(`x1t' - .3)
  
  qui gen `X16' = .
  qui gen `Y16' = .
  
  qui replace `X16' = `xx' in 1
  qui replace `Y16' = 0 in 1
  
  forval i = 2/81 {
    local yy = -((`i'-1)/20)
    qui replace `Y16' = `yy' in `i'
    
    local ti = `yy' + 2.282
    poly5 `ti' 1.2245 -.4339 .1431 -.0135 -.1396 .0537
    local x1t = `r(out)'
    qui replace `X16' = .3 + (`z16F'*(`x1t'-.3)) in `i'
  }
  
  qui gen `X16L' = -`X16'
  
  
  ************************************ MOUTH SIZE Z17 & MOUTH CURVATURE Z18
  local d = (`z18F' - .5)/3
  
  qui gen `X17' = .
  qui gen `Y17' = .
  
  qui replace `X17' = 0 in 1
  qui replace `Y17' = -6 in 1
  
  forval i = 2/30 {
    qui replace `X17' = (`i'-1)/10 in `i'
    
    local xx = `X17'[`i']
    local ti = `xx' - 1.5
    poly5 `ti' -6.1531 -.1583 -.0347 -.0418 -.0038 .0174
    local x0t = `r(out)'
    poly5 `ti' -5.7326 -.3889 -.1487 .0233 -.0366 .0347
    local x1t = `r(out)'
    
    local yy1 = `x0t' + `z17F'*(`x1t' - `x0t')
    local a = `d'*(`xx')^2
    qui replace `Y17' = `yy1' + `a' in `i'
  }
  
  qui replace `X17' = 3 in 31
  qui replace `Y17' = -6.5 + 9*`d' in 31
  
  qui gen `X17L' = -`X17'
  
  **************************************** Z18
  qui gen `X18' = .
  qui gen `Y18' = .
  
  qui replace `X18' = 0 in 1
  qui replace `Y18' = -7 in 1
  
  forval i = 2/30 {
    qui replace `X18' = (`i'-1)/10 in `i'
    
    local xx = `X18'[`i']
    local ti = `xx' - 1.5
    poly5 `ti' -6.6522 .1503 -.0513 .0402 .0040 -.0148
    local x0t = `r(out)'
    poly5 `ti' -6.9965 .0482 .0609 .0191 .0201 .0144
    local x1t = `r(out)'
    
    local yy1 = `x0t' + `z17F'*(`x1t' - `x0t')
    local a = `d'*(`xx')^2
    qui replace `Y18' = `yy1' + `a' in `i'
  }
  
  qui replace `X18' = 3 in 31
  qui replace `Y18' = -6.5 + 9*`d' in 31
  
  qui gen `X18L' = -`X18'
  
  // check for _null_ ++++++++++++++++++++++++++++++++++++++++++++++++++ $$$
  local c = 1
	foreach null of local facef {
		tokenize `"``null''"', parse("(), ")
		local head `1'
		//di in yellow "head is `head'"
		macro shift
		macro shift
		local v1 `1'
		//di in yellow "v1 is `v1'"
	 	
		if ("`v1'" == "_null_") {
			if ("`head'" == "nose") {
				qui replace `X16' = .
				qui replace `X16L' = .
			}
			if ("`head'" == "fline") {
				qui replace `Xface' = .
				qui replace `XfaceL' = .
			}
			if ("`head'" == "bcurv" | "`head'" == "bdens" | "`head'" == "bhor" | "`head'" == "bvert") {
				qui replace `X7' = .
				qui replace `X7L' = .
			}
			if ("`head'" == "isize" | "`head'" == "ihor" | "`head'" == "ivert" | "`head'" == "iangle") {
				qui replace `X1' = .
				qui replace `X1L' = .
				qui replace `X2' = .
				qui replace `X2L' = .
			}
			if ("`head'" == "hdark" | "`head'" == "hslant") {
				local hair = ""
			}
			if ("`head'" == "hupper") {
				qui replace `Xup' = .
				qui replace `XupL' = .
			}
			if ("`head'" == "hlower") {
				qui replace `Xlow' = .
				qui replace `XlowL' = .
			}
			if ("`head'" == "msize" | "`head'" == "mcurv" ) {
				qui replace `X17' = .
				qui replace `X17L' = .
				qui replace `X18' = .
				qui replace `X18L' = .
			}
			if ("`head'" == "psize" | "`head'" == "ppos" ) {
				qui replace `X3' = .
				qui replace `X3L' = .
				qui replace `X4' = .
				qui replace `X4L' = .
			}
  	}
  	local c = `c'+1
  }
  
  // construction of face finished ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  
  local FACE`f' "FACE`f'" // do not use tempfile as they are written to c(tmpdir) 
                          // and network users may not have access to it
  local FACES "`FACES' `FACE`f''.gph"
  
  if "`show'" != "show" {
    local noshow "nodraw" // do not draw individual face graphs
  }
  
  if "`ititle'" == "" {
  	local facetitle = ""
  }
  else {
  	local facetitle = `ititle'[`f']
  }
  
  if "`inote'" == "" {
  	local facenote = ""
  }
  else {
  	local facenote = `inote'[`f']
  }
  
  if "`iscale'" == "" {
  	local facescale = 1
  }
  else {
  	local facescale = `iscale'[`f']
  }
  
  if "`ilabel'" == "" {
    local facelbl = ""
  }
  else {
    local flbl = `ilabel'[`f']
    
    if ("`lhalf'" != "") { // defaults for left face
    	if `xlabel' == 64 local xlabel = -8
    	if `placement' == 64 local placement = 3
    	if "`justification'" == "" local justification = "right"
    }
    else if ("`rhalf'" != "") { // defaults for right face
    	if `xlabel' == 64 local xlabel = 8
    	if `placement' == 64 local placement = 9
    	if "`justification'" == "" local justification = "left"
    }
    else { // full face
    	if `xlabel' == 64 local xlabel = 10
    	if `placement' == 64 local placement = 9
    	if "`justification'" == "" local justification = "left"
    }
    
    tokenize `lsize', parse("()")
  	macro shift
  	macro shift
  	local lblsize `1'
  	if ("`lblsize'" == "") local lblsize = "large"
    local facelbl "text(`ylabel' `xlabel' `"`flbl'"', place(`placement') just(`justification') size(`lblsize'))"
  }
  
  tokenize `imargin', parse("()")
  macro shift
  macro shift
  local mgnsize `1'
  if (`"`imargin'"' == "") {
  	local imargin = "margin(zero)" // default margin for faces is zero
  }
  else {
  	local imargin = `"margin(`mgnsize')"'
  }
  
  tokenize `iregion', parse("()")
  macro shift
  macro shift
  local rgnsize `1'
  if (`"`iregion'"' == "") {
  	local iregion = "margin(medsmall)" // default margin fof faces is medsmall
  }
  else {
  	local iregion = `"margin(`rgnsize')"'
  }
  
  if ("`rhalf'" != "") { // draw only the right side of the face
  	qui replace `XfaceL' = .
  	qui replace `XlowL'  = .
  	qui replace `XupL'   = .
  	qui replace `X16L'   = .
  	qui replace `X17L'   = .
  	qui replace `X18L'   = .
  	qui replace `X7L'    = .
  	qui replace `X1L'    = .
  	qui replace `X2L'    = .
  	qui replace `X3L'    = .
  	qui replace `X4L'    = .
  }
  
  if ("`lhalf'" != "") { // draw only the left side of the face
  	qui replace `Xface'  = .
  	qui replace `Xlow'   = .
  	qui replace `Xup'    = .
  	qui replace `X16'    = .
  	qui replace `X17'    = .
  	qui replace `X18'    = .
  	qui replace `X7'     = .
  	qui replace `X1'     = .
  	qui replace `X2'     = .
  	qui replace `X3'     = .
  	qui replace `X4'     = .
  }
  
  local aspectratio = "aspectratio(1.2, placement(center))"
  if (`"`lhalf'"' != "" | `"`rhalf'"' != "") {
  	local aspectratio = "aspectratio(2.4, placement(center))"
  }
  
  if ("`rhalf'" != "" | "`lhalf'" != "") {
  	local forcedX = 50
  }
  else {
  	local forcedX = 100
  }
  
  qui twoway line `Yface' `Xface', lcolor(black) || line `Yface' `XfaceL', lcolor(black) ///
    || line `Ylow' `Xlow', lcolor(black) || line `Ylow' `XlowL', lcolor(black) ///
    || line `Yup' `Xup', lcolor(black) || line `Yup' `XupL', lcolor(black) ///
  	|| line `Y16' `X16', lcolor(black) || line `Y16' `X16L', lcolor(black) ///
  	|| line `Y17' `X17', lcolor(black) || line `Y18' `X18', lcolor(black) ///
  	|| line `Y17' `X17L', lcolor(black) || line `Y18' `X18L', lcolor(black) ///
  	|| line `Y7' `X7', lcolor(black) lwidth(medthick) || line `Y7' `X7L', lcolor(black) lwidth(medthick) ///
  	|| line `Y1' `X1', lcolor(black) || line `Y2' `X2', lcolor(black) ///
  	|| line `Y1' `X1L', lcolor(black) || line `Y2' `X2L', lcolor(black) ///
  	|| line `Y3' `X3', lcolor(black) || line `Y4' `X4', lcolor(black) ///
  	|| line `Y3' `X3L', lcolor(black) || line `Y4' `X4L', lcolor(black) ///
  	`hair' `facelbl' ///
  	, legend(off) xscale(off) yscale(off) xlabel(,nogrid) ylabel(,nogrid) xsize(`xface') ysize(`yface') ///
	  fxsize(`forcedX') fysize(100) saving("`FACE`f''",replace) `noshow' graphregion(color(white) `imargin') ///
	  note(`"`facenote'"', color(black)) title(`"`facetitle'"', color(black)) scale(`facescale') `aspectratio' ///
	  plotregion(`iregion')
  	
	//serset dir
	qui serset
	local rid = `r(id)'
	if `r(id)' == 0 local rid = 1
	local nsersets = `nsersets' + `rid'
	
	capture confirm file FACE0.gph
	if _rc { // draw blank graph - but only once
	   quietly twoway line `Yface' `Xface', lcolor(white) legend(off) xscale(off) yscale(off) ///
	     || line `Yup' `Xup', lcolor(white) legend(off) xscale(off) yscale(off) xsize(`xface') ysize(`yface') ///
	     fxsize(`forcedX') fysize(100) xlabel(,nogrid) ylabel(,nogrid) saving(FACE0, replace) nodraw ///
	     graphregion(color(white) `imargin') `aspectratio'
	}
	
	//drop `z1' `z2' `z3' `z4' `z5' `z6' `z7' `z8' `z9' `z10' `z11' `z12' `z13' `z14' `z15' `z16' `z17' `z18'
  drop `X1' `Y1' `X1L' `X2' `Y2' `X2L' `X3' `Y3' `X3L' `X4' `Y4' `X4L' `X7' `Y7' `X7L' `X16' `Y16' `X16L' `X17' `Y17' `X17L' `X18' `Y18' `X18L'
  drop `Xface' `Yface' `XfaceL' `Xlow' `Ylow' `XlowL' `Xup' `Yup' `XupL' `XXU' `YYU' `XXL' `YYL' `XT1' `YT1' `XT2' `YT2'
} // end of individual faces construction

//di as err "number of sersets is `nsersets'"

if "`timer'" == "timer" {
  timer off 1
  timer list 1
  capture timer clear 2
  timer on 2
}

if "`nocombine'" == "" {
  // combine all individual graphs into one graph
  
  //di as err "number of sersets to combine is `nsersets'"
  if `nsersets' > 1999 {
	di as err "Number of sersets exceeds 1,999, cannot draw a combined graph."
	di as err "Individual face graphs are saved as FACE1.gph, ..., FACE`faces'.gph."
  }
  else {
    
  tokenize `rows', parse("()")
  macro shift
  macro shift
  local ROW `1'
  
  tokenize `cols', parse("()")
  macro shift
  macro shift
  local COL `1'
  
  tokenize `xcombined', parse("()")
  macro shift
  macro shift
  local XS `1'
  //di "XS is `XS'"
  
  tokenize `ycombined', parse("()")
  macro shift
  macro shift
  local YS `1'
  //di "YS is `YS'"
  
  // calculate the size of the combined graph if the user did not specify it
  
  if ("`XS'" == "" & "`YS'" == "") {
  
  	if ("`ROW'" == "" & "`COL'" == "") {
  		local COL = ceil(sqrt(`faces'))
  		local ROW = ceil(`faces' / `COL')
  	}
  	else if ("`COL'" == "") { // only rows() was specified
  		local COL = ceil(`faces' / `ROW')
  	}
  	else if ("`ROW'" == "") { // only cols() was specified
  		local ROW = ceil(`faces' / `COL')
  	}
  	else if ("`ROW'" != "" & "`COL'" != "") { // if both specified, cols() takes precedence
  		local ROW = ceil(`faces' / `COL')
  	}
  	
  	local YS = `ROW' * `yface'
  	local XS = `COL' * `xface'
  	if ("`rhalf'" != "" | "`lhalf'" != "") local XS = `XS'*`hspace' //.50 will keep half graphs close to each other
  	
  	// looks like graph dimensions cannot exceed 20 so rescale
  	local RCmax = max(`XS',`YS')
  	if (`RCmax' > 20) {
  		local shrink = 20 / `RCmax'
  		local XS = `XS' * `shrink'
  		local YS = `YS' * `shrink'
  	}
  }  
  
  gettoken SAVE RPL : saving , parse(",") quotes
  //di as res "saveas is " as res `"`SAVE'"'
  //di as res "replace is " as res "`RPL'"
  
  di
  di in yellow "Finished creating individual faces, now processing " in green "graph combine" in yellow "."
  di in yellow "Please be patient, it may take a while...."
  di
	
  // +++++++++++++++++++++++++++++++++++++++++ legend - displays legend in two or three rows $$$
	
  tokenize `legend'
  local legend1 `1'
  local legend2 `2'  
  
  if ("`legend1'" == "2" | "`legend1'" == "3") {
  	local note = "" // legend overrides graph note
  	
  	local features "isize iangle ihor ivert psize ppos bcurv bdens bhor bvert hupper hlower hdark hslant fline nose msize mcurv" 
  	local b2t = ""
  	local cap = ""
  	local r2t = ""
  	local c = 1
  	
		foreach f of local features {
		  tokenize `"``f''"', parse("(), ")
		  //di as err "f is `f' and ``f''"
	    macro shift
	    macro shift
	    local v1 `1'
	    //di as err "v1 is `v1'"
	    
			if ("`v1'" != "" & "`v1'" != "." & "`v1'" != "_null_") {
  			local feature = "`f'"
  			
  			if ("`legend2'" == "nolab" | "`legend2'" == "nolabe" | "`legend2'" == "nolabel") {
  				local vlegend = "`v1'"
  			}
  			else {
  				capture local vlegend : variable label `v1'
  				if ("`vlegend'" == "") local vlegend = "`v1'"
  			}
  			
  			if ("`legend1'"=="2") {
  				if (mod(`c',2) != 0) {
  					local b2t `"`b2t'"`feature' - `vlegend'" "'
  				}
  				else {
  					local cap `"`cap'"`feature' - `vlegend'" "'
  				}
  				local c = `c'+1
  			}
  			else if ("`legend1'"=="3") {
  				if (mod(`c',3)/3 == 1/3) {
  					local b2t `"`b2t'"`feature' - `vlegend'" "'
  				}
  				else if (mod(`c',3)/3 == 2/3) {
  					local cap `"`cap'"`feature' - `vlegend'" "'
  				}
  				else {
  					local r2t `"`r2t'"`feature' - `vlegend'" "'
  				}
  				local c = `c'+1
  			}
			}
		}
	}
	
  // if local SAVE is empty, specifying saving() creates Graph.gph - use IF .... ELSE to solve this problem
  if "`saving'" == "" {
     qui graph combine `FACES' , `title' `subtitle' `note' rows(`ROW') cols(`COL') `colfirst' ///
        scheme(s1mono) /*`imargin'*/ xsize(`XS') ysize(`YS') `draw' plotregion(margin(zero)) graphregion(margin(zero)) ///
        b2title(" " `b2t',size(vsmall) ring(1) justification(left) placement(west) pos(7)) ///
        caption(" " `cap',size(vsmall) ring(1) justification(left) placement(center) pos(5)) ///
        note(" " `r2t',size(vsmall) ring(1) justification(left) placement(east) pos(6))
  }
  else {
     qui graph combine `FACES' , `title' `subtitle' `note' rows(`ROW') cols(`COL') `colfirst' ///
        scheme(s1mono) /*`imargin'*/ xsize(`XS') ysize(`YS') `draw' plotregion(margin(zero)) graphregion(margin(zero)) ///
        b2title(" " `b2t',size(vsmall) ring(1) justification(left) placement(west) pos(7)) ///
        caption(" " `cap',size(vsmall) ring(1) justification(left) placement(center) pos(5)) ///
        note(" " `r2t',size(vsmall) ring(1) justification(left) placement(east) pos(6))
  }
} // end of else
}

if "`timer'" == "timer" {
  timer off 2
  timer list 2
}

//save or erase individual face graphs
if ("`saveall'" == "" & `nsersets' < 2000) {
   forval i = 1/`faces' {
      capture erase "`FACE`i''.gph"
   }
   erase FACE0.gph
}

qui drop if `one' == 0 // restore the original number of obs if it is less than 121

di
di in yellow "The command has finished."

end


***************************************************************** SUROUTINES +++++++++++++++++++++++++++++++++++++++
capture program drop poly5
program define poly5, rclass
   args x c0 c1 c2 c3 c4 c5
   
   return local out = ((((`c5'*(`x') + `c4')*(`x') + `c3')*(`x') + `c2')*(`x') + `c1')*(`x') + `c0'

end

capture program drop rotate
program define rotate, rclass
  args rdx rdy rc rs rzx rzy
  
  local rdx1 = `rdx' - `rzx'
  local rdy1 = `rdy' - `rzy'
  return local outx = `rc'*`rdx1' - `rs'*`rdy1' + `rzx'
  return local outy = `rs'*`rdx1' + `rc'*`rdy1' + `rzy'

end

capture program drop rot
program define rot, rclass
  args x y al be
  
  return local out = `x'*`al' + `y'*`be'

end

//standardize x to [0,1] range
capture program drop chscale
program define chscale
  args var1 var2 min max
  qui gen `var2' = (`var1' - `min') / (`max' - `min')
end

exit
