program define rmttest                          
*!  version 1.1.1 28Jan96                               (STB-30: sg49)

   version 4.0
   local varlist "req ex min(1) max(1)"
   local if "opt"
   local in "opt"
   #delimit ;
   local options "BY(string) CI GRaph ID(string) Level(real .95)
      Symbol(string) *";
   #delimit cr

   parse "`*'"
   parse "`varlist'", parse(" ")
   local x1val : word 2 of `by'
   local x2val : word 3 of `by'
   local by : word 1 of `by'
   rmtv `by'
   local by "$S_1"
   confirm variable `id'
   if ("`ci'" != "") & (`level' > 1) {
      local level = `level'/100
      if `level'*(1-`level') < 0 { 
         di in red "invalid confidence level"
         error 499
      }
   }
   if "`x1val'" != "" & "`x2val'" != "" {
      local sk : type `by'
      if "`sk'" == "float" {
         local x1val "float(`x1val')"
         local x2val "float(`x2val')"
      }
      local lci "(`by'==`x1val'|`by'==`x2val')"
      if "`if'" != "" { local if "`if' & `lci'"}
      else { local if "if `lci'" }
   }
   tempvar use
   mark `use' `if' `in'
   markout `use' `varlist' `by' `id'
   qui count if `use'
   if !_result(1) { error 2000 }
   else if _result(1) < 4 { error 2001 }
   qui inspect `by' if `use'
   if _result(7) != 2 {
      di in red "`by' takes on", _result(7), "values, not 2"
      error 499
   }

   local srtby : sortedby
   tempvar srtvar dx
   qui gen long `srtvar' = _n
   sort `use' `id' `by'
   local sk : type `1'
   if "`sk'" != "double" { local sk "float" }
   qui gen `sk' `dx' = `1' - `1'[_n-1] if `use' & (`id'==`id'[_n-1])
   qui summ `1' if `use' & (`dx'==.)
   local x1val = round(`by'[_N-1], 5E-7)
   local df = _result(1) - 1
   local sk = 10 - length("`by'")
   noi di in gr _sk(`sk') "`by'" _col(12) "|" _col(19) "Obs"   /*
      */ _col(30) "Mean" _col(37) "Std. Err." _con
   if "`ci'" != "" {
      local ci = invt(`df', `level')
      local lci = 100*`level'
      local sk = 10 -length("`lci'")
      noi di in gr _sk(`sk') "[`lci'% Conf. Interval]"
   }
   else { noi di "" }
   noi rmtxx `ci'
   noi rmtx `x1val' `ci'
   local Ttick "$S_3, $S_1, $S_4"
   local x2val = round(`by'[_N], 5E-7)
   qui summ `1' if `use' & (`dx'!=.)
   noi rmtx `x2val' `ci'
   local Rtick "$S_3, $S_1, $S_4"
   noi rmtxx `ci'
   qui summ `dx' if `use' & (`dx'!=.)
   noi rmtx "Diff" `ci'

   local lci = $S_1/$S_2
   local pv = tprob(`df', `lci')
   noi di in gr _new "  Ho:  mean(Diff) = 0"  _skip(4) "df = "  /*
      */ in ye "`df'" _skip(4) in gr "t = " in ye round(`lci', .01)  /*
      */ _skip(4) in gr "Pr > |t| = " in ye %6.4f round(`pv', .0001)
      
   if "`graph'" != "" {
      more
      qui replace `dx' = `1'[_n-1] if `use' & (`id'==`id'[_n-1])
      tempvar deq
      qui gen `deq' = `dx' if `use' & `dx' != .
      if "`ci'" != "" {
         local ttick "ttick(`Ttick')"
         local rtick "rtick(`Rtick')"
      }
      if "`symbol'" != "" {
         local sk = substr("`symbol'", 1, 1)
         if "`sk'" == "[" {
            local sk = substr("`symbol'", 1, index("`symbol'", "]"))
         }
         local symbol "`sk'"
      }
      else { local symbol "o" }
      local sk : variable label `1'
      lab var `1' "`1' (`by' == `x2val')"
      lab var `dx' "`1' (`by' == `x1val')"
      gr `1' `deq' `dx', sym(`symbol'i) c(.l) `ttick' `rtick' `options'
      lab var `1' "`sk'"
   }
   sort `srtvar'
   if "`srtby'" != "" { sort `srtby' }
end


program define rmtx
   global S_1 = _result(3)
   global S_2 = sqrt(_result(4)/_result(1))
   local kk = 10 - length("`1'")
   noi di in gr _skip(`kk') "`1'" _col(12) "|" in ye _col(15)  /*
      */    %7.0g _result(1) _col(25) %9.0g _result(3) _col(37)   /*
      */    %9.0g $S_2 _con
   if "`2'" == "" { di "" }
   else {
      global S_3 = _result(3) - `2'* $S_2
      global S_4 = _result(3) + `2'* $S_2
      di in ye _skip(7) %9.0g $S_3 _skip(3) %9.0g $S_4
   }
end


program define rmtxx
   di in gr _dup(11) "-"  "+" _dup(33) "-" _con
   if "`1'" != "" { di in gr _dup(28) "-" }
   else { di "" }
end


program define rmtv
   local varlist "req ex min(1) max(1)"
   parse "`*'"
   parse "`varlist'", parse(" ")
   global S_1 "`1'"
end
