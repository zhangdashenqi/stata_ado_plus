version 9.0
mata
void tidotforsomersd(string scalar tidotv, string scalar tousev, string scalar bygpv,
  string scalar xv, string scalar yv,
  string scalar weightv, string scalar xcenv, string scalar ycenv,
  real scalar tree)
{
/*
  Return weighted concordance-discordance difference counts (calculated using tidot)
  in a named concordance-discordance counts variable,
  between a named X-variable and a named Y-variable (both possibly censored),
  restricted to observations with a nonzero value of a named to-use variable,
  within by-groups defined by a named by-group variable,
  selecting observations with a nonzero value for a to-use variable.
  tidotv is the concordance-discordance count variable name.
  tousev is the to-use variable name.
  bygpv is the by-group variable name.
  xv is the X-variable name.
  yv is the Y-variable name.
  weightv is the weight variable name.
  xcenv is the x-variable censoring indicator variable name.
  ycenv is the y-variable censoring indicator variable name.
  tree is indicator that the search tree algorithm should be used.
*! Author: Roger Newson
*! Date: 11 August 2005
*/
real matrix datmat, bygppanel, bygpstats
real colvector x, y, weight, xcen, ycen, tidotby
real scalar i1

/*
  Check that all parameters are names of existing variables
*/
if(missing(_st_varindex(tidotv))) {
  exit(error(111))
}
if(missing(_st_varindex(tousev))) {
  exit(error(111))
}
if(missing(_st_varindex(bygpv))) {
  exit(error(111))
}
if(missing(_st_varindex(xv))) {
  exit(error(111))
}
if(missing(_st_varindex(yv))) {
  exit(error(111))
}
if(missing(_st_varindex(weightv))) {
  exit(error(111))
}
if(missing(_st_varindex(xcenv))) {
  exit(error(111))
}
if(missing(_st_varindex(ycenv))) {
  exit(error(111))
}

/*
  Define main view and panel setup matrix
*/
st_view(datmat,.,(bygpv,xv,yv,weightv,xcenv,ycenv,tidotv),tousev)
datmat[.,7]=J(rows(datmat),1,.)
bygppanel=panelsetup(datmat,1)
bygpstats=panelstats(bygppanel)

/*
  Call tidot() for each by-group
*/
for(i1=1;i1<=bygpstats[1];i1++) {
  st_subview(x,datmat,bygppanel[i1,.],2)
  st_subview(y,datmat,bygppanel[i1,.],3)
  st_subview(weight,datmat,bygppanel[i1,.],4)
  st_subview(xcen,datmat,bygppanel[i1,.],5)
  st_subview(ycen,datmat,bygppanel[i1,.],6)
  st_subview(tidotby,datmat,bygppanel[i1,.],7)
  if (tree) {;tidotby[.,.]=tidottree(x,y,weight,xcen,ycen);}
  else {;tidotby[.,.]=tidot(x,y,weight,xcen,ycen);};
}

}
end
