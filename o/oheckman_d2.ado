program oheckman_d2
  version 9.2
  syntax anything		// cannot use args since we don't know how many scores there will be.
  gettoken todo anything : anything
  gettoken b anything : anything
  gettoken lnf anything : anything
  gettoken g anything : anything
  gettoken negH anything : anything

  quietly {
    local J = $OHECKMAN_NEQ - 1

    tempvar xbs
    mleval `xbs' = `b', eq(1)

    local eqn = 1
    forvalues i = 0/`J' {
      if real(substr("$OHECKMAN_HASY",`i'+1,1)) {
        tempvar xb`i'
        mleval `xb`i'' = `b', eq(`++eqn')
      }
    }

    tempname delta1 cutoff1
    scalar `delta1' = 1		// This is a hack to make much of the gradient/hessian code work without having to handle the first cutoff as a special case.
    mleval `cutoff1' = `b', scalar eq(`++eqn')
    forvalues i = 2/`J' {
      local previ = `i'-1
      tempname lndelta`i' delta`i' cutoff`i'
      mleval `lndelta`i'' = `b', scalar eq(`++eqn')
      scalar `delta`i'' = exp(`lndelta`i'')
      scalar `cutoff`i'' = `cutoff`previ'' + `delta`i''
    }

    tempvar rho
    gen double `rho' = .
    forvalues i = 0/`J' {
      tempname athrho`i' rho`i'
      if real(substr("$OHECKMAN_HASY",`i'+1,1)) {
        mleval `athrho`i'' = `b', scalar eq(`++eqn')
      }
      else {
        scalar `athrho`i'' = 0
      }
      scalar `rho`i'' = tanh(`athrho`i'')
      replace `rho' = `rho`i'' if $ML_y1 == `i'
    }

    forvalues i = 0/`J' {
      if real(substr("$OHECKMAN_HASY",`i'+1,1)) {
        tempname lnsigma`i' sigma`i'
        mleval `lnsigma`i'' = `b', scalar eq(`++eqn')
        scalar `sigma`i'' = exp(`lnsigma`i'')
      }
    }

    tempvar z lnfj upper lower
    gen double `z' = 0
    gen double `lnfj' = 0
    gen double `upper' = .
    gen double `lower' = .

    forvalues i = 0/`J' {
      if real(substr("$OHECKMAN_HASY",`i'+1,1)) {
        replace `z' = ($ML_y2 - `xb`i'') / `sigma`i'' if $ML_y1 == `i'
        replace `lnfj' = ln(normden(`z')) - `lnsigma`i'' if $ML_y1 == `i'
      }
    }

    local Jminus1 = `J' - 1
    forvalues i = 0/`Jminus1' {
      local nexti = `i'+1
      replace `lower' = (`xbs' + `rho`i''*`z' - `cutoff`nexti'') / sqrt(1 - `rho`i''^2) ///
        if $ML_y1 == `i'
    }
    replace `lower' = -1e10 if $ML_y1 == `J'
    replace `upper' = 1e10 if $ML_y1 == 0
    forvalues i = 1/`J' {
      replace `upper' = (`xbs' + `rho`i''*`z' - `cutoff`i'') / sqrt(1 - `rho`i''^2) ///
        if $ML_y1 == `i'
    }

    replace `lnfj' = `lnfj' + ln(norm(`upper') - norm(`lower')) if `upper' < 0
    replace `lnfj' = `lnfj' + ln(norm(-`lower') - norm(-`upper')) if `upper' >= 0

    mlsum `lnf' = `lnfj'

    if (`todo'==0 | missing(`lnf')) exit

    ********************* Gradient *********************
    tempvar  denom
    tempname d

    gen double `denom' = (norm( `upper') - norm( `lower')) if `upper' < 0
    replace    `denom' = (norm(-`lower') - norm(-`upper')) if `upper' >= 0

    gettoken d_alpha anything : anything
    replace `d_alpha' = (normden(`upper') - normden(`lower')) / `denom' / sqrt(1 - `rho'^2)
    mlvecsum `lnf' `d' = `d_alpha', eq(1)
    matrix `g' = (`d')

    local eqn = 1
    forvalues i = 0/`J' {
      if real(substr("$OHECKMAN_HASY",`i'+1,1)) {
        gettoken score`++eqn' anything : anything
        replace `score`eqn'' = 0
        replace `score`eqn'' = (`z' - `d_alpha' * `rho`i'') / `sigma`i'' if $ML_y1 == `i'
        mlvecsum `lnf' `d' = `score`eqn'', eq(`eqn')
        matrix `g' = (`g', `d')
      }
    }

    forvalues i = 1/`J' {
	local previ = `i'-1
      gettoken score`++eqn' anything : anything
      replace `score`eqn'' = 0
      replace `score`eqn'' = `delta`i'' * normden(`lower') / `denom' / sqrt(1 - `rho`previ''^2) if $ML_y1 == `previ'
      replace `score`eqn'' = -`delta`i'' * `d_alpha' if $ML_y1 > `previ'
      mlvecsum `lnf' `d' = `score`eqn'', eq(`eqn')
      matrix `g' = (`g', `d')
    }

    forvalues i = 0/`J' {
      if real(substr("$OHECKMAN_HASY",`i'+1,1)) {
        gettoken score`++eqn' anything : anything
        replace `score`eqn'' = 0
        replace `score`eqn'' = `z' * (1-`rho`i''^2) * `d_alpha' ///
                             + `rho`i''*(normden(`upper')*`upper' - normden(`lower')*`lower')/`denom' ///
          if $ML_y1 == `i'
        mlvecsum `lnf' `d' = `score`eqn'', eq(`eqn')
        matrix `g' = (`g', `d')
      }
    }

    forvalues i = 0/`J' {
      if real(substr("$OHECKMAN_HASY",`i'+1,1)) {
        gettoken score`++eqn' anything : anything
        replace `score`eqn'' = 0
        replace `score`eqn'' = (-1 + `z'^2 - `rho`i''*`z'*`d_alpha') if $ML_y1 == `i'
        mlvecsum `lnf' `d' = `score`eqn'', eq(`eqn')
        matrix `g' = (`g', `d')
      }
    }

    if (`todo'==1 | missing(`lnf')) exit

    ********************* Hessian *********************
    tempvar dvar d_alpha2 d_rho_alpha d_delta_alpha
    tempname row H_alpha2 H_beta_alpha H_beta2 H_delta_alpha H_delta_beta H_delta2
    tempname H_rho_alpha H_rho_beta H_rho_delta H_rho2
    tempname H_sigma_alpha H_sigma_beta H_sigma_delta H_sigma_rho H_sigma2
    gen double `dvar' = 0

    gen double `d_alpha2' = (`lower'*normden(`lower')-`upper'*normden(`upper')) / `denom' / (1 - `rho'^2) ///
                          - `d_alpha'^2
    mlmatsum `lnf' `H_alpha2' = `d_alpha2', eq(1)
    
    local eqn = 1
    forvalues i = 0/`J' {
      if real(substr("$OHECKMAN_HASY",`i'+1,1)) {
        replace `dvar' = 0
        replace `dvar' = -`d_alpha2' * `rho`i'' / `sigma`i'' if $ML_y1 == `i'      
        mlmatsum `lnf' `d' = `dvar', eq(`++eqn',1)
        matrix `H_beta_alpha' = (nullmat(`H_beta_alpha') \ `d')

        scalar `row' = .
        local eqn2 = 1
        forvalues i2 = 0/`J' {
          if real(substr("$OHECKMAN_HASY",`i2'+1,1)) {
            replace `dvar' = 0
            if `i' == `i2' {
              replace `dvar' = (`d_alpha2'*`rho`i''^2 - 1) / `sigma`i''^2 if $ML_y1 == `i'
            }
            mlmatsum `lnf' `d' = `dvar', eq(`eqn',`++eqn2')
            matrix `row' = (nullmat(`row'), `d')
          }
        }
        matrix `H_beta2' = (nullmat(`H_beta2') \ `row')
      }
    }

    gen double `d_delta_alpha' = normden(`lower') * (`lower' / sqrt(1-`rho'^2) + `d_alpha') / `denom' / sqrt(1 - `rho'^2)
    forvalues i = 1/`J' {
	local previ = `i'-1
      replace `dvar' = 0 if $ML_y1 < `previ'
      replace `dvar' = -`delta`i'' * `d_delta_alpha' if $ML_y1 == `previ'
      replace `dvar' = -`delta`i'' * `d_alpha2' if $ML_y1 > `previ'
      mlmatsum `lnf' `d' = `dvar', eq(`++eqn',1)
      matrix `H_delta_alpha' = (nullmat(`H_delta_alpha') \ `d')
      
      scalar `row' = .
      local eqn2 = 1
      forvalues i2 = 0/`J' {
        if real(substr("$OHECKMAN_HASY",`i2'+1,1)) {
          replace `dvar' = 0
          if `i2' == `previ' {
            replace `dvar' = `delta`i'' * `rho`i2'' * `d_delta_alpha' / `sigma`i2'' if $ML_y1 == `i2'
          }
          else if `i2' > `previ' {
            replace `dvar' = `delta`i'' * `rho`i2'' * `d_alpha2' / `sigma`i2'' if $ML_y1 == `i2'
          }
          mlmatsum `lnf' `d' = `dvar', eq(`eqn',`++eqn2')
          matrix `row' = (nullmat(`row'), `d')
        }
      }
      matrix `H_delta_beta' = (nullmat(`H_delta_beta') \ `row')

      scalar `row' = .
      forvalues i2 = 1/`J' {
        replace `dvar' = 0
        if `i2' == `i' {
          if `i' == 1 { // handled separately since first cutoff is not passed as logarithm
            replace `dvar' = `delta`i''^2 * normden(`lower') / (1 - `rho`previ''^2) / `denom' ///
                         * (`lower' - normden(`lower')/`denom') ///
              if $ML_y1 == `previ'
            replace `dvar' = `delta`i''^2 * `d_alpha2' ///
              if $ML_y1 > `previ'
          }
          else {
            replace `dvar' = `delta`i''^2 * normden(`lower') / (1 - `rho`previ''^2) / `denom' ///
                         * (`lower' - normden(`lower')/`denom') ///
                         + `delta`i'' * normden(`lower') / `denom' / sqrt(1 - `rho`previ''^2) ///
              if $ML_y1 == `previ'
            replace `dvar' = `delta`i''^2 * `d_alpha2' - `delta`i'' * `d_alpha' ///
              if $ML_y1 > `previ'
          }
        }
        else {
          replace `dvar' = `delta`i'' * `delta`i2'' * `d_delta_alpha' ///
            if ($ML_y1 == `previ' & $ML_y1 > `i2'-1) | ($ML_y1 > `previ' & $ML_y1 == `i2'-1)
          replace `dvar' = `delta`i'' * `delta`i2'' * `d_alpha2' if $ML_y1 > `previ' & $ML_y1 > `i2'-1
        }
        mlmatsum `lnf' `d' = `dvar', eq(`eqn',`++eqn2')
        matrix `row' = (nullmat(`row'), `d')
      }
      matrix `H_delta2' = (nullmat(`H_delta2') \ `row')
    }

    gen double `d_rho_alpha' = `z' * (1 - `rho'^2) * `d_alpha2' ///
                             + `rho' / `denom'  ///
                             * ((`lower'^2 * normden(`lower') - `upper'^2 * normden(`upper')) / sqrt(1-`rho'^2) ///
                               + ((`lower'*normden(`lower') - `upper'*normden(`upper')) + `denom') * `d_alpha')
    forvalues i = 0/`J' {
      if real(substr("$OHECKMAN_HASY",`i'+1,1)) {
        replace `dvar' = 0
        replace `dvar' = `d_rho_alpha' if $ML_y1 == `i'      
        mlmatsum `lnf' `d' = `dvar', eq(`++eqn',1)
        matrix `H_rho_alpha' = (nullmat(`H_rho_alpha') \ `d')
      
        scalar `row' = .
        local eqn2 = 1
        forvalues i2 = 0/`J' {
          if real(substr("$OHECKMAN_HASY",`i2'+1,1)) {
            replace `dvar' = 0
            if `i' == `i2' {
              replace `dvar' = (-`d_alpha'*(1-`rho`i''^2) - `rho`i''*`d_rho_alpha') / `sigma`i'' if $ML_y1 == `i'
            }
            mlmatsum `lnf' `d' = `dvar', eq(`eqn',`++eqn2')
            matrix `row' = (nullmat(`row'), `d')
          }
        }
        matrix `H_rho_beta' = (nullmat(`H_rho_beta') \ `row')

        scalar `row' = .
        forvalues i2 = 1/`J' {
          replace `dvar' = 0
          if `i' == `i2'-1 {
            replace `dvar' = -`delta`i2'' * ///
                          (`z' * (1 - `rho`i''^2) * `d_delta_alpha' ///
                           + `rho`i'' * normden(`lower') / `denom' / sqrt(1-`rho`i''^2) ///
                             * (-1 + `lower'^2 + (normden(`upper')*`upper' - normden(`lower')*`lower')/`denom')) ///
              if $ML_y1 == `i'
          }
          else if `i' > `i2'-1 {
            replace `dvar' = -`delta`i2'' * `d_rho_alpha' if $ML_y1 == `i'
          }
          mlmatsum `lnf' `d' = `dvar', eq(`eqn',`++eqn2')
          matrix `row' = (nullmat(`row'), `d')
        }
        matrix `H_rho_delta' = (nullmat(`H_rho_delta') \ `row')

        scalar `row' = .
        forvalues i2 = 0/`J' {
          if real(substr("$OHECKMAN_HASY",`i2'+1,1)) {
            replace `dvar' = 0
            if `i' == `i2' {
              replace `dvar' = (1 - `rho`i''^2) ///
                           * (-2 * `rho`i'' * `z' * `d_alpha' ///
                             + `z' * `d_rho_alpha' ///
                             + (`upper'*normden(`upper') - `lower'*normden(`lower')) / `denom') ///
                           + `rho`i''^2 / `denom' ///
                           * (`upper' * normden(`upper') * (1 - `upper'^2) ///
                             + `lower' * normden(`lower') * (`lower'^2 - 1) ///
                             - (`upper'*normden(`upper') - `lower'*normden(`lower'))^2 / `denom') ///
                           + (1 - `rho`i''^2) * `z' * `rho`i'' / `denom'  ///
                           * ((`lower'^2 * normden(`lower') - `upper'^2 * normden(`upper')) / sqrt(1-`rho`i''^2) ///
                             + ((`lower'*normden(`lower') - `upper'*normden(`upper')) + `denom') * `d_alpha') ///
                if $ML_y1 == `i'
            }
            mlmatsum `lnf' `d' = `dvar', eq(`eqn',`++eqn2')
            matrix `row' = (nullmat(`row'), `d')
          }
        }
        matrix `H_rho2' = (nullmat(`H_rho2') \ `row')
      }
    }

    forvalues i = 0/`J' {
      if real(substr("$OHECKMAN_HASY",`i'+1,1)) {
        replace `dvar' = 0
        replace `dvar' = -`rho`i'' * `z' * `d_alpha2' if $ML_y1 == `i'
        mlmatsum `lnf' `d' = `dvar', eq(`++eqn',1)
        matrix `H_sigma_alpha' = (nullmat(`H_sigma_alpha') \ `d')
      
        scalar `row' = .
        local eqn2 = 1
        forvalues i2 = 0/`J' {
          if real(substr("$OHECKMAN_HASY",`i2'+1,1)) {
            replace `dvar' = 0
            if `i' == `i2' {
              replace `dvar' = (`rho`i''*`d_alpha' + `z'*(`rho`i''^2*`d_alpha2' - 2)) / `sigma`i'' if $ML_y1 == `i'
            }
            mlmatsum `lnf' `d' = `dvar', eq(`eqn',`++eqn2')
            matrix `row' = (nullmat(`row'), `d')
          }
        }
        matrix `H_sigma_beta' = (nullmat(`H_sigma_beta') \ `row')

        scalar `row' = .
        forvalues i2 = 0/`J' {
          if real(substr("$OHECKMAN_HASY",`i2'+1,1)) {
            replace `dvar' = 0
            if `i' == `i2' {
              replace `dvar' = -`z' * (`d_alpha'*(1-`rho`i''^2) + `rho`i''*`d_rho_alpha') if $ML_y1 == `i'
            }
            mlmatsum `lnf' `d' = `dvar', eq(`eqn',`++eqn2')
            matrix `row' = (nullmat(`row'), `d')
          }
        }
        matrix `H_sigma_rho' = (nullmat(`H_sigma_rho') \ `row')

        scalar `row' = .
        forvalues i2 = 1/`J' {
          replace `dvar' = 0
          if `i' == `i2'-1 {
            replace `dvar' = `delta`i2'' * `rho`i'' * `z' * `d_delta_alpha' if $ML_y1 == `i'
          }
          else if `i' > `i2'-1 {
            replace `dvar' = `delta`i2'' * `rho`i'' * `z' * `d_alpha2' if $ML_y1 == `i'
          }
          mlmatsum `lnf' `d' = `dvar', eq(`eqn',`++eqn2')
          matrix `row' = (nullmat(`row'), `d')
        }
        matrix `H_sigma_delta' = (nullmat(`H_sigma_delta') \ `row')

        scalar `row' = .
        forvalues i2 = 0/`J' {
          if real(substr("$OHECKMAN_HASY",`i2'+1,1)) {
            replace `dvar' = 0
            if `i' == `i2' {
              replace `dvar' = (`rho`i''^2*`d_alpha2' - 2) * `z'^2 + `rho`i''*`d_alpha'*`z' if $ML_y1 == `i'
            }
            mlmatsum `lnf' `d' = `dvar', eq(`eqn',`++eqn2')
            matrix `row' = (nullmat(`row'), `d')
          }
        }
        matrix `H_sigma2' = (nullmat(`H_sigma2') \ `row')
      }
    }


    matrix `negH' = -(`H_alpha2',      `H_beta_alpha'', `H_delta_alpha'', `H_rho_alpha'', `H_sigma_alpha'' \ ///
                      `H_beta_alpha',  `H_beta2',       `H_delta_beta'',  `H_rho_beta'',  `H_sigma_beta''  \ ///
                      `H_delta_alpha', `H_delta_beta',  `H_delta2',       `H_rho_delta'', `H_sigma_delta'' \ ///
                      `H_rho_alpha',   `H_rho_beta',    `H_rho_delta',    `H_rho2',       `H_sigma_rho''   \ ///
                      `H_sigma_alpha', `H_sigma_beta',  `H_sigma_delta',  `H_sigma_rho',  `H_sigma2')
  }  
end
