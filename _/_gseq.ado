*! 2.0.0 NJC 1 February 1999 STB-50 dm70
* seq NJC 1.3.0  16 June 1997
program define _gseq
        version 6.0
        gettoken type 0 : 0
        gettoken g 0 : 0
        gettoken eqs 0 : 0
        gettoken lparen 0 : 0, parse("(")
        gettoken rparen 0 : 0, parse(")")
        syntax [if] [in] [ , by(string) Block(int 1) From(int 1) To(str)]

        if "`to'" == "" { local to = _N }
        else confirm integer n `to'

        if `block' < 1 {
                di in r "block should be at least 1"
                exit 498
        }

        if `from' > `to' {
                local temp = `from'
                local from = `to'
                local to = `temp'
        }

        marksample touse

        quietly {
                tempvar porder
                gen long `porder' = _n
                gen byte `g' = .
                sort `touse' `by' `porder'
                #delimit ;
                by `touse' `by':
                replace `g'
                = `from' + int(mod((_n - 1) / `block', `to' - `from' + 1))
                if `touse' ;
                #delimit cr
                if "`temp'" != "" { replace `g' = `to' + `from' - `g' }
        }
end

