*! mvdom version 1.0 Jan 15, 2014 Joseph N. Luchman

program define mvdom, eclass

syntax varlist(min = 2) if [aw fw], dvs(varlist min=1) [noConstant]

tempname canonmat

gettoken dv ivs: varlist

quietly canon (`dv' `dvs') (`ivs') [`weight'`exp'] `if', `constant'

matrix `canonmat' = e(ccorr)

ereturn scalar r2 = `canonmat'[1, 1]^2

ereturn local title "Multivariate regression"

end
