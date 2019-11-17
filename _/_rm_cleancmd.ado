*! version 0.1.0 2013-08-20 | long freese | clean margins command

//  clean margins command before submitting it

capture program drop _rm_cleancmd
program define _rm_cleancmd, sclass
    local cmd "`*'"
    local cmd : subinstr local cmd "at()" "", all
    local cmd : subinstr local cmd "  " " ", all
    local cmd : subinstr local cmd " ," ",", all
    sreturn local cmd "`cmd'"
end

exit
