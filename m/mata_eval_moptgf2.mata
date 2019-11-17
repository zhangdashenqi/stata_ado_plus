*! version 1.0.0 16apr2014 13:35 mata_eval_moptgf2.mata
version 11.0
mata:
mata set matastrict on
void femlogit_eval_gf2(transmorphic scalar ML, real scalar todo, /*
  */ real rowvector b, real colvector lnfj, real matrix S, /*
  */ real matrix H) {

  // declare variables
  real colvector touse, id, yi, upsiloni
  real matrix panelinfo, Xi, out2eq, X, E, T, Hc, Sc
  real scalar N, M, J, i, A, B, j, m, Z1
  real rowvector C, D, permuteinfo, Z2
  
  // get things from Stata
  st_view(touse=.,.,st_local("touse"))
  st_view(id=.,.,st_local("group"),st_local("touse"))
  st_view(X=.,.,st_local("rhs"),st_local("touse"))
  
  // auxilary matrix
  out2eq=st_matrix(st_local("out2eq"))
  
  // derived information
  J=rows(out2eq)
  M=cols(X)
  panelinfo=panelsetup(id,1)
  N=panelstats(panelinfo)[1]
     
  // init lnfj, S, H
  lnfj=J(N,1,0)
  if (todo>0) {
    S=J(N,(J-1)*M,0)
    if (todo==2) {
      H=J((J-1)*M,(J-1)*M,0)
    }
  }

  // calculate lnfj, S, H
  for(i=1;i<=N;i++) { // loop over panels
    // create panel-wise variables (only one call per panel)
    yi=moptimize_util_depvar(ML,1)[|panelinfo[i,1]\panelinfo[i,2]|]
    Xi=X[|panelinfo[i,1],.\panelinfo[i,2],.|]

    // init major auxiliary variables (A,B,C,D,E)
    A=0
    B=0
    if (todo>0) {
      C=J(1,(J-1)*M,0)
      D=J(1,(J-1)*M,0)
      if (todo==2) {
        E=J((J-1)*M,(J-1)*M,0)
      }
    }

    // calculate A,C
    for(j=1;j<=J;j++) { // loop over outcomes
      if (out2eq[j,2]!=0) { // exclude base outcome
        A=A+quadcolsum((yi:==out2eq[j,1]):* /*
        */ ((Xi*(colshape(b,M)'))[.,out2eq[j,2]]))
        if (todo>0) {
          for(m=1;m<=M;m++) { // loop over indep. vars
            C[1,(out2eq[j,2]-1)*M+m]=quadcolsum((yi:==out2eq[j,1]):* /*
            */ (Xi[.,m]))
          }
        }
      }
    }

    // calculate B,D,E
    // generate Upsilon_i=Set of permutations of y_i
    permuteinfo=cvpermutesetup(yi)
    // loop over permutations of y_i (upsilon_i in Upsilon_i)
    while((upsiloni=cvpermute(permuteinfo))!=J(0,1,.)) {
      // init minor auxiliary variables
      Z1=0
      if (todo>0) {
        Z2=J(1,(J-1)*M,0)
      }

      // calculate Z1,Z2
      for(j=1;j<=J;j++) { // loop over outcomes
        if (out2eq[j,2]!=0) { // exclude base outcome
          Z1=Z1+quadcolsum((upsiloni:==out2eq[j,1]):*((Xi* /*
          */ (colshape(b,M)'))[.,out2eq[j,2]]))
          if (todo>0) {
            for(m=1;m<=M;m++) {
              Z2[1,(out2eq[j,2]-1)*M+m]= /*
              */ quadcolsum((upsiloni:==out2eq[j,1]):*(Xi[.,m]))
            }
          }
        }
      }
      Z1=exp(Z1)

      // fill up B,D,E with minor aux. var's
      B=B+Z1
      if (todo>0) {
        D=D+Z2:*Z1
        if (todo==2) {
          E=E+(quadcross(Z2,Z2)):*Z1
        }
      }
    }

    // fill up lnfj,S,H with major aux. var's A,B,C,D,E
    lnfj[i]=A-ln(B)
    if (todo>0) {
      S[i,.]=C-D:/B
      if (todo==2) {
        // Sum up H
        H=H+((quadcross(D,D)):/(B^2))-(E:/B)
      }
    }
  }
  // Push out scores and Hessian for robust variance matrix (precision issues!)
  if (st_local("robust")!="" & st_local("constraints")=="") {
    if (cols(S)==rows(H) & rank(H)==rows(H)) {
      st_matrix(st_local("rvm"),(N/(N-1)):*(invsym(-H)*quadcross(S,S)*invsym(-H)))
    }
  }
  if (st_local("robust")!="" & st_local("constraints")!="") {
    T=st_matrix(st_local("T"))
    if (cols(S)==rows(T)) {
      Sc=quadcross(S',T)
      if (cols(H)==rows(T) & rows(H)==rows(T)) {
        Hc=quadcross(T,H)*T
        if (cols(Sc)==rows(Hc) & rank(Hc)==rows(Hc)) {
          st_matrix(st_local("rvm"),T*((N/(N-1)):*(invsym(-Hc)*quadcross(Sc,Sc)* /*
          */ invsym(-Hc)))*T')
        }
      }
    }
  }
}
end
