*! Version 1.0 - 29 January 2001  STB-60 sg162
*! -spatlsa- Measures of local spatial autocorrelation                         
*! Author: Maurizio Pisati                                                     
*! Department of Sociology and Social Research                                 
*! University of Milano Bicocca (Italy)                                        
*! maurizio.pisati@galactica.it                                                
*!                                                                             




*  ----------------------------------------------------------------------------
*  1. Define program                                                           
*  ----------------------------------------------------------------------------

program define spatlsa, rclass
version 7.0




*  ----------------------------------------------------------------------------
*  2. Define syntax                                                            
*  ----------------------------------------------------------------------------

syntax varname, Weights(string)             /*
           */   [Moran Geary GO1 GO2]       /*
           */   [id(varname)]               /*
           */   [TWOtail]                   /*
           */   [Sort]                      /*
           */   [GRaph(string)]              /*
           */   [SYmbol(string)]            /*
           */   [map(string)]               /*
           */   [Xcoord(varname numeric)]   /*
           */   [Ycoord(varname numeric)]   /*
           */   [SAVegraph(string)]




*  ----------------------------------------------------------------------------
*  3. Check syntax                                                             
*  ----------------------------------------------------------------------------

capture qui matrix list `weights'
if _rc==111 {
	di as err "Matrix `weights' does not exist"
	exit
}

