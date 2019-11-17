*! Version 1.0 - 29 January 2001 STB-60 sg162
*! -spatwmat- Generates different kinds of spatial weights matrices            
*! Author: Maurizio Pisati                                                     
*! Department of Sociology and Social Research                                 
*! University of Milano Bicocca (Italy)                                        
*! maurizio.pisati@galactica.it                                                
*!                                                                             




*  ----------------------------------------------------------------------------
*  1. Define program                                                           
*  ----------------------------------------------------------------------------

program define spatwmat
version 7.0




*  ----------------------------------------------------------------------------
*  2. Define syntax                                                            
*  ----------------------------------------------------------------------------

syntax [using/], Name(string)                           /* 
          */     [DROP(numlist min=1 >=0 sort)]         /*
          */     [Xcoord(varname numeric)]              /*
          */     [Ycoord(varname numeric)]              /*
          */     [Band(numlist min=2 max=2 >=0 sort)]   /*
          */     [Friction(real 1)]                     /*
          */     [BINary]                               /*
          */     [Standardize]                          /*
          */     [Eigenval(string)]




*  ----------------------------------------------------------------------------
*  3. Check syntax                                                             
*  ----------------------------------------------------------------------------

confirm name `name'

if "`using'"=="" & ("`xcoord'"=="" | "`ycoord'"=="") {
	di as err "You must specify both x- and y-coordinates using options "
	di as err "{bf:{ul:x}coord({it:varname})} and " _c
	di as err "{bf:{ul:y}coord({it:varname})}"
	exit
}
if "`using'"=="" & "`band'"=="" {
	di as err "You must specify distance band using option " _c
	di as err "{bf:{ul:b}and({it:numlist})}"
	exit
}

local OUTPUT "The following matrix has been created:"




*  ----------------------------------------------------------------------------
*  4. Import weights matrix                                                    
*  ----------------------------------------------------------------------------

