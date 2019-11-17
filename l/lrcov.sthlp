{smcl}
{* *! version 1.1  27feb2011}{...}
{cmd:help lrcov}{right: ({browse "http://www.stata-journal.com/article.html?article=st0272":SJ12-3: st0272})}
{hline}

{title:Title}

{p2colset 5 14 16 2}{...}
{p2col :{hi:lrcov} {hline 2}}Estimate long-run covariance of time series{p_end}
{p2colreset}{...}


{title:Syntax}

{p 8 13 2}{cmd:lrcov} {varlist} {ifin} [{cmd:,}
    {opt wv:ar}{hi:(}{varname}{hi:)} {opt nocent:er} {opt cons:tant}
    {opt dof(#)} {opt vic(string)} {opt vlag(#)} {opt kern:el(string)}
    {opt bwid:th(#)} {opt bmeth(string)} {opt blag(#)} {opt bweig(numlist)}
    {opt bwmax(#)} {opt btru:nc} {opt disp(string)}]

{pstd}{it:varlist} may contain factor variables or time-series operators.


{title:Description}

{pstd}{cmd:lrcov} computes long-run covariance (LRCOV) in Mata.  For the
prewhitened kernel method, matrix inversion is required.  {cmd:lrcov}
uses the {cmd:invsym} and {cmd:pinv} commands.  


{title:Options}

{phang}{cmd:wvar(}{it:varname}{cmd:)} specifies the weight of
observation; that is, multiply each variable in {it:varlist} with
{it:varname}.

{phang}{cmd:nocenter} requests that {cmd:lrcov} not center the data
before computing.  By default, {cmd:lrcov} centers the data using the
mean before computing LRCOV.

{phang}{cmd:constant} adds constant to {it:varlist}.  This option may
only be used with the {cmd:wvar()} option.

{phang}{cmd:dof(}{it:#}{cmd:)} adjusts the LRCOV by degrees of
freedom.  The default is {cmd:dof(0)}.

{phang}{cmd:vic(}{it:string}{cmd:)} specifies the information criteria
to select the optimal lags in value at risk (VAR).  {cmd:aic},
{cmd:bic}, and {cmd:hq} are allowed.  To prewhiten the data, both
{cmd:vic()} and {cmd:vlag()} must be specified.

{phang}{cmd:vlag(}{it:#}{cmd:)} specifies the maximum lag to
select the optimal lag length if the {cmd:vic()} option is specified.
Otherwise, {it:#} is the lag order of VAR model to estimate.  If
the user specified {cmd:vic()} but not {cmd:vlag()}, {cmd:lrcov}
automatically sets the maximum lag to int{T^(1/3)}.  To prewhiten the
data, both {cmd:vic()} and {cmd:vlag()} must be specified.

{phang}{cmd:kernel(}{it:string}{cmd:)} specifies the type of kernel
function. {it:string} may be {cmd:none}, {cmd:bartlett}, {cmd:bohman},
{cmd:daniell}, {cmd:parzen}, {cmd:qs}, {cmd:priesz}, {cmd:pcauchy},
{cmd:pgeometric}, {cmd:thamming}, {cmd:thanning}, or {cmd:tparzen}.  If
the user specifies {cmd:kernel(none)}, the {cmd:bwidth()},
{cmd:bmeth()}, {cmd:blag()}, {cmd:btrunc}, and {cmd:bweig()} options
will be ignored.

{phang}{cmd:bwidth(}{it:#}{cmd:)} specifies the bandwidth by hand.
If this option is specified, the program will ignore the {cmd:bmeth()},
{cmd:blag()}, {cmd:bweig()}, and {cmd:btrunc} options.

{phang}{cmd:bmeth(}{it:string}{cmd:)} specifies the bandwidth selection
procedure, including {cmd:nwfixed} [Newey-West fixed lag, that is, 4 x
(T/100)^(2/9)], {cmd:andrews}, and {cmd:neweywest}.  The default is
{cmd:bmeth(nwfixed)}.

{phang}{cmd:blag(}{it:#}{cmd:)} specifies the maximum lag to
compute the Newey-West automatic bandwidth.  The default value depends
on the kernel function.

{phang}{cmd:bweig(}{it:numlist}{cmd:)} specifies the weight of each
variable in the Andrews automatic bandwidth selection.  The weight is 1
for all variables by default.

{phang}{cmd:bwmax(}{it:#}{cmd:)} specifies the maximum bandwidth.  If
the bandwidth supplied by the user or automatically determined by the
procedure is greater than {it:#}, {cmd:lrcov} will use {it:#} as
the bandwidth.

{phang}{cmd:btrunc} truncates the bandwidth to an integer.

{phang}{cmd:disp(}{it:string}{cmd:)} requests that {cmd:lrcov} display
the detailed results, including {cmd:two} (two-sided LRCOV), {cmd:one}
(one-sided LRCOV), {cmd:sone} (strict one-sided LRCOV), and {cmd:cont}
(contemporaneous covariance).  The default is {cmd:disp(two)}.


{title:Examples}
   
{pstd}{hi:Example 1}

{phang}{cmd:.} {bf:{stata webuse dfex}}{p_end}
{phang}{cmd:.} {bf:{stata describe}}{p_end}

{pstd} Case 2: Nonparametric kernel approach.  Bartlett kernel, fixed
bandwidth at 10, output the two-sided LRCOV.{p_end}
{phang}{cmd:.} {bf:{stata lrcov d.(ipman income hours unemp), bwidth(10)}}{p_end}

{pstd} Case 3: Parametric approach.  Value at risk heteroskedasticity-
and autocorrelation-consistent estimation using VAR(1).{p_end}
{phang}{cmd:.} {bf:{stata lrcov d.(ipman income hours unemp), vlag(1) kernel(none) }}{p_end}

{pstd} Case 4: Prewhitened kernel approach.  Prewhiten using VAR(1),
Parzen kernel, Andrews automatic bandwidth.{p_end}
{phang}{cmd:.} {bf:{stata lrcov d.(ipman income hours unemp), vlag(1) kernel(parzen) bmeth(andrews)  }}{p_end}

{pstd} Case 5: More flexible options.  Prewhiten using VAR with lag
selected by Akaike's information criterion, quadratic spectral kernel,
Newey-West automatic bandwidth with truncated lag = 10.{p_end}
{phang}{cmd:.} {bf:{stata lrcov d.(ipman income hours unemp), vic(aic) kernel(qs) bmeth(neweywest) blag(10) }}{p_end}

{pstd}{hi:Example 2: Using {hi:lrcov} to compute heteroskedasticity- and autocorrelation-consistent variance}{p_end}

{phang}{cmd:.} {bf:{stata qui reg d.ipman d.(income hours unemp) }}{p_end}
{phang}{cmd:.} {bf:{stata qui predict u, res }}{p_end}
{phang}{cmd:.} {bf:{stata lrcov d.(income hours unemp), wvar(u) constant dof(4) kernel(none)}}{p_end}
{phang}{cmd:.} {bf:{stata matrix covu = r(Omega) }}{p_end}
{phang}{cmd:.} {bf:{stata matrix accum xx = d.(income hours unemp) }}{p_end}
{phang}{cmd:.} {bf:{stata matrix xxi = invsym(xx) }}{p_end}
{phang}{cmd:.} {bf:{stata matrix cov = 442*xxi*covu*xxi }}{p_end}
{phang}{cmd:.} {bf:{stata matlist cov }}{p_end}

{phang}{cmd:.} {bf:{stata qui reg d.ipman d.(income hours unemp), vce(robust) }}{p_end}
{phang}{cmd:.} {bf:{stata matlist e(V) }}{p_end}

{pstd}{hi:Example 3: Using lrcov to perform generalized method of moments (GMM) estimation}

{phang}{cmd:.} {bf:{stata webuse dfex, clear }}{p_end}

{pstd} One-step GMM (two-stage least squares){p_end}
{phang}{cmd:.} {bf:{stata qui ivregress 2sls d.ipman d.income (d.hours d.unemp = DL(1/2).(hours unemp)) }}{p_end}
{phang}{cmd:.} {bf:{stata qui predict u, res }}{p_end}

{pstd} Weighted matrix using long-run variance{p_end}
{phang}{cmd:.} {bf:{stata local inst = "d.income DL(1/2).(hours unemp)" }}{p_end}
{phang}{cmd:.} {bf:{stata qui lrcov `inst', nocent wvar(u) constant kernel(bartlett) bwidth(11) }}{p_end}
{phang}{cmd:.} {bf:{stata matrix w = r(Omega) }}{p_end}

{pstd} Two-step GMM estimator{p_end}
{phang}{cmd:.} {bf:{stata qui matrix accum xz = d.hours d.unemp d.income `inst' }}{p_end}
{phang}{cmd:.} {bf:{stata matrix xz = xz[1..3, 4...] \ xz["_cons", 4...] }}{p_end}
{phang}{cmd:.} {bf:{stata matrix accum yz = d.ipman `inst' }}{p_end}
{phang}{cmd:.} {bf:{stata matrix yz = yz[1, 2...] }}{p_end}
{phang}{cmd:.} {bf:{stata matrix b = invsym(xz*invsym(w)*xz')*(xz*invsym(w)*yz') }}{p_end}
{phang}{cmd:.} {bf:{stata matrix V = 440*invsym(xz*invsym(w)*xz') }}{p_end}
{phang}{cmd:.} {bf:{stata matlist b' }}{p_end}
{phang}{cmd:.} {bf:{stata matlist V }}{p_end}

{phang}{cmd:.} {bf:{stata qui ivregress gmm d.ipman d.income (d.hours d.unemp = DL(1/2).(hours unemp)), vce(unadjusted) wmatrix(hac bartlett 10) }}{p_end}
{phang}{cmd:.} {bf:{stata matlist e(b) }}{p_end}
{phang}{cmd:.} {bf:{stata matlist e(V) }}{p_end}


{title:Saved results}

{pstd}{cmd:lrcov} saves the following in {cmdab:r()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2:Scalars}{p_end}
{synopt:{cmd:r(bwidth)}}bandwidth{p_end}
{synopt:{cmd:r(vlag)}}lag of VAR model{p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2:Macros}{p_end}
{synopt:{cmd:r(kernel)}}kernel function{p_end}
{synopt:{cmd:r(bmeth)}}automatic bandwidth method{p_end}
{synopt:{cmd:r(vic)}}type of information criterion{p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2:Matrices}{p_end}
{synopt:{cmd:r(Omega)}}two-sided LRCOV{p_end}
{synopt:{cmd:r(Omegaone)}}one-sided LRCOV (lag){p_end}
{synopt:{cmd:r(Omega0)}}contemporaneous covariance{p_end}
{synopt:{cmd:r(Omegasone)}}strict one-sided LRCOV (lag){p_end}


{title:Author}

{pstd}Qunyong Wang{p_end}
{pstd}Institute of Statistics and Econometrics{p_end}
{pstd}Nankai University{p_end}
{pstd}brynewqy@nankai.edu.cn{p_end}


{title:Also see}

{p 4 14 2}Article:  {it:Stata Journal}, volume 12, number 3: {browse "http://www.stata-journal.com/article.html?article=st0272":st0272}

{p 7 14 2}Help:  {helpb cointreg}, {helpb hacreg} (if installed), {helpb newey}{p_end}
