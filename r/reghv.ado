*! 1.0.0  15Feb1997  (Jeroen Weesie/ICS)  STB-42 sg77

* alternate interface to regh
program define reghv
        version 5.0
        
        local varlist "req ex"
        local if "opt"
        local in "opt"
        local options "Var(str) *"
        parse "`*'"

        if "`var'" == "" {
                di in re "option -var- required"
                exit 198
        }
        unabbrev `var'
        local var "$S_1"
        
        eq lp_mean  : `varlist'
        eq lp_lnvar : `var'

        regh lp_mean lp_lnvar `if' `in', `options'
end
