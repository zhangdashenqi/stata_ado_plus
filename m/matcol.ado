*! version 0.2.1 2013-02-18 | scott long | add spaces
* version 0.2.0 2012-10-28 | scott long

* set _matrc.ado for details

capture program drop matcol
program matcol

    version 11.2
    local input "`*'"
    foreach t in = , + - = \ * / % {
        local input = subinstr("`input'","`t'"," `t' ",.)
    }
    local input = subinstr("`input'","  "," ",.)
    _matrc col `input'

end
exit

