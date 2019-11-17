* version 0.0.1 2013-08-29 | long | with mchange v2

//  get info from matrices

* TO DO put all matrix input here

capture program drop _orme_data_getmatrix
program _orme_data_getmatrix, sclass

qui `noisily' di _new "    ! entering  _orme_data_getmatrix"

    version 11.2

    args noisily

    local Cvalues "`_orme[Cvalues]'"
    local Cmatrixstub "`_orme[Cmatrixstub]'"
    local Ccatvals "`_orme[Ccatvals]'"
    local Ccatnms "`_orme[Ccatnms]'"
    local CcatsN "`_orme[CcatsN]'"
    local Cebaseout "`_orme[Cebaseout]'"

    tempname sd rng temp
    local error = 0

//  add getting ME from matrix

        //  matrix input: NVARS==#vars; NCATS=#categories
        * 1 x NVARS with SDs: mat Xsd = (1,2,3)
        matrix `temp' = `Cmatrixstub'sd
        matrix `temp' = `temp''
        matrix colna `temp' = _P_EVsd
        qui svmat `temp', names(col)
        label var _P_EVsd "SD of rhs variables"

        * 1 x NVARS with is it dummy var: mat Xdummy = (1,0,1)
        matrix `temp' = `Cmatrixstub'dummy
        matrix `temp' = `temp''
        matrix colna `temp' = _P_EVbin
        qui svmat `temp', names(col)
        label var _P_EVbin "Binary indicator of rhs variables"

        * 1 x NVARS with range: mat Xrange = (1,4,12.1)
        matrix `temp' = `Cmatrixstub'range
        matrix `temp' = `temp''
        matrix colna `temp' = _P_EVrng
        qui svmat `temp', names(col)
        label var _P_EVrng "Range of rhs variables"
        matrix drop `temp'

        * NCATS names of categories in order 1st cat, 2nd, 3rd,...
        local Ccatnms  "$`Cmatrixstub'catnms"

        * NCATS values of categories
        local Ccatvals "$`Cmatrixstub'catvals"
        if ("`Cvalues'"=="values") local Ccatnms "`Ccatvals'"
        local CcatsN = wordcount("`Ccatnms'")

char _orme[Ccatnms] `"`Ccatnms'"'
char _orme[Ccatvals] `"`Ccatvals'"'
char _orme[CcatsN] `"`CcatsN'"'

        * global with base category from mlogit.
        local Cebaseout $`Cmatrixstub'basecat
        if "`Cebaseout'"=="" {
            di as error "the global <matrixstub>basecat must be specified."
            sreturn local error = `error'
            exit // is ignored?
        }
        if (`Cebaseout'==0 |`Cebaseout'==.) local Ccatebaseout = 1
char _orme[Cebaseout] `"`Cebaseout'"'

        * NVARS names of predictors
        local ORbetanms "$`Cmatrixstub'rhsnms"
        local ORnbetanms = wordcount("`ORbetanms'")

        * name of estimation command for input coefficients
        if "$`Cmatrixstub'cmd"=="mlogit" {

            * estimates in order: NCATS rows; NVAR columns
            * row 1 is 1st non base cat VS basecat
            * row 2 is 2nd non base cat VS basecat, etc
            matrix _orme_B = `Cmatrixstub'beta
            matrix _orme_Bstd = _orme_B // to hold std betas
            matrix _orme_Brng = _orme_B // to hold range std betas

            * create standardized and range adjusted coefficients
            local inum = 1
            while `inum' < `ORnbetanms'+1 {
                scalar `sd' = _P_EVsd[`inum']
                scalar `rng' = _P_EVrng[`inum']
                local icat = 1
                while `icat' < `CcatsN' {
                    matrix _orme_Bstd[`icat',`inum'] ///
                        = _orme_B[`icat',`inum'] * `sd'
                    matrix _orme_Brng[`icat',`inum'] ///
                        = _orme_B[`icat',`inum'] * `rng'
                    local ++icat
                }
                local ++inum
            }
        } // mlogit

        else { // not mlogit
            matrix _orme_B = `Cmatrixstub'beta
            matrix _orme_Bstd = _orme_B*0
            matrix _orme_Brng = _orme_B*0
        }
        local error = 0

    char _orme[ORbetanms] `"`ORbetanms'"'
    char _orme[ORnbetanms] `"`ORnbetanms'"'


qui `noisily' di in blue _new "====> Leaving  _orme_data_getmatrix"
/*
qui `noisily' matlist _orme_B, title(_orme_B)
qui `noisily' matlist _orme_V, title(_orme_V)
qui `noisily' matlist _orme_Bstd, title(_orme_Bstd)
qui `noisily' matlist _orme_Brng, title(_orme_Brng)
qui `noisily' char list _orme[]
*/
    sreturn local error = `error'

qui `noisily' di _new "    ! leaving   _orme_data_getmatrix"

end

exit

