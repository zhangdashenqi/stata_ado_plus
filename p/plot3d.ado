program define plot3d
version 2.1
   mac def x_number=25
   mac def x_min=0
   mac def x_max=5
   mac def y_number=25
   mac def y_min=0
   mac def y_max=5
   mac def _totaant=%x_number*%y_number
   set obs %_totaant
   gen x=int((_n-1)/%x_number)*(%x_max-%x_min)/(%x_number-1)+%x_min
   gen y=((%y_max-%y_min)/(%y_number-1))*mod(_n-1,%y_number)+%y_min
   gen z=%_*
   mac def _alpha=2*_pi/3
   gen X_PLOT = y-x*cos(%_alpha)
   gen Y_PLOT = z-x*sin(%_alpha)
   qui summ Y_PLOT
   mac def Y_MIN = _result(5)
   mac def Y_MAX = 2 *(_result(6)-_result(5)) + _result(5)
   qui summ X_PLOT
   mac def X_MIN = _result(5)
   mac def X_MAX = _result(6)
   set graph off
   #delimit ;
   graph Y_PLOT X_PLOT, c(L) s(.) noaxis l1ti(" ") b2ti(" ") 
      xlab(%X_MIN,%X_MAX) ylab(%Y_MIN,%Y_MAX) saving(pl1,replace) ;
   sort y x ;
   graph Y_PLOT X_PLOT, c(L) s(.) noaxis l1ti(" ") b2ti(" ")
      xlab(%X_MIN,%X_MAX) ylab(%Y_MIN,%Y_MAX) saving(pl2,replace) ;
   #delimit cr
   drop _all
   !copy stage.prf stage.old > nul
   !copy plot3d.prf stage.prf > nul
   stage
   !copy stage.old stage.prf > nul
   set graph on
   graph using pl3, ti("z = %_*") saving(pl4,replace)
end

