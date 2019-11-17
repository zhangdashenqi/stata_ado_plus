*! version 1.0.2  06aug2008  Ben Jann

//  syntax 1:
//      reldist y [if] [in] [weights], by(groupvar) [...]
//  syntax 2:
//      reldist y1 y0 [if] [in] [weights] [, ... ]
//  syntax 3:
//      reldist y [if] [in] [weights], theoretical(exp) //=> containing F(y)
//        => theoretical(normal(y))


program reldist, rclass
    version 9.2

    syntax varlist(max=2 numeric) [if] [in] [fw aw pw] [, ///
        by(passthru) swap ///
        Generate(passthru) Replace ///
        NORMal CHI2 CHI22(passthru) DISTribution(passthru) ///
        noGRaph ///
        cdf CDF2(str asis) ///
        pdf PDF2(namelist min=2 max=2) ///
            n(passthru) Kernel(passthru) exact REFLection lc ///
            bw(passthru) ADJust(passthru) Adaptive Adaptive2(passthru) ///
            altlbwf /// undocumented
            ci CI2(str asis) Level(passthru) ///
        OLABel(str asis) OTICk(str asis) OTItle(passthru) ///
        HISTogram HISTogram2(str asis) ///
        DIVergence /// undocumented
        POLarization ///
        Location Shape mean MULTiplicative reverse ///
        vce(passthru) * ]

    if "`cdf2'"!="" local cdf cdf
    if "`pdf2'"!="" local pdf pdf
    if "`ci2'"!="" local ci ci
    ParseCI , `ci2'
    if `"`histogram2'"'!="" local histogram histogram
    ParseHistogram `histogram2'
    if "`cdf'"!="" & ("`pdf'"!="" | "`histogram'"!="") {
        di as err "cdf not allowed together with pdf or histogram"
        exit 198
    }
    if "`generate'`cdf'`divergence'`polarization'`histogram'"=="" local pdf pdf
    ParseOlabel `olabel'
    ParseOtick `otick'
    if `"`otitle'"'=="" {
        local otitle otitle("")
    }

    _reldist compute `varlist' `if' `in' [`weight'`exp'] , ///
        `by' `swap' ///
        `generate' `replace' ///
        `normal' `chi2' `chi22' `distribution' ///
        `cdf' ///
        `pdf' `n' `kernel' `exact' `reflection' `lc' ///
             `bw' `adjust' `adaptive' `adaptive2' `altlbwf' ///
             `ci' `level' ///
        `olabel' `olabfmt' `otick' ///
        `histogram' `histogram2' ///
        `divergence' ///
        `polarization' ///
        `location' `shape' `mean' `multiplicative' `reverse' ///
        `vce'

    if "`cdf'`pdf2'`ci2'`hsave'"!="" {
        local vcdf: word 1 of `cdf2'
        local vgrid: word 2 of `cdf2'
        local vpdf: word 1 of `pdf2'
        if "`vgrid'"=="" {
            local vgrid: word 2 of `pdf2'
        }
        local vcil: word 1 of `ci2'
        local vciu: word 2 of `ci2'
        local vhist: word 1 of `hsave'
        local vhgrid: word 2 of `hsave'
        _reldist save, `replace' cdf(`vcdf') pdf(`vpdf') grid(`vgrid') ///
            ci(`vcil' `vciu') hist(`vhist') hgrid(`vhgrid')
    }

    if "`graph'"=="" & "`cdf'`pdf'`histogram'`histogram2'"!="" {
        local r 0
        capt confirm matrix r(grid)
        if _rc==0 {
            local r = rowsof(r(grid))
        }
        capt confirm matrix r(hist)
        if _rc==0 {
            local r = max(`r', rowsof(r(hist)))
        }
        if `r'>_N preserve

        tempvar vcdf vpdf vgrid vcil vciu vhist vhgrid
        qui _reldist save, cdf(`vcdf') pdf(`vpdf') grid(`vgrid') ///
            ci(`vcil' `vciu') hist(`vhist') hgrid(`vhgrid')
        _reldist graph, `cdf' `ciopts' `hopts' `olabopts' `otickopts' `otitle' `options'
    }

    return add
    foreach mat in cdf pdf grid ci_pdf hist hgrid {
        return local _`mat' ""
    }

end

prog ParseCI
    syntax [, save(namelist min=2 max=2) * ]
    c_local ci2 `save'
    c_local ciopts ciopts(`options')
end

prog ParseHistogram
    syntax [anything] [, save(namelist min=2 max=2) * ]
    if `"`anything'"'!="" {
        capt confirm integer number `anything'
        if _rc {
            local 0 , `0'
            capt syntax [, save(namelist min=2 max=2) * ]
            if _rc {
                di as err "option histogram2() incorrectly specified"
                exit 198
            }
            local anything
        }
    }
    if `"`anything'"'!="" c_local histogram2 histogram2(`anything')
    else                  c_local histogram2 ""
    c_local hsave `save'
    c_local hopts hopts(`options')
end

prog ParseOlabel
    syntax [anything] [, FORmat(str) * ]
    c_local olabel olabel(`anything')
    c_local olabfmt olabfmt(`format')
    c_local olabelopts olabelopts(`options')
end

prog ParseOtick
    syntax [anything] [, * ]
    c_local otick otick(`anything')
    c_local otickopts otickopts(`options')
end
