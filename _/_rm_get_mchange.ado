*! version 1.0.0 2014-02-14 | long freese | spost13 release

//  get mchange information

program _rm_get_mchange, sclass

    version 11.2
    syntax , VARnm(string) STat(string) [ AMount(string) pw(string) NOISily ]

    local isdelta `_orme[Camountdelta]'

    if ("`stat'"=="ch") local stat change
    if ("`stat'"=="p") local stat pvalue
    if ("`pw'"!="") local amount "bin"
    local isamount = inlist("`amount'","bin","one","sd","rng","marg","delta")
    local isstat   = inlist("`stat'","change","pvalue")
    if `isamount'==0 {
        display "invalid amount(`amount'): bin one sd rng marg are valid"
        local rc "bad amount"
    }
    if `isstat'==0 {
        display "invalid stat(`stat'): change pvalue are valid"
        local rc "`rc' bad stat"
        local rc = trim("`rc'")
    }
    if "`pw'"!="" local varnm "`varnm'!`pw'"
    if `isamount'==1 & `isstat'==1 {
        local rownm "`varnm':`amount'_`stat'"
        local rownum = rownumb(_mchange,"`rownm'")
        qui `noisily' di "rownum: `rownum' rownm: `rownm'"
        if !missing(`rownum') {
            matrix _mchange_vec = _mchange[`rownum',1...]
            local rc "ok"
            qui `noisily' matlist _mchange_vec, title(`rownm')
        }
        else {
            capture matrix drop _mchange_vec
            local rc "invalid row name"
        }
    }
    sreturn local rc "`rc'"

end
exit