local ROWNAME : rownames(`weights')
local COLNAME : colnames(`weights')
local WTYPE : word 1 of `ROWNAME'
local WBINA : word 2 of `ROWNAME'
local WSTAN : word 3 of `ROWNAME'
local LOW1 : word 1 of `COLNAME'
local LOW2 : word 2 of `COLNAME'
local LOWER "`LOW1'.`LOW2'"
local UPP1 : word 3 of `COLNAME'
local UPP2 : word 4 of `COLNAME'
local UPPER "`UPP1'.`UPP2'"
if "`WTYPE'"!="SWMImpo" & "`WTYPE'"!="SWMDist" {
	di as err "Matrix `weights' has not been created by -spatwmat-."
	di as err "To run -spatlsa-, create weights matrix with -spatwmat-"
	exit
}

local N=_N
local DIM=rowsof(`weights')
if `DIM'!=`N' {
	di as err "Matrix `weights' is `DIM'x`DIM', the dataset in use has `N' obs."
	di as err "To run -spatlsa- weights matrix dimension must equal N. of obs"
	exit
}

local STATLIST "`moran' `geary' `go1' `go2'"
local NSTATS : word count `STATLIST'
if `NSTATS'==0 {
	di as err "You must specify one or more of the following options:"
	di as err "{bf:{ul:m}oran}: Moran's Ii"
	di as err "{bf:{ul:g}eary}: Geary's ci"
	di as err "{bf:{ul:go1}}  : Getis and Ord's G1i"
	di as err "{bf:{ul:go2}}  : Getis and Ord's G2i"
	exit
}

if ("`go1'"!="" | "`go2'"!="") & "`WSTAN'"=="Yes" {
	di as err "Matrix `weights' is row-standardized."
	di as err "To compute Getis and Ord's G1i and G2i you must use a"
	di as err "non-standardized binary weights matrix"
	exit
}

if ("`go1'"!="" | "`go2'"!="") & "`WBINA'"=="No" {
	di as err "Spatial weights in matrix `weights' are not binary."
	di as err "To compute Getis and Ord's G1i and G2i you must use a"
	di as err "non-standardized binary weights matrix"
	exit
}

if "`graph'"!="" & "`graph'"!="moran" & "`graph'"!="geary"   /*
            */   & "`graph'"!="go1" & "`graph'"!="go2" {
	di as err "Option {bf:{ul:gr}aph({it:keyword})} accepts only one of the " _c
	di as err "following keywords:"
	di as err "{bf:moran} {bf:go1} {bf:go2}"
	exit
}

if "`graph'"=="moran" & "`moran'"=="" {
	di as err "If you specify option {bf:{ul:gr}aph(`graph')} you must " _c
	di as err "specify also option {bf:{ul:m}oran}"
	exit
}

if "`graph'"=="go1" & "`go1'"=="" {
	di as err "If you specify option {bf:{ul:gr}aph(`graph')} you must " _c
	di as err "specify also option {bf:{ul:go1}}"
	exit
}

if "`graph'"=="go2" & "`go2'"=="" {
	di as err "If you specify option {bf:{ul:gr}aph(`graph')} you must " _c
	di as err "specify also option {bf:{ul:go2}}"
	exit
}

if ("`graph'"=="go1" | "`graph'"=="go2") & `"`map'"'=="" {
	di as err "If you specify option {bf:{ul:gr}aph(`graph')} you must " _c
	di as err "specify also option {bf:{ul:map}({it:filename})}"
	exit
}

if "`graph'"=="moran" & "`WSTAN'"=="No" {
	di as err "Matrix `weights' is not row-standardized."
	di as err "If you specify option {bf:{ul:gr}aph(`graph')} you must use a"
	di as err "row-standardized weights matrix"
	exit
}

if `"`map'"'!="" & ("`xcoord'"=="" | "`ycoord'"=="") {
	di as err "If you specify option {bf:{ul:map}({it:filename})} you must " _c
	di as err "specify also options"
	di as err "{bf:{ul:x}coord({it:varname})} and " _c
	di as err "{bf:{ul:y}coord({it:varname})}"
	exit
}

if `"`map'"'!="" {
	confirm file `"`map'"'
}

if "`symbol'"!="" & "`symbol'"!="id" & "`symbol'"!="n" {
	di as err "Option {bf:{ul:sy}mbol({it:keyword})} accepts only one of the " _c
	di as err "following keywords:"
	di as err "{bf:id} {bf:n}"
	exit
}

if "`symbol'"=="id" & "`id'"=="" {
	di as err "If you specify option {bf:{ul:sy}mbol(id)} you must " _c
	di as err "specify also option {bf:{ul:id}({it:varname})}"
	exit
}

if "`sort'"!="" {
	local sort "yes"
}
else {
	local sort "no"
}




*  ----------------------------------------------------------------------------
*  4. Define basic quantities                                                  
*  ----------------------------------------------------------------------------

/* Weights matrix */
local W="`weights'"


/* p-value multiplier and label */
local MULT=("`twotail'"!="")+1
local PVL "*`MULT'-tail test"


/* Row labels */
if "`id'"=="" {
	local ID=1
}
if "`id'"!="" {
   local TEMP : type `id'
   local TEMP=substr("`TEMP'",1,3)
   if "`TEMP'"=="str" {
      local ID=2
   }
   else {
      local TEMP : value label `id'
      if "`TEMP'"!="" {
         local ID=3
      }
      else {
         local ID=4
      }
   }
}


/* Display labels */
if "`WTYPE'"=="SWMImpo" & "`WBINA'"=="Yes" {
	local LBLTYPE "Imported (binary)"
}
if "`WTYPE'"=="SWMImpo" & "`WBINA'"=="No" {
	local LBLTYPE "Imported (non-binary)"
}
if "`WTYPE'"=="SWMDist" & "`WBINA'"=="Yes" {
	local LBLTYPE "Distance-based (binary)"
	local LBLBAND "`LOWER' < d <= `UPPER'"
}
if "`WTYPE'"=="SWMDist" & "`WBINA'"=="No" {
	local LBLTYPE "Distance-based (inverse distance)"
	local LBLBAND "`LOWER' < d <= `UPPER'"
}


/* Z m2 b2 */
if "`moran'"!="" | "`geary'"!="" {

preserve
qui summ `varlist', mean
local MEAN=r(mean)
qui replace `varlist'=`varlist'-`MEAN'
tempvar Vm2 Vm4
qui generate `Vm2'=`varlist'^2
qui summ `Vm2', mean
local m2=r(mean)
qui generate `Vm4'=`varlist'^4
qui summ `Vm4', mean
local m4=r(mean)
local b2=`m4'/(`m2'^2)	
tempname Z
mkmat `varlist', matrix(`Z')
restore

}


