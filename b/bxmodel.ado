*! version 1.2 bug fixes 1/31/06
*! version 1.1 add bxbw
*! version 1.0 for OS X 5/15/02
*! version 0.6   9/19/00

program define bxmodel
  version 6.0
/*  global DB_reps = 100
     global DB_n = 1 
     global DB_fnam  "" */

* frame with title
  global DB_rad "Type of Box Model"
  window control static DB_rad  5 50 190 75 blackframe
  window control static DB_rad 30 57 135 12 center
  
/*window control static DB_rad  5 60 130 45 blackframe
  window control static DB_rad 27 57  80 12 center */

* radio button group defaults to option 1
  global DB_rval = 1
  window control radbegin "Sum, mean, sd - w/  replacement"    10  67 150 15 DB_rval
  window control radio        "Sum, mean, sd - w/o replacement"   10  81 150 15 DB_rval
  window control radio        "Birthday - w/ replacement"               10  95 150 15 DB_rval
  window control radend     "Birthday - w/o replacement"             10 109 150 15 DB_rval

* file name, if any
  global DB_name "Enter file name:"
  window control static DB_name  10 5 80 9
  window control edit 10 15 80 10 DB_fnam

  global DB_n1 "Number:"
  window control static DB_n1  10 34 29 10
  window control edit          40 32 15 10 DB_n
/*window control static DB_n1  10 37 60 10
  window control edit          40 35 15 10 DB_n */

  global DB_t1      "Repetitions:"
  window control static DB_t1 10 145 35 10
  window control edit         50 143 20 10 DB_reps
/*window control static DB_t1 10 115 60 10
  window control edit         50 113 20 10 DB_reps */

  global DB_doit   "exit 3010"
  window control button "Do It"     45 170 40 10 DB_doit default
/*window control button "Do It"     10 130 40 10 DB_doit default */

  global DB_can    "exit 3000"
  window control button "Cancel"    115 170 40 10 DB_can 
  /* window control button "Cancel"    70 130 40 10 DB_can */

  capture noisily window dialog "Box Model Program" . . 200 200 /* 150 160 */

  if  _rc  ==  3010  {
    display

    if $DB_rval == 1 {
      display "bx1 using $DB_fnam , draw($DB_n)  reps($DB_reps)"
      bx1 using $DB_fnam  , draw($DB_n)  reps($DB_reps)
      display
    }
    
    if $DB_rval == 2 {
      display "bx1s using $DB_fnam , draw($DB_n)  reps($DB_reps)"
      bx1s using $DB_fnam  , draw($DB_n)  reps($DB_reps)
      display
    }

    if $DB_rval == 3 {
      display "bxb using $DB_fnam , draw($DB_n)  reps($DB_reps)"
      bxb using $DB_fnam  , draw($DB_n)  reps($DB_reps)
      display
    }

    if $DB_rval == 4 {
      display "bxbw using $DB_fnam , draw($DB_n)  reps($DB_reps)"
      bxbw using $DB_fnam  , draw($DB_n)  reps($DB_reps)
      display
    }
  }

end

