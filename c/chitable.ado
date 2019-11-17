*! version 1.0.0 27apr00
program define chitable
  version 6.0
  display
  display in green "        Critical Values of Chi-square"
  display in green " df     .50     .25     .10     .05    .025      .01     .001"
  if "`1'"~="" { tdisp `1' }
  else {
    local i = 1
    while `i'<=30 {
      tdisp `i'
      local i = `i' + 1
    }
    local i = 35
    while `i'<=100 {
      tdisp `i'
      local i = `i' + 5
    }
  }
end

program define tdisp
  display %3.0f `1' "  " %6.2f invchi(`1',.50) "  " %6.2f invchi(`1',.25) "  " /*
    */ %6.2f invchi(`1',.10) "  " in green %6.2f invchi(`1',.05)  /*
    */ "  " in yellow %6.2f invchi(`1',.025) /*
    */ "  " %7.2f invchi(`1',.01) "  " %7.2f invchi(`1',.001)
end