if "`using'"!="" {


   /* Read data file */
	preserve
   qui use `"`using'"', clear

   /* Drop rows and columns if requested */
	if "`drop'"!="" {
		local NDROP : word count `drop'
		unab VLIST : _all
		qui generate RDROP=0
		local i=1
		while `i'<=`NDROP' {
			local D : word `i' of `drop'
			local VAR : word `D' of `VLIST'
         local CDLIST "`CDLIST'`VAR' "
         qui replace RDROP=1 in `D'
			local i=`i'+1
		}
		qui drop `CDLIST'
		qui drop if RDROP
		qui drop RDROP
	}
	
	/* Check if weights are binary */
	unab VLIST : _all
	local NVAR : word count `VLIST'
	local SUM=0
	local i=1
	while `i'<=`NVAR' {
		local VAR : word `i' of `VLIST'
		qui capture assert `VAR'==0 | `VAR'==1
  	   if _rc!=0 {
		   local SUM=`SUM'+1
	   }
		local i=`i'+1
	}
	if `SUM'==0 {
		local binary "binary"
	}
	else {
		local binary ""
	}
	
	/* Check if each location has at least one neighbor */
	qui egen ROWSUM=rsum(_all)
	qui count if ROWSUM==0
	local NN=r(N)
	qui drop ROWSUM
	
	/* Create intermediate matrix _W */
   qui mkmat _all, matrix(_W)
   restore

   /* Check if matrix is square*/
   local NROW=rowsof(_W)
   local NCOL=colsof(_W)
   if `NROW'!=`NCOL' {
   	di as err "Matrix is not square"
   	exit
   }
   local N=`NROW'
   
   /* Create labels */
   if "`binary'"!="" {
   	local WT "Imported binary weights matrix"
   }
   else {
   	local WT "Imported non-binary weights matrix"
   }
   
   /* Create final matrix */
   matrix `name'=_W


}




*  ----------------------------------------------------------------------------
*  5. Create distance-based weights matrix                                     
*  ----------------------------------------------------------------------------

if `"`using'"'=="" {


   /* Define distance band */
	local LOWER : word 1 of `band'
	local UPPER : word 2 of `band'

   /* Check appropriateness of coordinate variables */
	capture qui assert `xcoord'!=.
   if _rc!=0 {
   	di as err "Variable `xcoord' has missing values"
   	exit
   }
	capture qui assert `ycoord'!=.
   if _rc!=0 {
   	di as err "Variable `ycoord' has missing values"
   	exit
   }
	local N=_N

   /* Create intermediate matrix */
	matrix _W=J(`N',`N',0)
	matrix _D=J(`N',`N',0)
	preserve
	local MAXOBS=(`N'/2)*(`N'-1)
	qui set obs `MAXOBS'
	tempvar DISTAN
	qui generate `DISTAN'=.
	local d=1
	local i=1
	while `i'<=`N' {
		local j=`i'+1
		while `j'<=`N' {
			local A=(`xcoord'[`i']-`xcoord'[`j'])^2
			local B=(`ycoord'[`i']-`ycoord'[`j'])^2
			local DIST=sqrt(`A'+`B')
			qui replace `DISTAN'=`DIST' in `d'
			matrix _D[`i',`j']=`DIST'
			matrix _D[`j',`i']=`DIST'
			if `DIST'>`LOWER' & `DIST'<=`UPPER' {
				if "`binary'"!="" {
					matrix _W[`i',`j']=1
					matrix _W[`j',`i']=1
				}
				else {
					matrix _W[`i',`j']=1/(`DIST'^`friction')
					matrix _W[`j',`i']=1/(`DIST'^`friction')
				}
			}
		   local d=`d'+1
		   local j=`j'+1
		}
	   local i=`i'+1
	}
	
	/* Generate distance statistics */
	qui summarize `DISTAN', detail
	local DMIN=r(min)
	local DP25=r(p25)
	local DP50=r(p50)
	local DP75=r(p75)
	local DMAX=r(max)
   qui svmat _D
   qui for varlist _D* : replace X=. if X==0
   qui egen ROWMIN=rmin(_D*)
   qui summ ROWMIN, mean
   local MAXMIN=r(max)
   qui egen ROWMAX=rmax(_D*)
   qui summ ROWMAX, mean
   local MINMAX=r(min)
   matrix drop _D
	restore

	/* Check if each location has at least one neighbor */
	preserve
	qui drop _all
   qui svmat _W
   qui egen ROWSUM=rsum(_W*)
	qui count if ROWSUM==0
	local NN=r(N)
   restore
	
   /* Create labels */
   if "`binary'"!="" {
   	local WT "Distance-based binary weights matrix"
   }
   else {
   	local WT "Inverse distance weights matrix"
   }
   
   /* Create final matrix */
   matrix `name'=_W


}




*  ----------------------------------------------------------------------------
*  6. Row-standardize weights matrix                                           
*  ----------------------------------------------------------------------------

if "`standardize'"!="" {
	preserve
	qui drop _all
   qui svmat _W
   qui egen ROWSUM=rsum(_W*)
   qui for varlist _W* : replace X=X/ROWSUM if ROWSUM!=0
   qui mkmat _W*, matrix(_WS)
   restore
   matrix `name'=_WS
}




*  ----------------------------------------------------------------------------
*  7. Create weights matrix eigenvalues                                        
*  ----------------------------------------------------------------------------

if "`eigenval'"!="" & `NN'>0 {
	di as err "Eigenvalues matrix cannot be computed because of the presence"
	di as err "of one or more locations with no neighbors"
}

if "`eigenval'"!="" & `NN'==0 {
   preserve
   qui drop _all
   qui svmat _W
   qui egen ROWSUM=rsum(_W*)
   qui replace ROWSUM=sqrt(1/ROWSUM)
   tempname D WW X
   qui mkmat ROWSUM, matrix(`D')
   matrix `D'=diag(`D')
   matrix `WW'=`D'*_W*`D'
   matrix symeigen `X' `eigenval'=`WW'
   matrix `eigenval'=`eigenval''
   restore
   local OUTPUT "The following matrices have been created:"
}




*  ----------------------------------------------------------------------------
*  8. Add relevant info to weights matrix                                      
*  ----------------------------------------------------------------------------

if "`using'"!="" & "`binary'"!="" {local ROW="SWMImpo Yes "}
if "`using'"!="" & "`binary'"=="" {local ROW="SWMImpo No "}
if "`using'"=="" & "`binary'"!="" {local ROW="SWMDist Yes "}
if "`using'"=="" & "`binary'"=="" {local ROW="SWMDist No "}
if "`standardize'"!="" {
	local ROW="`ROW'Yes"
}
else {
	local ROW="`ROW'No"
}
matrix rownames `name'=`ROW'

if "`using'"=="" {
   local INT=int(`LOWER')
   local DEC=`LOWER'-`INT'
   local DEC=string(`DEC')
   local COL "`INT' `DEC'"
   local INT=int(`UPPER')
   local DEC=`UPPER'-`INT'
   local DEC=string(`DEC')
   local COL "`COL' `INT' `DEC'"
   matrix colnames `name'=`COL'
}




*  ----------------------------------------------------------------------------
*  9. Display report                                                           
*  ----------------------------------------------------------------------------

if "`standardize'"!="" {
   local S "(row-standardized)"
}

di _newline
di as txt "`OUTPUT'"
di ""
di as txt "1. `WT' " as res "`name'" as txt " `S'"
di as txt "   Dimension: " as res "`N'x`N'"

if "`using'"=="" {
   di as txt "   Distance band: " as res "`LOWER' < d <= `UPPER'"
   di as txt "   Friction parameter: " as res "`friction'"
   di as txt "   Minimum distance: " %-9.1f as res `DMIN'
   di as txt "   1st quartile distance: " %-9.1f as res `DP25'
   di as txt "   Median distance: " %-9.1f as res `DP50'
   di as txt "   3rd quartile distance: " %-9.1f as res `DP75'
   di as txt "   Maximum distance: " %-9.1f as res `DMAX'
   di as txt "   Largest minimum distance: " %-9.2f as res `MAXMIN'
   di as txt "   Smallest maximum distance: " %-9.2f as res `MINMAX'
}

if `NN'==1 {
	di ""
	di as err "   Beware! `NN' location has no neighbors"
}
else if `NN'>1 {
	di ""
	di as err "   Beware! `NN' locations have no neighbors"
}
if `NN'>0 & "`using'"=="" {
	di as err "   You are advised to extend the distance band"  
}

if "`eigenval'"!="" & `NN'==0 {
   di ""
	di as txt "2. Eigenvalues matrix " as res "`eigenval'"
	di as txt "   Dimension: " as res "`N'x1"
}
di _newline




*  ----------------------------------------------------------------------------
*  10. End program                                                             
*  ----------------------------------------------------------------------------

capture matrix drop _W
capture matrix drop _WS
end



