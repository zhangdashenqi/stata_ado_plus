capture program drop extrans
program define extrans, rclass
  version 7
  syntax varlist 
  tokenize `varlist'
  while "`1'" ~= "" {
       tempvar X Y Z
       local p25 p75 p50
       local x25 x75 x50
       local y25 y75 y50
       local z25 z75 z50
       
       gen `X' = sqrt(`1')
       gen `Y' = log(`1')
       gen `Z' = -1/sqrt(`1') 
       
      quietly sum `1' , detail
	 local p25 = r(p25)
       local p75 = r(p75)
       local p50 = r(p50)
       

	quietly sum `X' , detail
       local x25 = r(p25)
       local x75 = r(p75)
       local x50 = r(p50)

 	quietly sum `Y' , detail
	 local y25 = r(p25)
       local y75 = r(p75)
       local y50 = r(p50)

      quietly sum `Z' , detail
	 local z25 = r(p25)
       local z75 = r(p75)
       local z50 = r(p50)


di in green "----> Variable `1':"
di 
di in green "| Transformation      |    Q1    |    Q2    |    Q3    |(Q3-Q2)/(Q2-Q1)|"
di in green "|_____________________|__________|__________|__________|_______________|"
di in green "| `1'"  _col(23) in green "|" _col(24) in yellow `p25'  _col(34)in green "|" /*
*/  _col(35) in yellow `p50'  _col(45) in green "|"   _col(46) in yellow `p75' /*
*/  _col(56) in green "|"  _col(57) in yellow (`p75'-`p50')/(`p50'-`p25')
di in green "| SQRT(`1')" _col(23) in green "|" _col(24) in yellow `x25' _col(34)in green "|" /*
*/  _col(35) in yellow `x50' _col(45) in green "|"   _col(46) in yellow `x75' /*
*/  _col(56) in green "|"  _col(57) in yellow (`x75'-`x50')/(`x50'-`x25')
di in green "| LOG(`1')" _col(23) in green "|" _col(24) in yellow `y25' _col(34)in green "|" /*
*/  _col(35) in yellow `y50'  _col(45) in green "|"   _col(46) in yellow `y75' /*
*/  _col(56) in green "|"  _col(57) in yellow (`y75'-`y50')/(`y50'-`y25')
di in green "| -1/SQRT(`1')" _col(23) in green "|" _col(24) in yellow `z25' _col(34)in green "|" /*
*/  _col(35) in yellow `z50'  _col(45) in green "|"   _col(46) in yellow `z75' /*
*/  _col(56) in green "|"  _col(57) in yellow (`z75'-`z50')/(`z50'-`z25')
di 
              
    macro shift
    drop `X' `Y' `Z'
  }
end
