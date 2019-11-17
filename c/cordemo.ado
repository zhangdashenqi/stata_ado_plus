*! version 1.1 revised 11/7/03
capture program drop cordemo
program define cordemo
  version 6.0
  args corr n

  if "`corr'" == "" {
    global demor = 0
  } 
  else { global demor = `corr' }

  if "`n'" == "" {
    global demon = 100
  }
  else { global demon = `n' }
  preserve
  
  _mkdata
  _grdisp
  _dbox

end

capture program drop _mkdata
program define _mkdata
  clear 
  quietly {
    set obs $demon
    generate y = invnorm(uniform())*4.4 + 55
    generate z = invnorm(uniform())*4.4 + 55
    generate x = sqrt(1 - ($demor)^2)*z + $demor*y
    egen w = std(x)
    replace x = w*4.4 + 55
    regress y x
    predict yhat
  }
end

capture program drop _grdisp
program define _grdisp
  local corr = string($demor, "%4.1f")
  graph y yhat x, s(oi) c(.l) ylabel(40 45 to 70) xlabel(40 45 to 70) /*
         */ t1(" r = `corr'  n = $demon") sort
end

capture program drop _dbox
program define _dbox
  global DB_rplus "_chr  .1"
  global DB_rmin  "_chr -.1"
  global DB_redo  "_redo"
  global DB_anim  "_anim"
  global DB_done  "_done"

  window control button "r + .1"         10   5 50 10 DB_rplus
  window control button "r - .1"         10  20 50 10 DB_rmin
  window control button "Redisplay"      10  54 50 10 DB_redo
  window control button "Show Movie"     10  71 50 10 DB_anim
  window control button "Done"           10 105 50 10 DB_done

  global DB_nnn = "n ="
  window control static DB_nnn      13 36 15 10 

  global DB_chnL 25,50,100,200,500,1000
  global demon = $demon
  window control scombo DB_chnL     35 35 30 40 demon parse(,)

  global DB_xxx = "delay ="
  window control static DB_xxx      10 89 25 10 

  global DB_slpL 0,.1,.2,.3,.4,.5
  global DB_slp = .0
  window control scombo DB_slpL     37 87 27 40 DB_slp parse(,)

  window dialog "cordemo" . . 80 130
end

capture program drop _done
program define _done
  macro drop DB_*
  macro drop demo*
  quietly exit 3000
end

capture program drop _redo
program define _redo
  _mkdata
  _grdisp
end

capture program drop _anim
program define _anim
  local slp = $DB_slp*1000
  global demor = -1
  _mkdata
  _grdisp
  sleep `slp'
  global demor = $demor + 0.1
  while $demor < 1 {
    _chdata
    _grdisp
    sleep `slp'
    global demor = $demor + 0.1
  }
end

capture program drop _chr
program define _chr
  global demor = $demor + `1'
  if $demor < -1 { 
    global demor = -1
  }
  if $demor > 1 { 
    global demor = 1
  }
  _chdata
  _grdisp
end

capture program drop _chdata
program define _chdata
  quietly {
    drop x w 
    capture drop yhat
    generate x = sqrt(1 - ($demor)^2)*z + $demor*y
    egen w = std(x)
    replace x = w*4.4 + 55
    regress y x
    predict yhat
  }
end