/* Wi Wi2 */
tempname Wi Wi2
matrix `Wi'=J(`N',1,0)
matrix `Wi2'=J(`N',1,0)
local i=1
while `i'<=`N' {
	local wi=0
	local wi2=0
	local j=1
	while `j'<=`N' {
		local w=`W'[`i',`j']
		local wi=`wi'+`w'
		local wi2=`wi2'+`w'^2
		local j=`j'+1
	}
	matrix `Wi'[`i',1]=`wi'
	matrix `Wi2'[`i',1]=`wi2'
	local i=`i'+1
}




*  ----------------------------------------------------------------------------
*  5. Moran's Ii                                                               
*  ----------------------------------------------------------------------------

if "`moran'"!="" {


/* Define results matrix */
tempname MORAN
matrix `MORAN'=J(`N',5,0)
matrix colnames `MORAN'=stat mean sd z p-value

/* Start loop */
local i=1
while `i'<=`N' {
	local zi=`Z'[`i',1]
	local wi=`Wi'[`i',1]
	local wi2=`Wi2'[`i',1]
	local SUM=0
	local j=1
	while `j'<=`N' {
		local wj=`W'[`i',`j']
		local zj=`Z'[`j',1]
		local SUM=`SUM'+`wj'*`zj'
		local j=`j'+1
	}

	/* stat */
	local stat=(`zi'/`m2')*`SUM'
	matrix `MORAN'[`i',1]=`stat'

	/* E(stat) */
	local E=(-`wi')/(`N'-1)
	matrix `MORAN'[`i',2]=`E'

	/* sd(stat) */
	local T1=(`wi2'*(`N'-`b2')) / (`N'-1)
	local T2=((`wi'^2-`wi2')*(2*`b2'-`N')) / ((`N'-1)*(`N'-2))
	local T3=((-`wi')/(`N'-1))^2
	local sd=`T1'+`T2'-`T3'
	local sd=sqrt(`sd')
	matrix `MORAN'[`i',3]=`sd'

	/* z */
	local z=(`stat'-`E')/`sd'
	matrix `MORAN'[`i',4]=`z'
	
	/* p-value */
   local pval=(1-normprob(abs(`z')))*`MULT'
	matrix `MORAN'[`i',5]=`pval'

	/* End loop */
	local i=`i'+1
}


}




*  ----------------------------------------------------------------------------
*  6. Geary's ci                                                               
*  ----------------------------------------------------------------------------

if "`geary'"!="" {


/* Define results matrix */
tempname GEARY
matrix `GEARY'=J(`N',5,0)
matrix colnames `GEARY'=stat mean sd z p-value

/* Start loop */
local i=1
while `i'<=`N' {
	local zi=`Z'[`i',1]
	local wi=`Wi'[`i',1]
	local wi2=`Wi2'[`i',1]
	local SUM=0
	local j=1
	while `j'<=`N' {
		local wj=`W'[`i',`j']
		local zj=`Z'[`j',1]
		local SUM=`SUM'+`wj'*((`zi'-`zj')^2)
		local j=`j'+1
	}

	/* stat */
	local stat=(1/`m2')*`SUM'
	matrix `GEARY'[`i',1]=`stat'

	/* E(stat) */
	local E=(2*`N'*`wi')/(`N'-1)
	matrix `GEARY'[`i',2]=`E'

	/* sd(stat) */
	local T1=`N'/(`N'-1)
	local T2=(`wi'^2+`wi2')*(3+`b2')
	local T3=((2*`N'*`wi')/(`N'-1))^2
	local sd=`T1'*`T2'-`T3'
	local sd=sqrt(`sd')
	matrix `GEARY'[`i',3]=`sd'

	/* z */
	local z=(`stat'-`E')/`sd'
	matrix `GEARY'[`i',4]=`z'
	
	/* p-value */
   local pval=(1-normprob(abs(`z')))*`MULT'
	matrix `GEARY'[`i',5]=`pval'

	/* End loop */
	local i=`i'+1
}


}




*  ----------------------------------------------------------------------------
*  7. Getis and Ord's G1i                                                      
*  ----------------------------------------------------------------------------

if "`go1'"!="" {


