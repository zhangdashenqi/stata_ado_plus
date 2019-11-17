program permtest1, rclass byable(recall)
    version 9.0
	  syntax varname [=/exp] [if] [in] [, runs(integer -1) exact simulate ]
		marksample touse
    markout `touse' `by'
		local x "`varlist'"
		tempvar diff
		local simcount=`runs'
		
		quietly gen double `diff' = `x'-(`exp') if `touse'
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
		
	  if `mode'==0  {
		 if `samplesize' >13 {
		   local mode=2
		 } 
		 else {
		   local mode=1
		 }
		}
		if `simcount'<0 {
		  local simcount=200000
		}
		quietly sum `diff' if `touse', meanonly
		local obs=`r(N)'
		local sumobs=`r(mean)'*`r(N)'
		quietly sum  `diff' if `touse' & `diff'>0, meanonly
		local positive=`r(N)'
		quietly sum `diff' if `touse' & `diff'<0, meanonly
		local negative=`r(N)'
		quietly sum `diff' if `touse' & `diff'==0, meanonly
		local zer0=`r(N)'
		tempname sample mresult 
		mkmat `diff' if `touse', matrix(sample)
		di in green "Fisher-Pitman permutation test for paired replicates"
		di _n
    di in smcl in gr " difference vector {c |} `x'-`exp'"
		di in smcl in gr "{hline 19}{c +}{hline 33}"
		di in smcl in gr " observations      {c |}" in ye " `obs'"
		di in smcl in gr "  - positive       {c |}" in ye " `positive'"
		di in smcl in gr "  - negative       {c |}" in ye " `negative'"
		di in smcl in gr "  - zero           {c |}" in ye " `zer0'"
		di in smcl in gr "{hline 19}{c +}{hline 33}"
    di in smcl in gr "  critical value   {c |}" in ye " `sumobs'"
		di _n
		di in gr "mode of operation:  " _c
		if `mode'==1 {
		  di in ye "exact (complete permutation)" _n
		} 
		else {
			di in ye "Montecarlo simulation (`simcount' runs)" _n
		}
    local matrix mresult=(.)
    mata: permtestRelated(`mode',`simcount')
		di in green "Test of hypothesis Ho: " "`x'" ">=" "`exp'" " : p = " in yellow el(mresult,1,1)
		di in green "Test of hypothesis Ho: " "`x'" "<=" "`exp'" " : p = " in yellow el(mresult,2,1)
		di in green "Test of hypothesis Ho: " "`x'" "==" "`exp'" " : p = " in yellow el(mresult,3,1)
    return scalar lowertail = el(mresult,1,1)
    return scalar uppertail = el(mresult,2,1)
    return scalar twotail = el(mresult,3,1)
    return scalar N = `samplesize'
    return scalar mode = el(mresult,4,1)
    return scalar runs = el(mresult,5,1)
	  return scalar positive = `positive'
		return scalar negative = `negative'
    return scalar zero     = `zer0'
    return scalar criticalValue = `sumobs' 
end	

mata:
  version 9.0
  void permtestRelated(real scalar mode, real scalar simct) {
		smp=st_matrix("sample")
		
    /* generate sign vector */
		for (i=1;i<=rows(smp);i++) {
		   if (smp[i,1]>0) {
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
	 z=abs(smp)
	 threshold=sum(sign:*z)
	 
   /* do permutations */

   if (mode==2) {
    step=round(simct/40);
    printf("{text}Progress:  {c |}{result}")
	 	for (j=1;j<=simct;j++) {
			 if (mode==2) {
				 if (mod(j,step)==0) {
					 printf(".");
					 displayflush()
				 }
			 }
			 p=genVec(rows(sign)) 
			 val=sum(p:*z)
			 total++
			 if (val<=threshold) lower++
			 if (val>=threshold) higher++
		 }
     printf("{text}|\n\n")
  	 displayflush()
	 } else	 
	 {	
	   simct=1;
     signmatrix=genPermutationSignMatrix(rows(sign));
	   for (i=1;i<=cols(signmatrix);i++) {
		 	 p=signmatrix[.,i];
  		 val=sum(p:*z)
       total++
  		 if (val<=threshold) lower++
  		 if (val>=threshold) higher++
  	 }
	 }
	 lt=(lower)/total
	 ut=(higher)/total
	 tt=min((0.5,ut,lt))*2
	 result=(lt\ut\tt\mode\simct)
	 st_matrix("mresult",result)
	}
	
	function genVec(size) {
	  v=(.)
    for (i=1;i<=size;i++) {
			k=uniform(1,1)[1,1]
			if (k<=0.5) {
				k=-1
			}	else {
			  k=1
			}
			if (v==(.)) {
				v=k;
			} else {
				v=(v\k);
			}
		}
		return(v)
	}
	
	real matrix genPermutationSignMatrix(size) {
		// create init vector
		iv=(.)
		for (i=1;i<=size;i++) {
			if (iv==(.)) {
			  iv=-1
			} else
			{
				iv=(iv\-1)
			}
		}
		//create final vector
		fv=(.)
    for (i=1;i<=size;i++) {
      if (fv==(.)) {
        fv=1
      } else
      {
        fv=(fv\1)
      }
    }
		// initialise matrix
		m=iv;
		av=iv;
		while (av!=fv) {
			if (av[1]==-1) {
				av[1]=1;
			} else {
				av[1]=-1;
				for (i=2;i<=size;i++) {
					if (av[i]==-1) {
						av[i]=1
						break;
					}
					av[i]=-1
				}
			}
			m=(m,av)
		}
	  return(m)
	}
	
end	

