*! 2005.12.03
*! Author: Lian Yu-Jun
*! arlionn@163.com

cap program drop math
program math
        version 8

        local z : list retokenize 0
        local z : subinstr local z "=" " ", all 
        local z : subinstr local z "(" " ", all 
        local z : subinstr local z ")" " ", all 

        local output : word 1 of `z'
        local func : word 2 of `z'
        local input : word 3 of `z'

        local rowno = rowsof(`input')
        local colno = colsof(`input')
        local rname : rowfullnames `input'
        local cname : colfullnames `input'
        mat `output'_ = J(`rowno',`colno',0)
        forvalue i = 1(1)`rowno' {
          forvalue j = 1(1)`colno' {
            matrix `output'_[`i',`j'] = `func'(`input'[`i',`j'])
          }
        }
        quietly capture matrix drop `output'
        matrix rename `output'_ `output'
        matrix rownames `output' = `rname'
        matrix colnames `output' = `cname'
end

/*
program math
        version 8
        preserve
        drop _all
        local z = trim("`0'")
        local z = subinstr("`z'","="," ",.)
        local z = subinstr("`z'","("," ",.)
        local z = subinstr("`z'",")"," ",.)
        local output = word("`z'",1)
        local func = word("`z'",2)
        local input = word("`z'",3)

        local colno = colsof(`input')
        quietly svmat double `input'
        capture matrix drop `output'
        if `colno' > 1 {
           forvalues i = 1/`colno' {
           quietly replace `input'`i' =  `func'(`input'`i')
           }
           mkmat `input'1-`input'`colno', matrix(`output')
        }
        else {
           quietly replace `input' =  `func'(`input')
           mkmat `input', matrix(`output')
        }
end
*/