/* Define results matrix */
tempname GO1
matrix `GO1'=J(`N',5,0)
matrix colnames `GO1'=stat mean sd z p-value

/* Define X matrix */
tempname X
mkmat `varlist', matrix(`X')

/* Start loop */
local i=1
while `i'<=`N' {
   qui summ `varlist' if _n!=`i'
   local MEANXi=r(mean)
   local VARXi=(r(Var)*(`N'-2))/(`N'-1)
	local wi=`Wi'[`i',1]
	local NUM=0
   local DEN=0
	local j=1
	while `j'<=`N' {
		if `i'!=`j' {
			local wj=`W'[`i',`j']
		   local xj=`X'[`j',1]
		   local NUM=`NUM'+`wj'*`xj'
		   local DEN=`DEN'+`xj'
		}
		local j=`j'+1
	}

	/* stat */
	local stat=`NUM'/`DEN'
	matrix `GO1'[`i',1]=`stat'

	/* E(stat) */
	local E=`wi'/(`N'-1)
	matrix `GO1'[`i',2]=`E'

	/* sd(stat) */
	local T1=`wi'*(`N'-1-`wi')*`VARXi'
	local T2=((`N'-1)^2)*(`N'-2)*(`MEANXi'^2)
	local sd=`T1'/`T2'
	local sd=sqrt(`sd')
	matrix `GO1'[`i',3]=`sd'

	/* z */
	local z=(`stat'-`E')/`sd'
	matrix `GO1'[`i',4]=`z'
	
	/* p-value */
   local pval=(1-normprob(abs(`z')))*`MULT'
	matrix `GO1'[`i',5]=`pval'

	/* End loop */
	local i=`i'+1
}


}




*  ----------------------------------------------------------------------------
*  8. Getis and Ord's G2i                                                      
*  ----------------------------------------------------------------------------

if "`go2'"!="" {


/* Define results matrix */
tempname GO2
matrix `GO2'=J(`N',5,0)
matrix colnames `GO2'=stat mean sd z p-value

/* Define X matrix */
tempname X
mkmat `varlist', matrix(`X')

/* Define Wi */
tempname Wi WW
matrix `Wi'=J(`N',1,0)
matrix `WW'=`W'
local i=1
while `i'<=`N' {
	local wi=0
	local j=1
	while `j'<=`N' {
		if `i'==`j' {
			matrix `WW'[`i',`j']=1
		}
		local w=`WW'[`i',`j']
		local wi=`wi'+`w'
		local j=`j'+1
	}
	matrix `Wi'[`i',1]=`wi'
	local i=`i'+1
}

