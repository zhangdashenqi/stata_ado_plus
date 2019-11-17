*! revised to remove clear for better animation, 1/24/04, mnm
*! revised 6/20/01
capture program drop sdmdemo
program define sdmdemo
  version 6.0
  
  if "`1'" == "" {
    global DB_n = 1
  } 
  else {
    global DB_n = `1'
  }

  preserve
  _mkgr
  _dbox
end

capture program drop _mkgr
program define _mkgr
  quietly {
    * clear
    drop _all // mnm changed
    range x -3 3 200
    generate se = $DB_n
    replace se = 1/sqrt(se)
    generate y1 = (1/sqrt(2*_pi))*exp(-.5*x^2)
    generate y2 = (1/(se*sqrt(2*_pi)))*exp(-.5*(x^2/se))
    graph y1 y2 x, noaxis s(ii) c(ll) pen(2) /*
        */ xline(0) xlabel(-3 -2 to 3) /*
        */ yline(0) ylabel(0 1 to 3) /*
        */ t1("n = 1 in yellow -- n = $DB_n in red")
  }
end

capture program drop _dbox
program define _dbox

  global DB_xplus "_chn 1"
  window control button "N + 1"         10 10 50 10 DB_xplus

  global DB_xmin  "_chn -1"
  window control button "N - 1"         10 25 50 10 DB_xmin

  global DB_anim "_anim"
  window control button "Show Movie"     10 40 50 10 DB_anim

  global DB_xxx = "delay="
  window control static DB_xxx      10 50 20 10 

  global DB_slpL 0,.1,.2,.3,.4,.5
  global DB_slp = .1
  window control scombo DB_slpL     30 50 25 40 DB_slp parse(,)

  global DB_done "quietly exit 3000"
  window control button "Done"      10 70 50 10 DB_done

  window dialog "Smp. Dst. Mean" . . 80 100
end

capture program drop _chn
program define _chn
  global DB_n = $DB_n + `1'
  if $DB_n < 1 { 
    global DB_n = 1
  }
  _mkgr
  window manage forward dialog
end


capture program drop _anim
program define _anim
  global DB_n = 0
  while $DB_n < 25 {
    global DB_n = $DB_n + 1
    _mkgr
    local slp = $DB_slp*100
    sleep `slp'
  }
  window manage forward dialog
end
