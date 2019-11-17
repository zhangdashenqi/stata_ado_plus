program permtest2, rclass byable(recall)
    version 9.0
	  syntax varname [if] [in], BY(varname) [runs(integer -1) exact simulate]
		marksample touse
    markout `touse' `by'
		local x "`varlist'"

		local simcount=`runs'
		local mode=0					
		if "`exact'" != "" & "`simulate'" != "" {
		  di in red "You are not allowed to specify both exact and simulate!"
			exit 499
		}
		if "`exact'" != "" {
			if `simcount' != -1 {
				di in red "You are not allowed to specify both runs() and exact!"
				exit 499
			}
			local mode=1
		}
		if "`simulate'" != "" {
		  local mode=2
		}

		quietly {
      summarize `by' if `touse', meanonly
      if r(N) == 0 { 
				di in red `"No group found, 2 required"'
			  exit 499
			}
      if r(min) == r(max) {
        di in red `"1 group found, 2 required"'
        exit 499
      }
    
		  local g1 = r(min)
      local g2 = r(max)

      count if `by'!=`g1' & `by'!=`g2' & `touse'
      if r(N) != 0 {
        di in red `"more than 2 groups found, only 2 allowed"'
        exit 499
      }
		}
		quietly count if `touse'
		local samplesize = `r(N)'
	  if `samplesize'	>  `c(matsize)' {
		  if `samplesize' > `c(max_matsize)' {
			  di in red "Your version of stata allows a maximum matrix size of"
				di in red `c(max_matsize)' ", whereas you need at least a matrix"
				di in red "size of " `samplesize' " to perform the requested operation."
				exit 499
			}
			set matsize `samplesize'
		}
    quietly sum `x' if `touse' & `by'==`g1'
    local n1=r(N)
    local m1=r(mean)
    local s1=r(sd)
    quietly sum `x' if `touse' & `by'==`g2'
    local n2=r(N)
    local m2=r(mean)
    local s2=r(sd)
    quietly sum `x' if `touse' 
    local nc=r(N)
    local mc=r(mean)
    local sc=r(sd)

    if `mode'==0  {
     if `nc' >15{
       local mode=2
     }
     else {
       local mode=1
     }
    }
		di in green "Fisher-Pitman permutation test for two independent samples"
		di _n
		di in smcl in gr %12s abbrev(`"`by'"',12)  " {c |}      obs        mean    std.dev."
    di in smcl in gr "{hline 13}{c +}{hline 33}"
		#delimit;
    di in smcl in gr %12s `"`g1'"' " {c |}" in ye
                _col(17) %7.0g `n1'
                _col(26) %10.0g `m1'
                _col(38) %10.0g `s1' ;
    di in smcl in gr %12s `"`g2'"' " {c |}" in ye
                _col(17) %7.0g `n2'
                _col(26) %10.0g `m2'
                _col(38) %10.0g `s2' ;
    di in smcl in gr "{hline 13}{c +}{hline 33}";
    di in smcl in gr %12s "combined" " {c |}" in ye
                _col(17) %7.0g `nc'
                _col(26) %10.0g `mc'
                _col(38) %10.0g `sc' ;
	  #delimit cr
		di _n
		if `simcount'<0 {
			local simcount=200000
		}
    di in gr "mode of operation:  " _c
    if `mode'==1 {
      di in ye "exact (complete permutation)" _n
    }
    else {
      di in ye "Montecarlo simulation (`simcount' runs)" _n
    }

    tempname sample mresult
    mkmat `by' `x' if `touse', matrix(sample)
    local matrix mresult=(.)
    mata: permtestIndependent(`g1',`g2',`mode',`simcount')
    #delimit ;
		di in green "Test of hypothesis Ho: " "`x'" "(" "`by'" "==" `g1' ") >= " 
             "`x'" "(" "`by'" "==" `g2' ") :  p="  in yellow el(mresult,1,1) in green " (one-tailed)";
		di in green "Test of hypothesis Ho: " "`x'" "(" "`by'" "==" `g1' ") <= "
             "`x'" "(" "`by'" "==" `g2' ") :  p="  in yellow el(mresult,2,1) in green " (one-tailed)";
		di in green "Test of hypothesis Ho: " "`x'" "(" "`by'" "==" `g1' ") == " 
						 "`x'" "(" "`by'" "==" `g2' ") :  p="  in yellow el(mresult,3,1) in green " (two-tailed)";
    #delimit cr

		return scalar lowertail = el(mresult,1,1)	
		return scalar uppertail = el(mresult,2,1)
		return scalar twotail = el(mresult,3,1)
		return scalar n1 = `n1'
		return scalar n2 = `n2'
		return scalar criticalValue = el(mresult,6,1)
		return scalar N = `samplesize'
    return scalar mode = el(mresult,4,1)
	  return scalar runs = el(mresult,5,1) 
end	

mata:
  version 9.0
  void permtestIndependent(g1,g2,real scalar mode, real scalar simct) {
		smp=st_matrix("sample")
		smp_string=st_matrixcolstripe("sample")

    /* generate sign vector */
		for (i=1;i<=rows(smp);i++) {
		   if (smp[i,1]==g1) {
					if (i==1) {
					  sign=1
					} else {
  			    sign=(sign\1)
					}	
			 } else
			 {
			   if (i==1) {
				    sign=-1
				  } else
				 	{
			      sign=(sign\-1)
					}
			 }
		}
	 /* initialize values */
	 lower=0
	 higher=0
	 total=0
	 threshold=sum(sign:*smp[.,2])
   /* do permutations */
	 m=(.)
	 if (mode==1) {
		 m=genPermutationMatrixInd(sign)
		 simct=1
     for (i=1;i<=cols(m);i++) {
       val=sum(m[.,i]:*smp[.,2])
       total++
       if (val<=threshold) lower++
       if (val>=threshold) higher++
     }
 
	 } else {
     step=round(simct/40);
     printf("{text}Progress:  {c |}{result}")
		 ts=sign;
	 	 for (j=1;j<=simct;j++) {
	    	if (mod(j,step)==0) {
					displayflush()
					printf(".")
				}
				_jumble(ts);
				val=sum(ts:*smp[.,2])
		    total++
				if (val<=threshold) lower++
				if (val>=threshold) higher++
	   }
	   printf("{text}|\n\n")
	 }
	 lt=(lower)/total
	 ut=(higher)/total
	 tt=min((0.5,ut,lt))*2

	 result=(lt\ut\tt\mode\simct\threshold)
	 st_matrix("mresult",result)
	}

	function genPermutationMatrixInd(sign) {
	  m=(.)
		perminfo=cvpermutesetup(sign)
		while ((p=cvpermute(perminfo)) != J(0,1,.)) {
			if ( m==(.)) {
				m=p
			} else {
			  m=(m,p)
			}
		}
		return(m);
	}
	
end