/* Start loop */
local i=1
while `i'<=`N' {
   qui summ `varlist',
   local MEANXi=r(mean)
   local VARXi=(r(Var)*(`N'-1))/`N'
	local wi=`Wi'[`i',1]
	local NUM=0
   local DEN=0
	local j=1
	while `j'<=`N' {
		local wj=`WW'[`i',`j']
	   local xj=`X'[`j',1]
	   local NUM=`NUM'+`wj'*`xj'
	   local DEN=`DEN'+`xj'
		local j=`j'+1
	}

	/* stat */
	local stat=`NUM'/`DEN'
	matrix `GO2'[`i',1]=`stat'

	/* E(stat) */
	local E=`wi'/`N'
	matrix `GO2'[`i',2]=`E'

	/* sd(stat) */
	local T1=`wi'*(`N'-`wi')*`VARXi'
	local T2=(`N'^2)*(`N'-1)*(`MEANXi'^2)
	local sd=`T1'/`T2'
	local sd=sqrt(`sd')
	matrix `GO2'[`i',3]=`sd'

	/* z */
	local z=(`stat'-`E')/`sd'
	matrix `GO2'[`i',4]=`z'
	
	/* p-value */
   local pval=(1-normprob(abs(`z')))*`MULT'
	matrix `GO2'[`i',5]=`pval'

	/* End loop */
	local i=`i'+1
}


}




*  ----------------------------------------------------------------------------
*  9. Display results                                                          
*  ----------------------------------------------------------------------------

di _newline
di as txt "{title:Measures of local spatial autocorrelation}"

di _newline
di as txt "Weights matrix"
di as txt "{hline 62}"
di as txt "Name: " as res "`W'"
di as txt "Type: " as res "`LBLTYPE'"
if "`WTYPE'"=="SWMDist" {
	di as txt "Distance band: " as res "`LBLBAND'"
}
di as txt "Row-standardized: " as res "`WSTAN'"
di as txt "{hline 62}"

if "`moran'"!="" {
	di ""
	_disp "`varlist'" "`MORAN'" "Moran's Ii" "Ii" "`N'" "`ID'"   /*
	*/    "`sort'" "`id'"
}

if "`geary'"!="" {
	di ""
	_disp "`varlist'" "`GEARY'" "Geary's ci" "ci" "`N'" "`ID'"   /*
	*/    "`sort'" "`id'"
}

if "`go1'"!="" {
	di ""
	_disp "`varlist'" "`GO1'" "Getis & Ord's G1i" "G1i" "`N'" "`ID'"   /*
	*/    "`sort'" "`id'"
}

if "`go2'"!="" {
	di ""
	_disp "`varlist'" "`GO2'" "Getis & Ord's G2i" "G2i" "`N'" "`ID'"   /*
	*/    "`sort'" "`id'"
}

di as txt "`PVL'"
di _newline




*  ----------------------------------------------------------------------------
*  10. Moran scatterplot                                                       
*  ----------------------------------------------------------------------------

