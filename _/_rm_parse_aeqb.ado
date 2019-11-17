*! version 1.0.0 2014-02-14 | long freese | spost13 release

//  _rm_parse_AeqB: parse string of format: a=b c d e=f...
//
//  Two types of input:
//
//      equal:      label = source
//      no equal:   source          implies source = source ]
//
//  input:      list(string)
//              sourcenames(string) valid names for source
//              labelnames(sting)   valid names for labels
//
//  output:     s(label_names)      name to use as label
//              s(source_names)     name to use as source
//              s(label_valid)      string of 1 0's for valid and not
//              s(source_valid)     string of 1 0's for valid and not
//              s(error)            0 ok; 1 not balanced

program _rm_parse_AeqB, sclass

    syntax , list(string) [ sourcenames(string) labelnames(string) ]

    local error = 0
    local label_names
    local source_names
    local label_valid
    local source_valid

    local list  : subinstr local list "  " " ", all
    local list  : subinstr local list "=" " = ", all
    local list  : subinstr local list "  " " ", all

    local N_token : word count `list'

//  loop through tokens

    local i_token = 1
    local i_tokennext = 1

    while `i_token' <= `N_token' {

        local Ltoken : word `i_token' of `list'
        local Lnum = `i_token'

        if `i_token' < `N_token' {
            local ++i_token
            local EQtoken : word `i_token' of `list'
        }
        else local EQtoken "VOID"

//  equal found

        if "`EQtoken'"=="=" {

            local i_tokennext = `i_token' + 2 // +2 since EQtoken & Rtoken used

            local labelnm "`Ltoken'"
            local label_names "`label_names' `labelnm'" // names being returned

            local ++i_token
            if `i_token' <= `N_token' {
                local Rtoken : word `i_token' of `list'
            }
            else {
                di as error "A name must follow each equal sign"
                local error = 1
                continue, break
            }

            local sourcenm "`Rtoken'" // source name is to right of =
            local source_names "`source_names' `sourcenm'"

        } // equal sign

//  equal not found

        else {

            local i_tokennext = `Lnum' + 1
            local labelnm "`Ltoken'"
            local label_names "`label_names' `Ltoken'"
            local Rtoken "`Rtoken'"
            local sourcenm "`Ltoken'" // ! source is L not R
            local source_names "`source_names' `sourcenm'"
            * make source name a valid label name
            local labelnames "`labelnames' `sourcenm'"
        }

//  are labels and soruce names valid?

        if "`labelnames'"!="" {
            local isok : list posof "`labelnm'" in labelnames
            local isok = `isok'>0
            local label_valid "`label_valid' `isok'"
        }
        else { // assumed ok
            local label_valid "`label_valid' 1"
        }

        if "`sourcenames'"!="" {
            local isok : list posof "`sourcenm  '" in sourcenames
            local isok = `isok'>0
            local source_valid "`source_valid' `isok'"
        }
        else { // assumed ok
            local source_valid "`source_valid' 1"
        }

        local i_token = `i_tokennext'

    } // loop through tokens

//  close up

    if `error'==1 {
        sreturn local error = 1
        exit
    }

    sreturn local error = 0
    sreturn local label_names  `"`label_names'"'
    sreturn local source_names `"`source_names'"'
    sreturn local source_valid  "`source_valid'"
    sreturn local label_valid   "`label_valid'"

end
exit

EXAMPLE

local list "a=1 b=2 3 4 c=99"
local srcok "1 2 3"
di "valid source names: `srcok'"

local lblok "a b d"
di "valid labels:       `lblok'"

di "list is: `list'"
di "labels: 1 2 3 4 are ok; 5   not"
di "source: 1 2 3   are ok; 4 5 not"

_rm_parse_AeqB, list(`list') sourcenames(`srcok') labelnames(`lblok')

di "`s(label_names)'      name to use as label"
di "`s(source_names)'     name to use as source"
di "`s(label_valid)'      string of 1 0's for valid and not"
di "`s(source_valid)'     string of 1 0's for valid and not"
di "`s(error)'            0 ok; 1 unbalanced; 2 invalid label"
