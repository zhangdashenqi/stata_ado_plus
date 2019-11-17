program define qsturng
*  return a studentized range quantile, q_`3'(`1', `2')
*! version 1.1.0 02Jul97     STB-47 sg101
   version 5.0
   capture assert (`1'>=2) & (`2'>=1) & (`3'*(1-`3') > 0)
   if _rc {
      di in red "invalid parameters in qsturng"
      error 499
   }
   global S_1 1
   local 2 = min(`2', 1E8)
   local 3 = string(`3')
   if `1' > 2 {
      global S_3 ".500 .750 .900 .950 .975 .990 .995 .999"
      if `3' > .99 & !(`3'==.995|`3'==.999) {
         global S_1 6
         global S_2 .995
      }
      else if `3' < .5 {
         global S_1 1
         global S_2 .75
      }
      else { qstux `3' }
      local pp $S_1
      if $S_2 {
         tempname z
         local px 1
         scalar `z' = -1/(1+1.5*invnorm((1+`3')/2))
         qstuz 1
         qstuz 2
         qstuz 3
      }

      local Nu = `2' >= 20
      if `Nu' {
         global S_3 "20 24 30 40 60 120 1E8"
         qstux `2'
         if !$S_2 { local w 1 }
         else {
            local w : word $S_1 of $S_3
            local w = ($S_2-`2')*`w'/(($S_2-`w')*`2')
         }
         local j $S_1
      }
      else {
         local j = int(`2')
         local w = (`j'+1-`2')*`j'/`2'
      }

      local lr = log(`1' - 1)
      qstuy `lr' `j' `w' `pp' `Nu'

      if "`px'" != "" {
         tempname y1 y2 y3 rnu
         scalar `rnu' = `1'*cond(`2' < 1E8, 1/`2', 0)
         while `px' < 4 {
            scalar `y`px'' = log($S_1 + `rnu')
            local pp = 1 + `pp'
            if `px' < 3 { qstuy `lr' `j' `w' `pp' `Nu' }
            local px = `px' + 1
         }
         scalar `y1' = (`y2'-`y1')/(scalar(S_2)-scalar(S_1))
         scalar `y3' = (`y3'-`y2')/(scalar(S_3)-scalar(S_2))
         if abs(2*(`y1'-`y3')/(`y1'+`y3')) < .01 {
            /* linear ipolation */
            if `z' > scalar(S_2) { scalar `y1' = scalar(`y3') }
            scalar `y3' = 0
         }
         else {
            /* quadratic ipolation */
            scalar `y3' = (`y3'-`y1')/(scalar(S_3)-scalar(S_1))
            scalar `y1' = `y1' - `y3'*(scalar(S_1)+scalar(S_2))
         }
         scalar `y2' = `y2' - scalar(S_2)*(`y1'+`y3'*scalar(S_2))
         global S_1 = exp( `y2'+`z'*(`y1'+`y3'*`z') ) - `rnu'
      }
      if `1' == 3 {
         global S_1 = $S_1 - .002/(1 + 12*(invnorm(`3'))^2)    /*
                 */ +  cond(`2'>=4.364, 1/(191*`2'), 1/517 - 1/(312*`2'))
      }
   }
   global S_1 = $S_1 * sqrt(2) * invt(`2', `3')
   di %6.0g $S_1
end


program define qstux
   local j : word count $S_3
   local j = `j' + 1
   local i 0
   while `j' != `i' + 1 {
      local m = int((`i'+`j')/2)
      local k1 : word `m' of $S_3
      if `k1' <= `1' { local i `m' }
      else { local j `m' }
   }
   local k1 : word `i' of $S_3
   if `1' > `k1' { global S_2 : word `j' of $S_3 }
   else { global S_2 0 }
   global S_1 `i'
end


program define qstuy
   local B "StuRng`4'`5'"
   capture local t = rowsof(`B')
   if _rc {
      sturng`4' `5'
      prog drop sturng`4'
   }
   global S_1 = (((matrix(`B'[`2',4])*`1' + matrix(`B'[`2',3]))*`1' +   /*
         */  matrix(`B'[`2',2]))*`1' + matrix(`B'[`2',1]))*`1' + 1
   if `3' < 1 {
      local t = (((matrix(`B'[`2'+1,4])*`1' + matrix(`B'[`2'+1,3]))*`1' +   /*
         */  matrix(`B'[`2'+1,2]))*`1' + matrix(`B'[`2'+1,1]))*`1' + 1
      global S_1 = sqrt(`3'*$S_1*$S_1 + (1-`3')*`t'*`t')
   }
end


program define qstuz
   local w = $S_1 + `1' - 1
   local w : word `w' of $S_3
   scalar S_`1' = -1/(1 + 1.5*invnorm((1+`w')/2))
end
