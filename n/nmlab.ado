*!  version 1.0.0 \ scott long 2007-08-05

//  syntax:     nmlab <list of variables>, column(for labels) number vl
//  task:       list variable names and labels
//  project:    workflow chapter 4
//  author:     scott long \ 2007-08-05

capture program drop nmlab
program define nmlab
    version 8, missing
    syntax [varlist] [, COLumn(integer 0) NUMber vl]
    tokenize `varlist'
    local stop : word count `varlist'

    local len = 0
    local i 1
    while `i' <= `stop' {
        local l = length("``i''")
        if `l'>`len' local len = `l'
        local i = `i' + 1
    }
    if `column'==0 local column = `len' + 3

    display
    local i 1
    if "`number'"=="number" {
        local column = `column' + 6
    }
    else {
        local n ""
    }

    * value label location
    if "`vl'"=="vl" {
        local column2 = `column' + 11 // for labels
    }

    while `i' <= `stop' {
        local varlbl :  variable label ``i'' // grab var label
        local vallbl : value label ``i'' // grab value label

        if "`number'"=="number" {
            local n = substr(string(`i',"%4.0f") + ".     ",1,6)
        }
        if "`vl'"!="vl" {
            display in green "`n'``i''" in y _col(`column') "`varlbl'"
        }
        else { // show value label
            display in green "`n'``i''" in white _col(`column') ///
                "`vallbl'" in y _col(`column2') "`varlbl'"
        }
        local i = `i' + 1
    }
end
exit
