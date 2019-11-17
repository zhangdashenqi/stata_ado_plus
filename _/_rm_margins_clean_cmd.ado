*! version 1.0.0 2014-02-14 | long freese | spost13 release

//  clean margins command before submitting it

program define _rm_margins_clean_cmd, sclass
    local cmd "`*'"
    local cmd : subinstr local cmd " )" ")", all
    local cmd : subinstr local cmd "at()" "", all
    local cmd : subinstr local cmd "  " " ", all
    local cmd : subinstr local cmd " ," ",", all
    sreturn local cmd "`cmd'"
end
exit

_rm_margins_clean_cmd `cmd'
local cmd `"`s(cmd)'"'
