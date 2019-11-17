program tsrtest, rclass
  version 9.2
// split in pre- and post-":" string
  capture _on_colon_parse `0'
  local cmd=`"`s(after)'"'
  local before=`"`s(before)'"'
  
  // syntax check on ":"
  if "`cmd'" == "" & "`before'" == "" {
    di in red "invalid syntax"
    exit 20
  }
  // syntax check on "bla:"
  if "`cmd'" == "" {
    di in red "test command not specified"
    exit 20
  }
  // syntax check on ":bla"
  if "`before'" == "" {
    di in red "grouping variable and test statistic not found"
    exit 20
  }  
  
  // syntax check for parts before ":"
  local 0 "`before'"
  syntax anything [if] [in] [using/] [,quiet ] [nodrop] [nodots] [reps(integer 10000)] [simsec(integer 1000)] [nullvalue(real 0)] [exact] [OVerwrite]
  tokenize "`anything'" 
  if "`1'" == "" | "`2'" == "" {
    di in red "Too few arguments before ':'"
    exit 20
  }
 
  // options related to "using"
  if "`using'"!="" {
		local usingf="`using'"
		local p = lower(substr("`using'",length("`using'")-3 ,4))
		if "`p'"!=".dta" {
			local usingf="`using'.dta"
		}
		if "`overwrite'"=="" {
	    confirm new file `usingf'
		}
  }

	if "`using'"!="" {
		tempfile usingfile
  } 
	else {
	  local usingfile=""
	}


// preserve data set
  preserve

// group variable
  local group `"`1'"'
  confirm numeric variable `group'

  // test statistic
  local stat `"`2'"'
  
// consider "if" and "in"
  marksample touse
  
  quietly {
    // sanity checks
    count if `touse'
    if r(N) == 0 error 2000
    local n = r(N)
    sum `group' if `touse'
    local group1 = r(min)
    local group2 = r(max)
    if `group1' == `group2' {
       di as err "1 group found, 2 required"
       exit 499
    }
    count if `touse' & `group'!=`group1' & `group'!=`group2'
    if r(N) > 1 {
      di as err "more than two groups found!"
      exit 499
    }
    
    // group sizes 
    count if `group' == `group1' & `touse'
    local n1 = r(N)
    count if `group' == `group2' & `touse'
    local n2 = r(N)

  }
  
   // number of combinations
  local minsize=min(`n1',`n2')
  local perms=comb(`n1'+`n2', `minsize')
  
  // which one is the smaller group?
  local smgroup = "`group1'"
  local othergroup= "`group2'"
  if `n1'>`n2' {
    local smgroup="`group2'"
    local othergroup= "`group1'"
  }
  local qt=1
  if "`quiet'"=="" {
    local qt=0
    di in gr "Two-sample randomization test for theta=" in ye "`stat'" _c
    di in gr " of " in ye "`cmd'" in gr " by " in ye "`group'" _n
    di in gr "Combinations:   " in ye "`perms'" in gr " = ("  _c
    di in ye "`n'" in gr " choose " _c
    di in ye "`minsize'" in gr ")"  in gr 
    if "`nullvalue'"=="0" {
      di in gr "Assuming null=0"
    }
  } 
  
  local dts=1
  if "`dots'"=="nodots" {
    local dts=0
  }

  local exct=0
  if "`exact'"=="exact" {
    local exct=1
  }
  local kp=0
  if "`drop'"=="nodrop" {
 
  } 
  else {
    // now, drop all observations that are not about to be used
 
    quietly keep if `touse'
  }
  
  mata: ///
  TwoSampleRandTest(`reps',`exct',`dts',`qt',`simsec',`nullvalue',"`group'","`stat'","`cmd'","`usingfile'",`group1',`group2',`n1',`n2',"`touse'")
  
  // did the MATA code terminate abnormally?
  local ec=r(combinations)
  if `ec'==. {
    exit 20
  }
  if "`quiet'"=="" {
  // output results
    di in gr 
    di in gr " p=" in ye %7.5f r(uppertail) _c
    di in gr " [one-tailed test of Ho:  theta(`group'==" _c
    di "`smgroup')<=theta(`group'==`othergroup')]"
    di in gr " p=" in ye %7.5f r(lowertail) _c
    di in gr " [one-tailed test of Ho:  theta(`group'==" _c
    di "`smgroup')>=theta(`group'==`othergroup')]"
    di in gr " p=" in ye %7.5f r(twotail) _c
    di in gr " [two-tailed test of Ho:  theta(`group'==" _c
    di "`smgroup')==theta(`group'==`othergroup')]"
    if r(missing)>0 {
      di in gr _n "Fraction of combinations with missing test statistics: " in ye %7.5f r(missing)
    }
  }
  local simul=r(simulated)
  
  if "`simul'"=="1" {
    return scalar repetitions = r(repetitions)
  }
  else  {
     return scalar repetitions = .
  }
	if "`using'"!="" {
		di _n in gr "Saving log file to `usingf'..." _c

		quietly {
			insheet theta using "`usingfile'" , clear
			save "`usingf'", replace
			restore
		}
		di "done."
	}
  // store results
  return scalar combinations = r(combinations)
  return scalar obsvStat = r(obsvStat)
  return scalar lowertail = r(lowertail)
  return scalar uppertail = r(uppertail)
  return scalar twotail = r(twotail)
  return scalar missing = r(missing)
  return scalar simulated = r(simulated)
  
  
