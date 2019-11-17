program oheckman_lf
  version 9.2
  syntax varlist(min=2)

  quietly {
    local J = $OHECKMAN_NEQ - 1
    local Jminus1 = `J' - 1

    ********** Parse arguments **********

    gettoken lnf varlist : varlist
    gettoken xbs varlist : varlist

    forvalues i = 0/`J' {
      if real(substr("$OHECKMAN_HASY",`i'+1,1)) {
        gettoken xb`i' varlist : varlist
      }
    }

    gettoken cutoff1 varlist : varlist
    forvalues i = 2/`J' {
      local j = `i'-1
      tempname cutoff`i'
      gettoken lndelta`i' varlist : varlist
      scalar `cutoff`i'' = `cutoff`j'' + exp(`lndelta`i'')
    }

    forvalues i = 0/`J' {
      tempname rho`i'
      if real(substr("$OHECKMAN_HASY",`i'+1,1)) {
        gettoken athrho`i' varlist : varlist
        scalar `rho`i'' = tanh(`athrho`i'')
      }
      else {
        scalar `rho`i'' = 0
      }
    }

    forvalues i = 0/`J' {
      if real(substr("$OHECKMAN_HASY",`i'+1,1)) {
        tempname sigma`i'
        gettoken lnsigma`i' varlist : varlist
        scalar `sigma`i'' = exp(`lnsigma`i'')
      }
    }

    ********** Compute log likelihood **********
    replace `lnf' = 0
    tempvar numer
    gen double `numer' = .
    forvalues i = 0/`J' {
      if real(substr("$OHECKMAN_HASY",`i'+1,1)) {
        replace `lnf' = ln(normden(($ML_y2 - `xb`i'') / `sigma`i'')) - ln(`sigma`i'') if $ML_y1 == `i'
        replace `numer' = `xbs' + `rho`i'' * ($ML_y2 - `xb`i'') / `sigma`i'' if $ML_y1 == `i'
      }
      else {
        replace `numer' = `xbs' if $ML_y1 == `i'
      }
    }

    replace `lnf' = `lnf' + ln(norm((`cutoff1' - `numer') / sqrt(1 - `rho0'^2))) if $ML_y1 == 0
    forvalues i = 1/`Jminus1' {
      local j = `i'+1
      replace `lnf' = `lnf' ///
                    + ln(norm((`numer' - `cutoff`i'') / sqrt(1 - `rho`i''^2)) ///
                       - norm((`numer' - `cutoff`j'') / sqrt(1 - `rho`i''^2))) ///
        if ($ML_y1 == `i') & (`numer' - `cutoff`i'' < 0)
      replace `lnf' = `lnf' ///
                    + ln(norm((`cutoff`j'' - `numer') / sqrt(1 - `rho`i''^2)) ///
                       - norm((`cutoff`i'' - `numer') / sqrt(1 - `rho`i''^2))) ///
        if ($ML_y1 == `i') & (`numer' - `cutoff`i'' >= 0)
    }
    replace `lnf' = `lnf' ///
                  + ln(norm((`numer' - `cutoff`J'') / sqrt(1 - `rho`J''^2))) ///
      if $ML_y1 == `J'
  }
end
