*! Version 1.1 6/16/03, mnm : Does not rename graphs with do2htm to avoid running out of sersets
*! Version 1  4/23/03, mnm : Added options to work with do2htm
*! Version .7 4/7/03, mnm
capture program drop grss
program define grss
  version 8

  if `"`0'"' == `""' {
    if ("$grss_graphnum" == "" ) {
      display as error "No graphs to display"
      display as text "To learn how to use grss type " as command "help grss"
      exit
    }
    grss_dlg
    exit
  }

  if `"`0'"' == `"clear"' {
    * display "going to clear"
    grss_clear
    exit
  }

  * display "Must be a graph command"
  * must be a graph command, pass it thru
  if ("$grss_graphnum" == "" ) {
    * first time invoking this session

    * clear out old graphs (dont need this now that we are using temp graphs in memory)
    **************** grss_clear
    *  set graphnum to 0
    global grss_graphnum = 0
  }
  capture graph drop Graph
  capture quietly `0' 
  local rc1 = _rc
  capture graph describe Graph
  local rc2 = _rc
  if (`rc1' == 0 & `rc2' == 0) {
    global grss_graphnum = $grss_graphnum + 1 
    if "$grss_png" != "" {
      quietly graph export $grss_png$grss_graphnum.png , as(png) replace
      if ("$grss_log2htm"=="") display "Saved graph as $grss_png$grss_graphnum.png"
    }
    if ("$grss_log2htm"=="") {
      capture quietly graph rename Graph grss_graph$grss_graphnum, replace 
      display "Saved graph #$grss_graphnum from command "
      display as command `". `0'"' 
    }
    else {
      display "#grssbefore#'$grss_png$grss_graphnum.png'#grssafter#"
    }
    global grss_graphcmd$grss_graphnum `"`0'"'
  }
  else {
    if (`rc1' != 0) {
      display as error "Error number " `rc1' " was returned from graph command" 
      exit `rc1'
    }
    else if (`rc2' != 0) {
      display as text "Graph was not created from command " as command "`0'"
    }
  }
end

capture program drop grss_clear
program define grss_clear
  version 8
  display "Erasing temporary graphs and clearing out graph slide show"
  if "$grss_graphnum" != "" {
    local i = 1
    while (`i' <= $grss_graphnum) {
      capture graph drop grss_graph`i'
      local i = `i' + 1
    }
  }
  global grss_graphnum 
end

capture program drop grss_dlg
program define grss_dlg
  version 8

  global grss_curgraphnum = 1
  grss_show $grss_curgraphnum
  window manage forward dialog

  global grss_message = "Showing Graph $grss_curgraphnum of $grss_graphnum"
  window control static grss_message  10 5 80 10 

  window control static grss_message2 10 15 120 20 

  global grss_DBprev "grss_prev"
  window control button "Prev Graph" 10 40 50 10 grss_DBprev

  global grss_DBnext "grss_next"
  window control button "Next Graph" 70 40 50 10 grss_DBnext

  global grss_DBdone "quietly exit 3000"
  window control button "Done"       40 55 40 10 grss_DBdone escape

  window dialog "Graph Slide Show" . .  140 85
  window dialog update

end

capture program drop grss_show
program define grss_show
  version 8
  args curgraphnum

  if (`curgraphnum' < 0) | (`curgraphnum' > $grss_graphnum) {
    display "graph number out of range"
    exit 9999
  }

  global grss_curgraphnum = `curgraphnum'
  * display "Showing graph # $grss_curgraphnum"
  * display `"${grss_graphcmd`curgraphnum'}"'
  graph display grss_graph$grss_curgraphnum

  global grss_message = "Showing Graph $grss_curgraphnum of $grss_graphnum"
  * global grss_message2 = substr(`"${grss_graphcmd`curgraphnum'}"',1,100)
  global grss_message2 = `"${grss_graphcmd`curgraphnum'}"'

end

capture program drop grss_next
program define grss_next
  version 8
  global grss_curgraphnum = $grss_curgraphnum + 1
  if ($grss_curgraphnum > $grss_graphnum) {
    global grss_curgraphnum = 1
  }
  grss_show $grss_curgraphnum
end

capture program drop grss_prev
program define grss_prev
  version 8

  global grss_curgraphnum = $grss_curgraphnum - 1
  if ($grss_curgraphnum <= 0) {
    global grss_curgraphnum = $grss_graphnum
  }

  grss_show $grss_curgraphnum

end