if "`graph'"=="moran" {
	

/* Preserve data */
preserve

/* Create y and Wy */
tempvar Y
qui egen `Y'=std(`varlist')
tempname y Wy
mkmat `Y', matrix(`y')
matrix `Wy'=`W'*`y'
svmat `Wy', n(_Wy)
qui summ _Wy1, mean
local YL=r(mean)

/* Extract variable label */
local VARLBL : variable label `varlist'
if "`VARLBL'"!="" {
   local VARLBL=substr("`VARLBL'",1,78)
}
else {
   local VARLBL="`varlist'"
}

/* Make scatterplot */
if `"`map'"'=="" {

	qui regress _Wy1 `Y'
	tempvar YHAT
   qui predict `YHAT'
   local I=string(_b[`Y'],"%5.3f")
   
   qui summ _Wy1, mean
   local ymin=int(r(min))-1
   local ymax=int(r(max))+1
   qui summ `Y', mean
   local xmin=int(r(min))-1
   local xmax=int(r(max))+1
   
   if "`symbol'"=="" {
   	local SY "O"
   }
   if "`symbol'"=="n" {
   	local SY "[_n]"
   }
   if "`symbol'"=="id" {
   	local SY "[`id']"
   	local TRIM "trim(6)"
   }

   graph _Wy1 `YHAT' `Y', sort c(.l) sy(`SY'.) border yline(`YL') xline(0)   /*
                     */   ylab(`ymin'(1)`ymax') xlab(`xmin'(1)`xmax')        /*
                     */   t1(Moran scatterplot (Moran's I = `I'))            /*
                     */   t2("`VARLBL'") b2(z) l2(Wz) `TRIM'
                     
   if "`savegraph'"!="" {
   	translate @Graph `savegraph'
   }

}

/* Map scatterplot */
if `"`map'"'!="" {
	
	tempvar TYPE
   qui generate `TYPE'=0
   qui replace `TYPE'=1 if `Y'>=0 & _Wy1>=`YL'
   qui replace `TYPE'=2 if `Y'<0 & _Wy1<`YL'
   qui replace `TYPE'=3 if `Y'>=0 & _Wy1<`YL'
   qui replace `TYPE'=5 if `Y'<0 & _Wy1>=`YL'

   tempname Q
   matrix `Q'=`MORAN'
   svmat `Q', n(_Q)
   tempvar Z SY
   qui generate `Z'=abs(_Q4)*150

   merge using `"`map'"'
   qui tab _ID
   local NPOLY=r(r)
   qui summ _Y, mean
   local ymin=r(min)
   local ymax=r(max)
   qui summ _X, mean
   local xmin=r(min)
   local xmax=r(max)
   local JY=(`ymax'-`ymin')*0.08
   local JX=(`xmax'-`xmin')*0.08
   local ymin=`ymin'-`JY'
   local ymax=`ymax'+`JY'
   local xmin=`xmin'-`JX'
   local xmax=`xmax'+`JX'
   local RATIO=(`ymax'-`ymin')/(`xmax'-`xmin')
   local YS=4
   local XS=4/`RATIO'
   format _Y _X %5.0f
   quietly {
	   gph open, ysize(`YS') xsize(`XS')
      graph _Y _X, s(i) ysize(`YS') xsize(`XS') yscale(`ymin',`ymax')   /*
              */   xscale(`xmin',`xmax') ylab(`ymin') xlab(`xmin')      /*
              */   noaxis l1(" ") t1("Moran scatterplot") b2("`VARLBL'")
      gph clear 15000 0 23063 5750 
      local ay=r(ay)
      local by=r(by)
      local ax=r(ax)
      local bx=r(bx)
      replace _Y=`ay'*_Y+`by'
      replace _X=`ax'*_X+`bx'
      replace `ycoord'=`ay'*`ycoord'+`by'
      replace `xcoord'=`ax'*`xcoord'+`bx'
  	   gph pen 1
      forvalues i=1/`NPOLY' {
   	   gph vline _Y _X if _ID==`i'
  	   }
  	   gph pen 2
      gph vpoint `ycoord' `xcoord' `Z' `TYPE'
      gph close
   }

   if "`savegraph'"!="" {
   	translate @Graph `savegraph'
   }

}

/* Restore data */
restore


}




*  ----------------------------------------------------------------------------
*  11. Plot Getis and Ord's G1i or G2i (z-values)                              
*  ----------------------------------------------------------------------------

if "`graph'"=="go1" | "`graph'"=="go2" {


local VARLBL : variable label `varlist'
if "`VARLBL'"!="" {
   local VARLBL=substr("`VARLBL'",1,78)
}
else {
   local VARLBL="`varlist'"
}
if "`graph'"=="go1" {
	local TITLE "Getis and Ord's G1i (z-values)"
	tempname Q
	matrix `Q'=`GO1'
}
if "`graph'"=="go2" {
	local TITLE "Getis and Ord's G2i (z-values)"
	tempname Q
	matrix `Q'=`GO2'
}
preserve
svmat `Q', n(_Q)
tempvar Z SY
qui generate `Z'=abs(_Q4)*150
qui generate `SY'=cond(_Q4>0,1,0)
qui replace `SY'=2 if _Q4<0
merge using `"`map'"'
qui egen _POLY=group(_ID)
qui tab _POLY
local NPOLY=r(r)
qui summ _Y, mean
local ymin=r(min)
local ymax=r(max)
qui summ _X, mean
local xmin=r(min)
local xmax=r(max)
local JY=(`ymax'-`ymin')*0.08
local JX=(`xmax'-`xmin')*0.08
local ymin=`ymin'-`JY'
local ymax=`ymax'+`JY'
local xmin=`xmin'-`JX'
local xmax=`xmax'+`JX'
local RATIO=(`ymax'-`ymin')/(`xmax'-`xmin')
local YS=4
local XS=4/`RATIO'
format _Y _X %5.0f
quietly {
	gph open, ysize(`YS') xsize(`XS')
   graph _Y _X, s(i) ysize(`YS') xsize(`XS') yscale(`ymin',`ymax')   /*
           */   xscale(`xmin',`xmax') ylab(`ymin') xlab(`xmin')      /*
           */   noaxis l1(" ") t1("`TITLE'") b2("`VARLBL'")
   gph clear 15000 0 23063 8000 
   local ay=r(ay)
   local by=r(by)
   local ax=r(ax)
   local bx=r(bx)
   replace _Y=`ay'*_Y+`by'
   replace _X=`ax'*_X+`bx'
   replace `ycoord'=`ay'*`ycoord'+`by'
   replace `xcoord'=`ax'*`xcoord'+`bx'
  	gph pen 1
   forvalues i=1/`NPOLY' {
   	gph vline _Y _X if _POLY==`i'
  	}
  	gph pen 2
   gph vpoint `ycoord' `xcoord' `Z' `SY'
   gph close
}
if "`savegraph'"!="" {
	 translate @Graph `savegraph'
}
restore


}




*  ----------------------------------------------------------------------------
*  12. Return results                                                          
*  ----------------------------------------------------------------------------

if "`moran'"!="" {
   return matrix Moran `MORAN'
}

if "`geary'"!="" {
   return matrix Geary `GEARY'
}

if "`go1'"!="" {
   return matrix GetisOrd1 `GO1'
}

if "`go2'"!="" {
   return matrix GetisOrd2 `GO2'
}




*  ----------------------------------------------------------------------------
*  13. End program                                                             
*  ----------------------------------------------------------------------------

end








*  ----------------------------------------------------------------------------
*  A1. Subprogram _disp                                                        
*  ----------------------------------------------------------------------------

program define _disp
version 7.0
args VAR MAT TITLE L N ID SORT id


preserve

if "`SORT'"=="yes" {
	if `ID'==1 {
		tempvar TEMP
		qui gen `TEMP'=_n
	}
   qui svmat `MAT', n(_M)
   qui sort _M4
   tempname STAT
   qui mkmat _M*, matrix(`STAT')
   drop _M*
}
if "`SORT'"=="no" {
   tempname STAT
   matrix `STAT'=`MAT'
}

if "`id'"!="" {
	local header=abbrev("`id'",19)
}
else {
	local header="Location"
}

local VARLBL : variable label `VAR'
if "`VARLBL'"!="" {
   local VARLBL=substr("`VARLBL'",1,42)
}
else {
   local VARLBL="`VAR'"
}

di as txt "`TITLE' (" as res "`VARLBL'" as txt ")"
di as txt "{hline 20}{c TT}{hline 41}"
di as txt _col(1) %19s "`header'" " {c |}" _col(26) "`L'"       /*
     */   _col(32) "E(`L')" _col(39) "sd(`L')" _col(50) "z"     /*
     */   _col(55) "p-value*"
di as txt "{hline 20}{c +}{hline 41}"

local i=1
while `i'<=`N' {
	if `ID'==1 {
		local ROW=`TEMP'[`i']
	}
	if `ID'==2 {
		local ROW=substr(`id'[`i'],1,18)
	}
	if `ID'==3 {
      local INDEX=`id'[`i']
      local ROW : label(`id') `INDEX' 19
	}
	if `ID'==4 {
      local ROW=`id'[`i']
	}
	di as txt _col(1) %19s "`ROW'" " {c |}"   /*
	*/ as res %7.3f `STAT'[`i',1]             /*
	*/ as res %8.3f `STAT'[`i',2]             /*
	*/ as res %8.3f `STAT'[`i',3]             /*
	*/ as res %8.3f `STAT'[`i',4]             /*
	*/ as res %8.3f `STAT'[`i',5]
	local i=`i'+1
}
di as txt "{hline 20}{c BT}{hline 41}"

restore


end



