*! version 0.2.2 2013-08-04 | scott long | call sreturns
* version 0.2.1 2013-02-18 | scott long | call _matmath
* version 0.2.0 2012-10-28 | scott long

* set _matmath.ado for details

capture program drop matmath
program matmath, sclass

    version 11.2
    local input "`*'"
    foreach t in = , + - = \ * / % {
        local input = subinstr("`input'","`t'"," `t' ",.)
    }
    local input = subinstr("`input'","  "," ",.)
    _matmath `input'

    sreturn local nrows `s(nrows)'
    sreturn local ncols `s(ncols)'
end
exit

