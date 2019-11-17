*! version 1.1 -- 4/19/2001

capture program drop orcalc
program define orcalc
  gettoken probs 0: 0, parse(",")
  syntax [, REFgroup(integer 1) ]
  tokenize `probs'
  if "`1'" != "" & "`2'" != "" & "`3'" != "" & "`4'" != ""{
    local groups = 4
  }
  else {
    if "`1'" != "" & "`2'" != "" & "`3'" != "" {
      local groups = 3
    }
    else {
      if "`1'" != "" & "`2'" != "" & "`3'" == "" {
        local groups = 2
      }
      else {
        display in ye "syntax is " in gr "orcalc p1 p2 [p3], [ref(refgroup)]"
        exit
      }
    }
  }

  if `refgroup' > `groups' {
    display in ye "The reference group cannot be larger than the number of groups"
    exit
  }

  if `groups' == 2 {
    if `refgroup' == 1 {
      display
      display in gr "Odds ratio for group 2 vs group 1"
      showodds `2' `1' 2 1
    }
    if `refgroup' == 2 {
      display
      display in gr "Odds ratio for group 1 vs group 2"
      showodds `1' `2' 1 2
    }
  }
  if `groups' == 3 {
    if `refgroup' == 1 {
      display 
      display in gr "Odds ratio for group 2 vs group 1"
      showodds `2' `1' 2 1
      display
      display in gr "Odds ratio for group 3 vs group 1"
      showodds `3' `1' 3 1
    }
    if `refgroup' == 2 {
      display 
      display in gr "Odds ratio for group 1 vs group 2"
      showodds `1' `2' 1 2
      display
      display in gr "Odds ratio for group 3 vs group 2"
      showodds `3' `2' 3 2
    }
    if `refgroup' == 3 {
      display 
      display in gr "Odds ratio for group 1 vs group 3"
      showodds `1' `3' 1 3
      display
      display in gr "Odds ratio for group 2 vs group 3"
      showodds `2' `3' 2 3
    }
  }

  if `groups' == 4 {
    if `refgroup' == 1 {
      display 
      display in gr "Odds ratio for group 2 vs group 1"
      showodds `2' `1' 2 1
      display
      display in gr "Odds ratio for group 3 vs group 1"
      showodds `3' `1' 3 1
      display
      display in gr "Odds ratio for group 4 vs group 1"
      showodds `4' `1' 4 1
    }
    if `refgroup' == 2 {
      display 
      display in gr "Odds ratio for group 1 vs group 2"
      showodds `1' `2' 1 2
      display
      display in gr "Odds ratio for group 3 vs group 2"
      showodds `3' `2' 3 2
      display
      display in gr "Odds ratio for group 4 vs group 2"
      showodds `4' `2' 4 2
    }
    if `refgroup' == 3 {
      display 
      display in gr "Odds ratio for group 1 vs group 3"
      showodds `1' `3' 1 3
      display
      display in gr "Odds ratio for group 2 vs group 3"
      showodds `2' `3' 2 3
      display
      display in gr "Odds ratio for group 4 vs group 3"
      showodds `4' `3' 4 3
    }
    if `refgroup' == 4 {
      display 
      display in gr "Odds ratio for group 1 vs group 4"
      showodds `1' `4' 1 4
      display
      display in gr "Odds ratio for group 2 vs group 4"
      showodds `2' `4' 2 4
      display
      display in gr "Odds ratio for group 3 vs group 4"
      showodds `3' `4' 3 4
    }
  }
end


capture program drop showodds
program define showodds
  args p1 p2 g1 g2

  local odds1 = (`p1'/(1-`p1'))
  local odds2 = (`p2'/(1-`p2'))
  local or = `odds1'/`odds2'
  local od1str = string(`odds1',"%8.3f")
  local od2str = string(`odds2',"%8.3f")
  local orstr = string(`or',"%8.3f")
  local p1s = string(`p1',"%4.2f")
  local p2s = string(`p2',"%4.2f")
  display in ye ""
  display "      p`g1' / (1 - p`g1')     odds`g1'     `p1s' / (1 - `p1s')     `od1str'"
  display "or = --------------- = ------- = ------------------- = ------- = `orstr'"
  display "      p`g2' / (1 - p`g2')     odds`g2'     `p2s' / (1 - `p2s')     `od2str'"
end

capture program drop showodd2
program define showodd2
  args p1 p2 g1 g2

  local odds1 = (`p1'/(1-`p1'))
  local odds2 = (`p2'/(1-`p2'))
  local or = `odds1'/`odds2'
  local od1str = string(`odds1',"%8.3f")
  local od2str = string(`odds2',"%8.3f")
  local orstr = string(`or',"%8.3f")
  local p1s = string(`p1',"%4.2f")
  local p2s = string(`p2',"%4.2f")
  display in ye ""
  display "         p`g1'  / (1 -  p`g1')        odds`g1'"
  display " or =  -------------------  =  -------  =   ?"
  display "         p`g2'  / (1 -  p`g2')        odds`g2'"
  display
  display "        `p1s' / (1 - `p1s')       `od1str'"
  display " or =  -------------------  =  -------  =  `orstr'"
  display "        `p2s' / (1 - `p2s')       `od2str'"
end

