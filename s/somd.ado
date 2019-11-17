program define somd, rclass
  quietly {
    count if `1' != .
    local n=r(N)
    sum `1' if `2'==`3', meanonly
    local y1=r(mean)
    sum `1' if `2'==`4', meanonly
    local y2=r(mean)
    local d=(2/`n')*(`y2'-`y1')
  }
  return scalar d = `d'
end

