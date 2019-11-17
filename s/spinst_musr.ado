*! version 1.0.0  15feb2009
program spinst_musr
  version 10.1

  di as smcl "{txt}Installing ..."

  cap noi spinst_musr_wrk sjlatex http://www.stata-journal.com/production
  cap noi spinst_musr_wrk estout http://fmwww.bc.edu/RePEc/bocode/e
  cap noi spinst_musr_wrk st0033_2 http://www.stata-journal.com/software/sj6-3
  cap noi spinst_musr_wrk st0108 http://www.stata-journal.com/software/sj6-3
  cap noi spinst_musr_wrk ivreg2 http://fmwww.bc.edu/RePEc/bocode/i
  cap noi spinst_musr_wrk ranktest http://fmwww.bc.edu/RePEc/bocode/r
  cap noi spinst_musr_wrk gr42_4 http://www.stata-journal.com/software/sj6-4
  cap noi spinst_musr_wrk grqreg http://fmwww.bc.edu/RePEc/bocode/g
  cap noi spinst_musr_wrk qcount http://fmwww.bc.edu/RePEc/bocode/q
  cap noi spinst_musr_wrk xtscc http://fmwww.bc.edu/RePEc/bocode/x
  cap noi spinst_musr_wrk spost9_ado http://www.indiana.edu/~jslsoc/stata
  cap noi spinst_musr_wrk mixlogit http://fmwww.bc.edu/RePEc/bocode/m
  cap noi spinst_musr_wrk tobcm http://www.stata.com/users/ddrukker
  cap noi spinst_musr_wrk hnblogit http://fmwww.bc.edu/RePEc/bocode/h
  cap noi spinst_musr_wrk fmm http://fmwww.bc.edu/RePEc/bocode/f
  cap noi spinst_musr_wrk xtpqml http://fmwww.bc.edu/RePEc/bocode/x

  if "`haserr'" != "" {
    di
    di in smcl "{p}{err}At least one of the packages was not able to be " ///
               "installed.  Try typing {cmd:spinst_musr} again.  If that " ///
               "fails, look at the output of the error message above to " ///
               "diagnose the problem.  Perhaps you have an out-of-date " ///
               "version of the package already installed.  In that case, " ///
               "type {cmd:adoupdate} to update it."
  }
  else {
   di as smcl "{txt}Installation complete."
  }
end

program spinst_musr_wrk
  version 10.1
  args package from

  di as smcl "{txt}   package {res:`package'} from {res:`from'}"
  capture net install `package', from(`from')
  if _rc {
    di
    di as smcl "{cmd}. net install `package', from(`from')
    capture noisily net install `package', from(`from')
    di
    if _rc {
      c_local haserr "yes"
    }
  }
end

