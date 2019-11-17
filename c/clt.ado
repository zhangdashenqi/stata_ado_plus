*! revised to version 8.2, 1/24/04, mnm
capture program drop clt
program define clt
  version 6.0
  * window manage forward dialog

  global temp1 "Distribution Type"
  window control static temp1  5 10 55 10
  global DB_distL Normal,LogNormal,Exponential,Bimodal,Binomial,Uniform
  global DB_dist="Normal"
  window control scombo DB_distL 60 10 50 60 DB_dist parse(,)

  global temp2 "If Binomial, P="
  window control static temp2  5 25 45 10
  global DB_probL .1,.2,.3,.4,.5,.6,.7.,.8,.9
  global DB_prob=.5
  window control scombo DB_probL 60 25 25 60 DB_prob parse(,)

  global temp3 "N per sample="
  window control static temp3  5 40 45 10
  global DB_nL 1,5,10,15,20,25,30,35,40,45,50,75,100,150,200
  global DB_n=1
  window control scombo DB_nL 60 40 25 60 DB_n parse(,)

  global temp4 "# of Samples="
  window control static temp4  5 55 45 10
  global DB_sampL 100,500,1000,2000,3000,5000,10000
  global DB_samp=1000
  window control scombo DB_sampL 60 55 35 60 DB_samp parse(,)

  global DB_norm 0
  window control check "Show Normal Overlay" 5 70 80 10 DB_norm

  global DB_sdl 0
  window control check "Draw lines at +-1SD and +-2SD" 5 80 110 10 DB_sdl

  global DB_z 0
  window control check "Show means as Z scores" 5 90 90 10 DB_z

  global DB_sum 0
  window control check "Show sums instead of means" 5 100 100 10 DB_sum

  * global DB_build 0
  * window control check "Show distribution being built" 5 120 100 10 DB_build

  * global temp5 "Samples per step="
  * window control static temp5  10 135 60 10
  * global DB_stepL 1,5,10,20,30,40,50
  * global DB_step=10
  * window control scombo DB_stepL 80 135 25 60 DB_step parse(,)

  * global temp6 "Delay between steps="
  * window control static temp6  10 150 70 10
  * global DB_slpL 0,.1,.2,.3,.4,.5,.6,.7,.8,.9,.1
  * global DB_slp=.1
  * window control scombo DB_slpL 80 150 25 60 DB_slp parse(,)

  global DB_doclt "_doclt"
  window control button "Show" 5 120 25 10 DB_doclt

  global DB_done "quietly exit 3000"
  window control button "Done" 45 120 30 10 DB_done escape

  global DB_help "_help"
  window control button "Help" 90 120 30 10 DB_help

  window dialog "Central Limit Theorem" . .  130 150
  window dialog update

end

capture program drop _help
program define _help
  whelp clt
end