end

// mata routine to do the actual test based on the
// algorithm by Jane F. Gentleman (1975): 
// Algorithm AS 88: Generation of All nCr Combinations
// by Simulating Nested Fortran DO Loops,
// Applied Statistics 24 (374-376)
// and on Monte Carlo simulations

mata:
void TwoSampleRandTest(
  real scalar reps,
  real scalar exact,
  real scalar dots,
  real scalar quiet,
  real scalar simsec,
  real scalar nullvalue,
  string scalar groupVar,
  string scalar testStat,
  string scalar cmd,
  string scalar csvfile,
  real scalar group1,
  real scalar group2,
  real scalar n1,
  real scalar n2,
  string scalar touse
)
{
  // variable declarations
  real matrix nul, groupvector
  
  real scalar kount, m, n, r, nmr, l, i, lower,equal, greater, err
  real scalar oldquota,quota,obstat,runningStat,total,missing
  real scalar smallergroup,greatergroup
  string scalar s
  
  real scalar simulate
   
  simulate=0
  // calculate total combinations and determine smaller group id
  total=comb(n1+n2,min((n1,n2)))
  smallergroup=( n1<n2 ? group1 : group2 )
  greatergroup=( n1<n2 ? group2 : group1 )

  // calculate critical value
  err=_stata(cmd,1)
  
  if (err!=0) {
    displayas("err")
    printf("{err:could not successfully execute '"+cmd+"', aborting}\n")
    exit(20)
  }
  obstat=st_numscalar(testStat)

  if (obstat==J(1,1,.)) {
    displayas("err")
    printf("{err:could not obtain test statistic from "+testStat+", aborting}\n")
    exit(20)
  }
  if (quiet==0) {
    displayas("text")
    printf("Observed theta: ")
    displayas("result")
    printf(strofreal(obstat,"%6.4g")+"\n")
  }
  groupvector=st_data(.,(groupVar),touse);

  // estimate time need
  estimate_base=200
  timer_clear(97);
  timer_on(97);
  for (i=1;i<=estimate_base;i++) {
   err=_stata(cmd,1)
  }
  timer_off(97)
  secs=timer_value(97)[1]/estimate_base;
  total_time=round(secs*total)
  e_sec=trunc(mod(total_time, 60))
  e_min=trunc(mod(total_time/60,60))
  e_hrs=trunc(total_time/3600)
  e_time=(e_sec<10?"0":"")+strofreal(e_sec)
  e_time=(e_min<10?"0":"")+strofreal(e_min)+":"+e_time
  e_time=strofreal(e_hrs)+":"+e_time
  
  displayas("text");
  printf("\nMinimum time needed for exact test (h:m:s): ");
  displayas("result");
  printf(" "+e_time+"\n");
  displayas("text");
  
  if (total_time>simsec & exact==0) {
    printf("Reverting to Monte Carlo simulation.\n");
    simulate=1
  }
  if (total_time>1e+18 & exact==1) {
    displayas("error");
    printf("\n!!!!!!!! THIS WILL TAKE LONGER THAN THE EXPECTED LIFETIME OF THE UNIVERSE!!!\n")
  }
  if (total_time>simsec & exact==1) {
    displayas("result");
    printf("\nWARNING: This will take *very* long! If this is not what you intended to do, hit");
    printf("\n         BREAK and repeat the command without specifying the 'exact' option!\n\n");
    displayas("text");
    simulate=0;
  }
   if (simulate==1 & quiet==0) {
    displayas("text")
    printf("Mode: simulation ("+strofreal(reps)+" repetitions)\n\n")
   }
   
   if (simulate==0 & quiet==0) {
    displayas("text")
     printf("Mode: exact\n\n")
   }
  // initialize counters
   lower=0
   equal=0
   greater=0
   quota=0
   oldquota=0
   missing=0
   eithertail=0
   absobstat=abs(obstat-nullvalue)
   n=n1+n2
   r=min((n1,n2))
   nmr=n-r
   kount=0
   
   log=(csvfile!="")
   if (log) {
    if (fileexists(csvfile)) 
      unlink(csvfile) 
    
    fh=fopen(csvfile, "w")
     fput(fh,strofreal(obstat))
    }
   displayas("text")
   if (dots==1) {
      printf("progress: |")
      displayflush()
  }
  if (simulate==1) {
     /////////////////////////////////
   // Simulation loop starts here //
   /////////////////////////////////
   for (kount=1;kount<=reps;kount++) {
      // generate random group vector j 
    // vector with size n+1
    j=e(1,n)'
    // fill vector j with numbers 1..n
    for (k=1;k<=n;k++) {
      j[k]=k;
    }
    _jumble(j)
     j = (j[1::n-nmr])
    // transpose j. Contains indices of observations
    // that will be set to be in the smaller group.
 
    //////////////////////
    // job starts here
    //////////////////////
    
    // display progress
    quota=(kount/reps)*40;
    if (floor(quota)>floor(oldquota) & dots==1) {
      printf(".")
      displayflush()
    }
    oldquota=quota  
    
    // set group vector
  
    groupvector=J(n1+n2,1,greatergroup)
    for (m=1;m<=rows(j);m++) {
      groupvector[j[m]]=smallergroup
    }
    st_store(.,(groupVar),touse,groupvector)
   
  // calculate test statistic and adjust counters
   err=_stata(cmd,1)
   if (err!=0) {
     displayas("err")
     printf("{err:could not successfully execute '"+cmd+"', aborting}\n")
      if (log) 
      {
        fclose(fh)
        } 
     exit(20)
    }
    runningStat=st_numscalar(testStat)
    if (runningStat != .) {
        if (abs(runningStat-nullvalue)>= absobstat)
          eithertail++
        if (runningStat==obstat)
           equal++
        else if (runningStat<obstat)
           lower++
        else if (runningStat>obstat)
          greater++
    } 
      if (log) 
      {
        fput(fh,strofreal(runningStat))
      }
    //////////////////////
    // job ends here
    //////////////////////
     
      
    // Simulation loop ends here
    
  }
  
  } else {
  //////////////// EXACT /////////////////////
  // Do Gentleman's AS88 algorithm
  
  i=1
  j=e(1,r)'
  do {
    if (i!=r) {
      for (l=i+1;l<=r;l++) {
        j[l]=j[l-1]+1
      }
    }
    kount++
  
    //////////////////////
    // job starts here
    //////////////////////
    
    // display progress
    quota=(kount/total)*40;
    if (floor(quota)>floor(oldquota) & dots==1) {
      printf(".")
      displayflush()
    }
    oldquota=quota  
    
    // set group vector
  
    groupvector=J(n1+n2,1,greatergroup)
    for (m=1;m<=rows(j);m++) {
      groupvector[j[m]]=smallergroup
    }
    st_store(.,(groupVar),touse,groupvector)
   
  // calculate test statistic and adjust counters
   err=_stata(cmd,1)
   if (err!=0) {
     displayas("err")
     printf("{err:could not successfully execute '"+cmd+"', aborting}\n")
      if (log) 
      {
        fclose(fh)
        } 
     exit(20)
    }
    runningStat=st_numscalar(testStat)
    if (runningStat != .) {
        if (abs(runningStat-nullvalue)>= absobstat)
          eithertail++
        if (runningStat==obstat)
           equal++
        else if (runningStat<obstat)
           lower++
        else if (runningStat>obstat)
          greater++
    } 
      if (log) 
      {
        fput(fh,strofreal(runningStat))
      }
    //////////////////////
    // job ends here
    //////////////////////
     
      
    // Gentleman's algorithm continues here
    
    i=r;
    while(i>0 && j[i]>=nmr+i) {
      i--
      if (i==0)
        break
    }
    if (i>0) {
        j[i]=j[i]+1
    }
  } while(i>0)
  }
  
  if (log) 
  {
    fclose(fh)
  } 
  if (dots==1)
    printf("|\n")
  displayflush()
  st_numscalar("r(combinations)", total)
  st_numscalar("r(obsvStat)",obstat)
  st_numscalar("r(missing)", missing/kount)
  st_numscalar("r(lowertail)",(lower+equal)/kount)
  st_numscalar("r(uppertail)",(greater+equal)/kount)
  st_numscalar("r(twotail)",(eithertail/kount))
  st_numscalar("r(simulated)",simulate)
  st_numscalar("r(repetitions)",reps)
}
end
