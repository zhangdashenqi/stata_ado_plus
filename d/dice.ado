*! mnm changed clear to drop _all, put back in animation, 1/24/03
*! revised 6/25/01
capture program drop dice
program define dice
  version 6.0

  global DB_rolls = 100
  global DB_dice = 2
  global DB_sides = 6
  global DB_anim = 0
  global DB_slp = 0

  preserve
  _mkgr
  _dbox

end

capture program drop _mkgr
program define _mkgr
  version 6.0
  * clear
  drop _all // mnm changed to drop _all
  quietly set obs $DB_rolls
  quietly generate trials = _n
  quietly generate sumdice = 0
  local dicei = 1
  while (`dicei' <= $DB_dice) {
    quietly replace sumdice = sumdice + int(uniform()*$DB_sides + 1) 
    local dicei = `dicei' + 1
  }
  if ($DB_dice == 1) {
    label variable sumdice "Number shown on die with $DB_sides sides"
  }
  else {
    label variable sumdice "Total of $DB_dice dice with $DB_sides sides"
  }
  label variable trials  "Number of trials (rolls)"
  quietly summarize sumdice
  * local dicemin = `r(min)'
  * local dicemax = `r(max)'
  local dicemin = $DB_dice
  local dicemax = $DB_dice*$DB_sides
  local dicemi2 = $DB_dice*2

  local bins = min(`dicemax'-`dicemin'+1,50)

  if ((`dicemax' - `dicemin') == 1) | (`dicemi2' >= `dicemax') {
    local xlab = "`dicemin' `dicemax'"
  }
  else {
    local xlab = "`dicemin' `dicemi2' to `dicemax'"
  }

  if $DB_anim {
    preserve
    contract sumdice
    quietly summarize _freq
    local ymax = `r(max)'
    restore
    local slp = $DB_slp*100
    * noisily display "xlabel is `xlab'"
    quietly for num 1 (1) $DB_rolls: graph s in 1/X, histogram bin(`bins') xlabel(`xlab') freq  ylabel(0 `ymax') \ sleep `slp'
  }
  else {
    * noisily display "xlabel is `xlab'"
    graph s, histogram bin(`bins') xlabel(`xlab') 
  }
end


capture program drop _dbox
program define _dbox
  global DB_msg1 = "Number rolls"
  window control static DB_msg1      5 10 40 10 
  global DB_rollsL 1,5,10,15,20,25,30,40,50,60,70,80,90,100,200,300,500,1000
  window control scombo DB_rollsL     50 10 30 40 DB_rolls parse(,)

  global DB_msg2 = "Number Dice"
  window control static DB_msg2      5 25 40 10 
  global DB_diceL 1,2,3,4,5,6,7,8,9,10
  window control scombo DB_diceL     50 25 30 40 DB_dice parse(,)

  global DB_msg3 = "Sides per die"
  window control static DB_msg3      5 40 40 10 
  global DB_sidesL 2,3,4,5,6,7,8,9,10
  window control scombo DB_sidesL    50 40 30 40 DB_sides parse(,)


  window control check "animate dice rolls" 5 60 100 10 DB_anim

  global DB_msg4 = "with delay="
  window control static DB_msg4      5 70 40 10 
  global DB_slpL 0,.1,.2,.3,.4,.5
  window control scombo DB_slpL     50 70 25 40 DB_slp parse(,)



  global DB_roll "_mkgr"
  window control button "Roll Dice"               10 90 50 10 DB_roll

  global DB_done "quietly exit 3000"
  window control button "Done"      10 110 50 10 DB_done

  window dialog "Dice Rolling Demo" . . 85 140
end


capture program drop _anim
program define _anim
  global demodf = 0
  while $demodf < 30 {
    global demodf = $demodf + 1
    _mkdata
    _grdisp
    local slp = $DB_slp*1000
    sleep `slp'
  }
  window manage forward dialog
end
