*!version 1.2 1999 Joseph Hilbe
* version 1.1.1  1993 Joseph Hilbe  rev:7-7-95 (sg44: STB-28)
* binomial distribution random number generator
* Example: rndbin 10000 .5 1  [set obs 10000; p = 0.5; n = 1]
 
program define rndbin
   version 3.1
   set type double
   cap drop xb
   qui   {
      local cases `1'
      set obs `cases'
      mac shift
      local pp `1'
      mac shift
      local n `1'
      if `pp' < 0.5  { local p = `pp' }
      else  { local  p = 1.0 - `pp' }
      local am = `n'*`p'
      noi di in gr "( Generating " _c
      if `n' < 25  {
         tempvar bn1 ran1
         gen `bn1' = 0
         gen `ran1' = uniform()
         local j=0
         while `j' < `n'  {
            replace `bn1' = `bn1' + 1 if (`ran1' < `p')
            local j = `j' + 1
            replace `ran1' = uniform()
            noi di in gr "." _c
         }
      }
      else if `am' < 1.0  {
         local g = exp(-`am')
         tempvar t em ds sum1 ran1 bn1
         gen `t' = 1.0
         gen `em' = -1
         gen `ran1'=uniform()
         gen `ds' = 1
         egen `sum1' = sum(`ds')
         while `sum1' > 0  {
            replace `em' = `em' + 1 if (`ds'==1)
            replace `t' = `t' * `ran1' if (`ds'==1)
            replace `ds' = 0 if (`g' > `t')
            replace `ran1' = uniform()
            drop `sum1'
            egen `sum1' = sum(`ds')
         }
         gen `bn1' = `em'
         replace `bn1' = `n' if (`em' > `n')
     }
     else  {
        tempvar ran1 ran2 ds ts sum1 e y em bn1
        local en = `n'
        local oldg = lngamma(`en'+1.0)
        local pc=1.0-`p'
        local plog = log(`p')
        local pclog = log(`pc')
        local sq = sqrt(2.0*`am'*`pc')
        gen `em' = -1
        gen `e' = -1
        gen `ran1' = uniform()
        gen `ran2' = uniform()
        gen `ds' = 1
        gen `ts' = 1
        gen `y' = -1
        egen `sum1' = sum(`ds')
        while `sum1' > 0  {
           replace `y' = sin(_pi*`ran1')/cos(_pi*`ran1')
           replace `em' = `sq'*`y' + `am' if (`ds'==1)
           replace `ts' =0 if (((0>`em') | (`em' >=(`en'+1.0))) & (`ds'==1))
           #delimit ;
           replace `e' = 1.2*`sq'*(1.0+(`y'*`y'))*exp(`oldg'-lngamma(`em'+1.0)
             -lngamma(`en'-`em'+1.0) + (`em' *`plog')+(`en'-`em')*`pclog') if
             (( `ds'==1) & (`ts'==1));
           #delimit cr
           replace `ds'=0 if ((`ran2'<`e') & (`ds'==1) & (`ts'==1))
           replace `ran1' = uniform()
           replace `ran2' = uniform()
           replace `e'=-1
           replace `ts' = 1
           drop `sum1'
           egen `sum1' = sum(`ds')
           noi di in gr "." _c
        }
        gen `bn1' = int(`em'+.5)
     }
     replace `bn1' = `n'-`bn1' if `p' ~= `pp'
     gen xb = `bn1'
     noi di in gr " )"
     noi di in bl "Variable " in ye "xb " in bl "created."
     lab var xb "Binomial random variable"
     set type float
   }
end
