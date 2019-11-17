program define cards
  version 7.0
  preserve
  clear
  set more off

  display
  label define cl 2 "2" 3 "3" 4 "4" 5 "5" 6 "6" 7 "7" 8 "8" /*
               */ 9 "9" 10 "10" 11 "Jack"  12 "Queen" 13 "King" 14 "ACE"
  label define sl 1 "of Spades  " 2 "of Diamonds" 3 "of Hearts  " 4 "of Clubs   "

  quietly set obs 52
  generate card = mod(_n, 13) + 2
  generate value = card
  quietly replace  value = 10 if card==11 | card==12 | card==13
  quietly replace  value = 11 if card==14
  sort card
  generate suit = mod(_n, 4) + 1
  label value card cl
  label value suit sl
  sort value suit
  generate isace = value==11 
  global DB_num  = 5
  global DB_wor  = 1
  quietly capture list card suit, noheader clean
  if _rc~=0 {
    display as error "Your copy Stata is not up-to-date."
    display as error "The cards command requires you update Stata."
    display as txt "Type the command: " as res "update, all" as txt /*
            */ " to obtain the latest version."
    exit 3000
  }
  _shuffle
  _dbox
end  

capture program drop _shuffle
program define _shuffle
  tempvar v
  generate `v' = uniform()
  sort `v'
  drop `v'

  global DB_indx = 0
  global DB_bj1  = 0
  global DB_bj2  = 0

end

capture program drop _dbox
program define _dbox
  global DB_draw "_draw"
  global DB_done "_done"
  global DB_shuf "_shuffle"
  global DB_bjk  "_blkjk"
  global DB_hit  "_hitme"
  global DB_sta  "_stand"

  window control button "Shuffle"        12  5 50 10 DB_shuf
  window control button "Draw"           12 20 50 10 DB_draw
  global DB_nnn = "n ="
  window control static DB_nnn      10 37 15 10
  global DB_numL 1,2,3,4,5,7,13
  global DB_num = $DB_num
  window control scombo DB_numL     29 36 32 40 DB_num parse(,)

  global DB_wor = 1
  window control radbegin "w/o replacement" 5 48 65 15 DB_wor
  window control radend   "w/  replacement" 5 60 65 15 DB_wor
  window control button "Blackjack"         7 80 62 10 DB_bjk
  window control button "Hit Me"            5 95 32 11 DB_hit
  window control button "Stand "           41 95 30 11 DB_sta

  window control button "Done"           10 110 50 10 DB_done

  window dialog "cards" . . 80 135
end

capture program drop _done
program define _done
  macro drop DB_*
  set more on
  quietly exit 3000
end

capture program drop _draw
program define _draw
  if $DB_wor==1 { _dwor $DB_num }
  else { _drawr $DB_num }
end

capture program drop _drawr
program define _drawr

  local i = 1
  while `i' <= `1' {
    _shuffle
    list card suit in 1, noobs nohead clean
    local i = `i' + 1
  }
  display
end


capture program drop _dwor
program define _dwor
  if `1' < 1  {
    display as txt "You can't draw less than 1 card."
    display
    exit
  }
  if `1' > 52 {
    display as txt "You can't draw more than 52 cards."
    display
    exit
  }
  local begin = $DB_indx + 1
  local   end = $DB_indx + $DB_num
  if `end' > 52 {
    display as txt "Not enough cards left to finish deal."
    display as txt "Shuffle again.
  }
  else {
    list card suit in `begin' / `end' , noobs noheader clean
    global DB_indx = `end'
  } 
  display
end 

capture program drop _blkjk
program define _blkjk

  local one = $DB_indx + 1
  local two = $DB_indx + 2
  if `two' >= 52 {
    _shuffle
    local one = 1
    local two = 2
  }
  display as txt "Blackjack"
  display as txt "You draw 
  list card suit in `one', noobs nohead clean
  list card suit in `two', noobs nohead clean

  local total = value[`one'] + value[`two'] 
  local aces = isace[`one'] + isace[`two']
  if `total' == 22 {
    local total = `total' - 10
    local aces  = 1
  }
  display as txt "Your total is " `total'
  if `total' == 21 {
    display as txt "Blackjack, you win"
  }
  display
  global DB_indx = `two'
  global DB_bj1   = `total'
  global DB_bj2   = `aces' 
end 

capture program drop _hitme
program define _hitme

  local one   = $DB_indx + 1
  local value = $DB_bj1
  local aces  = $DB_bj2
  if `one' >= 52 {
    display as txt "Shuffling ..."
    _shuffle
    local one = 1
  }
  local value = `value' + value[`one']
  local aces  = `aces' + isace[`one']
  while `value' > 21 & `aces' > 0 {
    local value = `value' - 10
    local aces  = `aces' - 1
  }
  display as txt "Your card is " 
  list card suit in `one', noobs noheader clean
  display as txt "Your total is " `value'
  if `value' > 21 & `aces' == 0 {
    display as txt "You lose."
  }
    display
    global DB_indx = `one'
    global DB_bj1   = `value'
    global DB_bj2   = `aces'
end  

capture program drop _stand
program define _stand
  local one   = $DB_indx + 1
  local two   = $DB_indx + 2
  local you   = $DB_bj1
  if `two' >= 52 {
    display as txt "Shuffling ..."
    _shuffle
    local one = 1
    local two = 2
  }
  local dealer = value[`one'] + value[`two']
  local aces   = isace[`one'] + isace[`two']
  display as txt "Dealer draws " 
  list card suit in `one', noobs noheader clean
  list card suit in `two', noobs noheader clean
  local index = `two' + 1
  while `dealer' < 17 {
    local dealer = `dealer' + value[`index']
    local `aces' = `aces'   + isace[`index']
    list card suit in `index', noobs noheader clean
    if `dealer' >21 & `aces'>0 { 
      local dealer = `dealer' - 10
      local aces = `aces' - 1
    }
    local index = `index' + 1
    if `index' >= 52 {
      display as txt "Shuffling ..."
      _shuffle
      local `index' = 1
    }
  }
  display as txt "Dealer's total is " `dealer'
  if `dealer' > `you' & `dealer' <= 21 {
    display as txt "Dealer wins"
  }
  if `dealer' < `you' {
    display as txt "You win"
  }
  if `dealer' == `you' {
    display as txt "Push"
  }
  if `dealer' > 21 {
    display as txt "Dealer bust, you win."
  } 
    display
    global DB_indx  = `index'
    global DB_bj1   = 0
    global DB_bj2   = 0
end  

