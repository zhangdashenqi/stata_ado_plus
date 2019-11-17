*! version 2.5.0 2009-10-28 jsl

//  list versions of spost ado files being used

capture program drop prwhich
program define prwhich, rclass
    version 8
di
di in w ///
"== spost versions as of $S_TIME ========================================="
di
which _get_mlogit_bv
which _get_mlogit_bvecv
which _peabbv
which _pebase
which _pecats
which _peciboot
which _pecidelta
which _peciml
which _pecmdcheck
which _pecollect
which _pedum
which _peife
which _pemarg
which _penocon
which _pepred
which _perhs
which _pesum
which _petrap
which _peunvec
which _pexstring
which asprvalue
which brant
which case2alt
which countfit
which fitstat
which leastlikely
which listcoef
which misschk
which mlogplot
which mlogtest
which mlogview
which mvtab1
which nmlab
which praccum
which prchange
which prcounts
which prdc
which prgen
which prtab
which prvalue
which prwhich
which spex
which spostupdate
which vardesc
which xpost    
    
di
di in w ///
"========================================= spost versions as of $S_TIME =="

end
exit
* version 1.0.3 13Apr2005
