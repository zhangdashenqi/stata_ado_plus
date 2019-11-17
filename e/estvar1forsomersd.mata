version 9.0
mata
void estvar1forsomersd(string scalar tousev, string scalar clusterv, string scalar cfweightv,
  string rowvector namevars, string rowvector uidotwvars,
  | string rowvector uidotvars, real scalar vonmises)
{
/*
  Return estimates, jackknife estimates and variances
  of sample means, degree-2 U-statistics or degree-2 Von Mises functionals
  in returned results.e(b), e(b_jk) and e(V), respectively,
  based on pseudovalues created from uidots in uidotvars
  and within-cluster uidots in uidotwvars,
  and with row and column names from namevars.
  tousev is the to-use variable name.
  clusterv is the cluster variable name.
  cfweightv is the cluster frequency weights variable name.
  namevars contains the variable names with which the output matrices will be labelled.
  uidotwvars contains the within-cluster uidot variable name.
  uidotvars contains the uidot variable name.
  vonmises is nonzero if we are jackknifing Von Mises functionals.
*! Author: Roger Newson
*! Date: 04 August 2005
*/
real matrix clustmat, uidotwmat, uidotmat,
  clustpanel, cluststats, cfweights, pseudmat, phiiimat,
  cfweicur, uidotwcur, uidotcur, b, b_jk, V
real scalar narg, wcluster, i1, N_clust
string matrix rcstripe


/*
  Fill in absent parameters
  and evaluate wcluster
  indicating sample means of within-cluster totals
*/
narg=args()
if(narg<7) {;vonmises=0;}
if(narg<6) {;
  wcluster=1;
  uidotvars=uidotwvars;
}
else {
  wcluster=0
}


/*
  Conformability checks
*/
if(cols(uidotwvars)!=cols(namevars)) {
  exit(error(3200))
}
if(cols(uidotvars)!=cols(namevars)) {
  exit(error(3200))
}


/*
  Check that all parameters are names of existing variables
*/
if(missing(_st_varindex(tousev))) {
  exit(error(111))
}
if(missing(_st_varindex(clusterv))) {
  exit(error(111))
}
if(missing(_st_varindex(cfweightv))) {
  exit(error(111))
}
if(missing(_st_varindex(namevars))) {
  exit(error(111))
}
if(missing(_st_varindex(uidotwvars))) {
  exit(error(111))
}
if(missing(_st_varindex(uidotvars))) {
  exit(error(111))
}


/*
  Define main views and panel setup matrix
*/
st_view(clustmat,.,(clusterv,cfweightv),tousev)
st_view(uidotwmat,.,uidotwvars,tousev)
if(!wcluster){;st_view(uidotmat,.,uidotvars,tousev);}
clustpanel=panelsetup(clustmat,1)
cluststats=panelstats(clustpanel)


/*
  Create matrices cfweights containing cluster frequency weights,
  N_clust containing total number of clusters,
  b containing estimates,
  and pseudmat containing pseudovalues
*/
cfweights=J(cluststats[1],1,.)
pseudmat=J(cluststats[1],cols(namevars),.)
if(!wcluster) {;phiiimat=J(cluststats[1],cols(namevars),.);}
for(i1=1;i1<=cluststats[1];i1++) {
  st_subview(cfweicur,clustmat,clustpanel[i1,.],2)
  cfweights[i1,.]=colmax(cfweicur)
  st_subview(uidotwcur,uidotwmat,clustpanel[i1,.],.)
  if(wcluster) {
    pseudmat[i1,.]=quadcolsum(uidotwcur)
  }
  else {
    st_subview(uidotcur,uidotmat,clustpanel[i1,.],.)
    phiiimat[i1,.]=quadcolsum(uidotwcur)
    pseudmat[i1,.]=quadcolsum(uidotcur)
  }
}
N_clust=quadcolsum(cfweights)
if(wcluster) {
    b = mean(pseudmat,cfweights)
    if(N_clust<=0) {;b=J(rows(b),cols(b),0);}
}
else if(vonmises) {
  b = mean(pseudmat,cfweights) :/ N_clust
  if(N_clust<=0) {;b=J(rows(b),cols(b),0);}
  _v2jackpseud(pseudmat,phiiimat,cfweights)
}
else {
  b = mean((pseudmat-phiiimat),cfweights) :/ (N_clust-1)
  if(N_clust<=1) {;b=J(rows(b),cols(b),0);}
  _u2jackpseud(pseudmat,phiiimat,cfweights)
}


/*
  Calculate jackknife estimate and variance
*/
V=quadmeanvariance(pseudmat,cfweights)
b_jk=V[1,.]
V=V[|2,1 \ .,.|] :/ N_clust
if(N_clust<=1) {
  V=J(rows(V),cols(V),0)
  if(N_clust<=0) {
    b_jk=J(rows(b_jk),cols(b_jk),0)
  }
}


/*
  Return estimation results
*/
rcstripe=J(cols(V),1,""),(namevars')
st_numscalar("r(N_clust)",N_clust)
st_matrix("r(b)",b)
st_matrix("r(b_jk)",b_jk)
st_matrix("r(V)",V)
st_matrixcolstripe("r(b)",rcstripe)
st_matrixcolstripe("r(b_jk)",rcstripe)
st_matrixcolstripe("r(V)",rcstripe)
st_matrixrowstripe("r(V)",rcstripe)

}
end
