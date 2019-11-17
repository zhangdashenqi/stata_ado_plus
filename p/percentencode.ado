program define percentencode, rclass
mata: st_local("percentencode", percentencode(`"`1'"'))
return local percentencode "`percentencode'"
di "`percentencode'"
end
mata:
string scalar percentencode(string scalar s){
  lc = "abcdefghijklmnopqrstuvwxyz"
  uc = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
  no = "1234567890"
  re = "-._~"
  str = lc + uc + no + re
  asc = ascii(s)'
  sel = rowmax(asc :== J(rows(asc), 1, ascii(str)))
  chr = sel:* strofreal(asc)
  enc = !sel :* ("%" :+ inbase(16, asc))
  final = strupper(chr :+ enc)
  for(i=1; i<=rows(final); i++) {
    if (substr(final[i], 1, 1)!="%") {
      final[i] = char(strtoreal(final[i]))
    }
  }
  return (invtokens(final', ""))
}
end
