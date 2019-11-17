{smcl}
{* *! version 2012-08-31 scott long}{...}
{title:Title}

{p 4 21 2}
{hi:_rm_modelinfo} {hline 2}
Returns information about the model that has e-returns in memory.


{marker syntax}{...}
{title:Syntax}

{phang2}
{cmd:_rm_modelinfo}


{marker description}{...}
{title:Description}

{pstd}
{cmd:_rm_modelinfo} is a programmer's tool that returns information about
the estimation command that has e-returns in memory.

{pstd}
One way to see the information returned is by including: _rm_modelinfo.doi

{pstd}
Alternatively:

    _rm_modelinfo

    sreturn list

    foreach s in cmdnm cmdbin cmdnrm cmdsvy cmdn lhsnm lhsvalues lhscatn ///
        lhscatnms lhscatvals rhsnms rhsn rhsnms2 rhsn2 ///
        rhsfvtypes rhsfvtypes2 {

        di "`s': " _col(20) "`s(`s')'"
    }


{marker saved_results}{...}
{title:Saved results}

{pstd}
{cmd:_rm_modelinfo} saves in {cmd:s()}:

{p2colset 9 32 36 2}{...}
{pstd}Macros:{p_end}

{p2col :{cmd:s(cmdnm)}}Estimation command name{p_end}
{p2col :{cmd:s(cmdbin)}}1 if binary model{p_end}
{p2col :{cmd:s(cmdnrm)}}1 if mprobit or mlogit{p_end}
{p2col :{cmd:s(cmdsvy)}}1 if svy command{p_end}
{p2col :{cmd:s(cmdn)}}Sample size{p_end}
{p2col :{cmd:s(lhsnm)}}Name of lhs variable{p_end}
{p2col :{cmd:s(lhsvalues)}}# of values for lhs variable in e(sample){p_end}
{p2col :{cmd:s(lhscatn)}}# of cateogies returned by e(k_cat){p_end}
{p2col :{cmd:s(lhscatnms)}}names of lhs categories{p_end}
{p2col :{cmd:s(lhscatvals)}}values of categories{p_end}

{p2col :{cmd:s(rhsnms)}}names of 1st rhs equation{p_end}
{p2col :{cmd:s(rhsn)}}# of rhs variables{p_end}
{p2col :{cmd:s(rhsnms2)}}names of 2nd equation{p_end}
{p2col :{cmd:s(rhsn2)}}# of rhs vars in the second equation{p_end}

{p2col :{cmd:s(rhs2_core)}}unique set of variables on the rhs inflation portion{p_end}
{p2col :{cmd:s(rhs2_notfv)}}variables not used as factor variables{p_end}
{p2col :{cmd:s(rhs2_fv)}}variables used as factor variables{p_end}
{p2col :{cmd:s(rhs2_fvbin)}}variables used as i1. type factor variables{p_end}
{p2col :{cmd:s(rhs2_fvcat)}}variables used as i2., i3., ... type factor variables{p_end}
{p2col :{cmd:s(rhs2_fvint)}}variables used in # terms{p_end}
{p2col :{cmd:s(rhs2_fvintself)}}variables used in # with themselves (e.g., c.age#c.age){p_end}
{p2col :{cmd:s(rhs2_fvintselfonly)}}variables used in # only with self but no other variables
(e.g., not c.age#i.wc){p_end}
{p2col :{cmd:s(rhs2_fvintother)}}variables used in # with other varvariables
(e.g., c.age#i.wc) {p_end}

{p2colreset}{...}

{title:Also see}

{pstd}
{help _rm} for other _rm programming commands.
INCLUDE help _rm_footer

