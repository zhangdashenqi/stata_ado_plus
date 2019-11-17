*! revised 6/20/01
capture program drop pwrdemo2
program define pwrdemo2
  version 6.0
  syntax [, N(integer 25) Diff(real .25) Alpha(real 0.05) t1(string) t2(string) l1(string) NODialog *]

  global N = `n'
  global DIFF = `diff'
  global ALPHA = `alpha'
  global T1 = "`t1'"
  global T2 = "`t2'"
  global L1 = "`l1'"

  preserve
  drop _all
  _mkgr
  if "`nodialog'" == "" {
    _dbox
  }
end

capture program drop _mkgr
program define _mkgr
  quietly {
    drop _all
    range x -1 1 200

    local se = (1 / ($N ^.5))
    local alpha2 = $ALPHA / 2

    if `"$T1"'=="" {
      local t1 "Ho=Left Curve, Ha=Right Curve, Area to right of line=Power"
    }
    if `"$T2"'=="" {
      local t2 = "N = " + string($N) + " diff = " + string($DIFF) + " alpha = " + string($ALPHA) 
    }
    if `"$L1"'=="" {
      local l1 = "."
    }

    scalar z = invnorm(1.0 - (`alpha2'))
    scalar zcrit = z*(`se')
    scalar zpow = (zcrit - $DIFF) / `se'
    scalar power = round(  1 - normprob(zpow) , 0.01)
  
    generate y1 = (1 /(`se'*sqrt(2*_pi))) * exp( -1*( (x-     0)^2 ) / (2*`se'^2) )
    generate y2 = (1 /(`se'*sqrt(2*_pi))) * exp( -1*( (x-$DIFF)^2 ) / (2*`se'^2) )
    generate y3 = y2 if x>zcrit
  
    local b1 = "b1title( Power = " + string(power) + " )"
    local xl = "xline( 0 " + string($DIFF) + " " +  string(zcrit-.004) + " " +  string(zcrit-.002) + " " +  string(zcrit) + " " +  string(zcrit+.002) + " " +  string(zcrit+.004) + ")"
    graph y1 y2 y3 x, s(iiO) c(lll) yline(0) noaxis ylabel(0) xlabel(-1.0 -.5 to 1)  xscale(-1.2,1.2) `xl' `b1' t1title("`t1'") t2title("`t2'") l1title("`l1'") `options'
  }
end

capture program drop _dbox
program define _dbox
  global DB_done "quietly exit 3000"

  * adjust N
  global DB_nmin  "_chn -1"
  global DB_nplus "_chn  1"
  window control button "N - 1"             5  10 35 10 DB_nmin
  window control button "N + 1"             45 10 35 10 DB_nplus

  * adjust diff
  global DB_dmin  "_chd -.01"
  global DB_dplus "_chd  .01"
  window control button "diff - .01"         5  25 35 10 DB_dmin
  window control button "diff + .01"         45 25 35 10 DB_dplus

  * adjust alpha
  global DB_amin  "_cha -.01"
  global DB_aplus "_cha  .01"
  window control button "alpha - .01"         5  40 35 10 DB_amin
  window control button "alpha + .01"         45 40 35 10 DB_aplus

  global DB_animn "_animn"
  window control button "Movie Varying N"     5 60 75 10 DB_animn

  global DB_animd "_animd"
  window control button "Movie Varying Diff"  5 75 75 10 DB_animd

  global DB_anima "_anima"
  window control button "Movie Varying Alpha" 5 90 75 10 DB_anima


  global DB_xxx = "movie delay="
  window control static DB_xxx      9 105 45 10 
  global DB_slpL 0,.1,.2,.3,.4,.5
  global DB_slp = .1
  window control scombo DB_slpL     55 105 25 40 DB_slp parse(,)

  window control button "Done"      5 125 75 10 DB_done
  window dialog "Power Demo" . . 90 150
end

capture program drop _chn
program define _chn
  global N = $N + `1'
  if $N < 1 { 
    global N = 1
  }
  _mkgr
end

capture program drop _chd
program define _chd
  global DIFF = $DIFF + `1'
  if $DIFF < 0 { 
    global DIFF = 0
  }
  _mkgr
end

capture program drop _cha
program define _cha
  global ALPHA = $ALPHA + `1'
  if $ALPHA <= 0.01 { 
    global ALPHA = 0.01
  }
  _mkgr
end


capture program drop _animn
program define _animn
  global N = 5
  while $N < 30 {
    global N = $N + 1
    _mkgr
    local slp = $DB_slp*1000
    sleep `slp'
  }
end

capture program drop _animd
program define _animd
  global DIFF = 0
  while $DIFF < .30 {
    global DIFF = $DIFF + .01
    _mkgr
    local slp = $DB_slp*1000
    sleep `slp'
  }
end

capture program drop _anima
program define _anima
  global ALPHA = 0.01
  while $ALPHA < .20 {
    global ALPHA = $ALPHA + .01
    _mkgr
    local slp = $DB_slp*1000
    sleep `slp'
  }
end
