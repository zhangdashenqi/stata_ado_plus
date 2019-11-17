*! Author:
*! Lian Yujun, Sun Yat-sen University (2013-10-05)


capture program drop mediantab
program define mediantab, rclass
version 12.0
syntax varlist(min=1) [if] [in], by(varname) [Format(string) Moption]
 
 
*----------Arlion new added --------begin--------------
    if `"`format'"' != "" {
       capt local tmp : display `format' 1
       if _rc {
          di as err `"invalid %fmt in format(): `format'"'
          exit 120
       }
	   else{  // the suitable display format is %8.#f
	      tokenize "`format'", p(".")    
		  local 1 "%8"
		  local format `1'`2'`3'
	   }
    }
	else{
	   local format %8.3f
	}	
*----------Arlion new added --------over-------------- 
		
		
  tokenize `varlist'
  local k : word count `varlist'
	forval i=1(1)`k' {
	  confirm numeric variable ``i''
	}
	  
  qui tab `by' `if' `in'
  if r(r) ~=2 {
	 di in y "`by'" in r " can not contain more than two groups"
     exit 198
  }
	      
  tempname mat mttable 
  qui tabstat `varlist' `if' `in', s(N p50) by(`by') save
  mat `mttable' =  r(Stat1)', r(Stat2)', J(`k',2,0)
  local Group1_name = r(name1)
  local Group2_name = r(name2)
  forval i = 1(1) `k' {
    qui median ``i'' `if' `in', by(`by') `moption'
	mat `mttable'[`i',5] = r(chi2)
	  if r(p)<=.1 {
	     mat `mttable'[`i',6]= 1
	  }
	  if r(p)<=.05 {
	     mat `mttable'[`i',6]= 2
	  } 
	  if r(p)<=.01 {
	     mat `mttable'[`i',6]= 3
	  } 
  }
	
		 local star0= ""
		 local star1= "*"
		 local star2= "**"
		 local star3= "***"

	  di in smcl in gr _n "{hline 74}"
	  disp "Variables" in smcl _c
	  dis  _col(13) "G1(" abbrev("`Group1_name'",8) ")"  _col(25) _c "  Median1" _c
	  dis  _col(40) "G2(" abbrev("`Group2_name'",8) ")"  _col(50) _c "  Median2" _c
	  dis  _col(64) "  Chi2" 
	  di in smcl in gr  "{hline 74}"	  
	  
    forval i = 1(1)`k' {
      disp in g abbrev(`"``i''"',10) _c 
	  disp _col(15) in y scalar(`mttable'[`i', 1]) _c
	  disp _col(25) in y `format' scalar(`mttable'[`i', 2]) _c
	  disp _col(42) in y scalar(`mttable'[`i', 3]) _c
	  disp _col(50) in y `format' scalar(`mttable'[`i', 4]) _c
	  disp _col(62) in y `format' scalar(`mttable'[`i', 5]) _c
	  local star = scalar(`mttable'[`i', 6])
	  disp in g "`star`star''" 
	}
	
	di in smcl in gr  "{hline 74}"

    
end
