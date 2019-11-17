capture program drop dropmissing
program dropmissing

syntax varlist

capture drop flag
mark flag

markout flag `varlist'
drop if flag == 0

end