capture program drop _doclt
program define _doclt
  local opts ""
  if $DB_norm {
    local opts "`opts' normal"
  }
  if $DB_sdl {
    local opts "`opts' sdline"
  }
  if $DB_z {
    local opts "`opts' z"
  }
  if $DB_sum {
    local opts "`opts' sum"
  }

  * if $DB_build {
  *   local sleep = $DB_slp*100
  *   local opts "`opts' build sleep(`sleep') step($DB_step)"
  * }
  _clt , samples($DB_samp) n($DB_n) dist($DB_dist) p($DB_prob) `opts'
end


capture program drop _clt
program define _clt
  version 6.0
  * build step sleep and sum options below
  syntax [ , BUild STep(integer 10) SLeep(integer 100) SUM /*
            */ N(integer 30) Samples(integer 5000) Dist(string) P(real .5) /*
            */ Z  Normal SDLIne SDLAbel Bin(integer 50) SAving(string) /*
            */ TOpcode(real 99999) BOtcode(real -99999) *]

  preserve
  * clear
  drop _all // mnm changed
  global Samp_N = `n'
  simul cltsamp, reps(`samples') args("`dist' `p'") 

  * sum & z option below
  if "`sum'" != "" {
    quietly replace mean = sum
  }
  if "`z'" != "" {
    egen zmean = std(mean)
    quietly replace mean = zmean
  }

  qui replace mean = `topcode' if mean > `topcode'
  qui replace mean = `botcode' if mean < `botcode'
  
  quietly summarize mean
  local xmax = string(r(max),"%7.3f")
  local xmin = string(r(min),"%7.3f")
  local xmean = string(r(mean),"%7.3f")
  local xsd = string(r(sd),"%7.3f")
  local x1u = string(r(mean)+1*r(sd),"%7.3f")
  local x2u = string(r(mean)+2*r(sd),"%7.3f")
  local x1d = string(r(mean)-1*r(sd),"%7.3f")
  local x2d = string(r(mean)-2*r(sd),"%7.3f")

  local saveopt = ""
  if "`saving'" != "" {
    local saveopt = `" saving("`saving'",replace) "'
  }

  if "`dist'" == "Binomial" {
    local distx = "Binomial" 
    quietly summarize sum
    local bin = round( (r(max)-r(min)+1), 1)
    if `bin' > 50 {
      * bin option here
      local bin = int(`bin'/2)+1
      display "Graph required over 50 bins, so `bin' bins are used."
      display "Graph may look lousy"
    }
  }
  else if "`dist'" == "Exponential" {
    local distx = "Exponential" 
  }
  else if "`dist'" == "ExpNormal" {
    local distx = "ExpNormal" 
  }
  else if "`dist'" == "Log" {
    local distx = "Log" 
  }
  else if "`dist'" == "LogNormal" {
    local distx = "LogNormal" 
  }
  else if "`dist'" == "Uniform" {
    local distx = "Uniform" 
  }
  else if "`dist'" == "Bimodal" {
    local distx = "Bimodal" 
  }
  else {
    local dist = "Normal"
    local distx = "Normal" 
  } 

  if "`sdline'" != "" {
    local sdline "xline(`x2d' `x1d' `xmean' `x1u' `x2u')"
    local sdlin2 "Lines drawn at -2sd -1sd mean +1sd +2sd"
  }

  local xlab "Sample Mean"
  if "`z'" != "" {
    local xlab "Sample Value (Z Score)"
  }
  if "`sum'" != "" {
    local xlab "Sample Value (Sum)"
  }

  if "`sdlabel'" != "" {
    local sdlabel "xlabel(`x2d' `x1d' `xmean' `x1u' `x2u')"
    local b2 "-2sd, -1sd, mean, +1sd, +2sd"
    local b1 "`xlab'"
  }
  else {
    local b2 "`xlab'"
    local b1 ""
  }

  if ("`dist'" == "Binomial") {
    * local t1 "Samples=`samples', Population=`distx', N=`n' P=`p', Mean=`xmean' & SD=`xsd'"
    local t1 "Samples=`samples', Population=`distx', N=`n' P=`p'"
  }
  else {
    * local t1 "Samples=`samples', Population=`distx', N=`n', Mean=`xmean', & SD=`xsd'"
    local t1 "Samples=`samples', Population=`distx', N=`n'"
  }

  * define build options here
  if "`build'" != "" {
    local step2 = `step'*2
    local sample1 = `samples'/2

    local for "qui for num `step'(`step')`sample1' `sample1'(`step2')`samples' :"
    local in  "in 1/X"
    local sl " \ sleep `sleep'" 
    local t1 = "`t1' Sample #=X"
  }

  qui replace mean = `xmax' in 1
  qui replace mean = `xmin' in 2

  * for in and sleep below.
  * set trace on
  * pause on
  * pause 
  * display "bin is `bin'"
  * display "t1 is `t1'"
  #delimit ;
  * `for' graph mean `in', 
        `normal' bin(`bin') /* freq */  `saveopt'
        t1("`t1'")
        t2("`sdlin2'") 
        b1("`b1'")
        b2("`b2'")
        l1("Frequency") 
        `sdline' `sdlabel'
        `options'
        `sl'
    ;
  #delimit ;
  version 8.2: quietly `for' histogram mean `in', 
         bfcolor(teal) blcolor(edkblue) 
        `normal' bin(`bin') `saveopt'
        title("`t1'")
        subtitle("`sdlin2'") 
        xtitle("`b1'")
        ytitle("Fraction") 
        `sdline' `sdlabel' `options' `sl'
    ;
#delimit cr
  restore
end
