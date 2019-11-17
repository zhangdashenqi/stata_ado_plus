.-
help for ^nmlab^ :: 2008-03-07
.-

Create a list of variable names and variable labels
---------------------------------------------------

    ^nmlab^ varlist^,^ [ ^num^ber ^col(^#^)^ ^vl^ ]

Description
-----------

  ^nmlab^ lists the names and variable labels for a list of variables
  that you provide.

Options
-------

  ^number^ produces a numbered list.

  ^col(^#^)^ indicates the column in which the variable label will begin.
      By default, the label begins in column 12.

  ^vl^ lists the value label assigned to each variable.

Examples
--------

  . ^use wf-lfp^
  (Data from 1976 PSID-T Mroz)

  . ^nmlab lfp k5^
  lfp      In paid labor force? 1=yes 0=no
  k5       # kids < 6

  . ^nmlab lfp k5, num^
  #1: lfp    In paid labor force? 1=yes 0=no
  #2: k5     # kids < 6

  . ^nmlab lfp k5, num col(15)^
  #1: lfp         In paid labor force? 1=yes 0=no
  #2: k5          # kids < 6

  . ^nmlabel lfp k5, vl^
  lfp   lfp        In paid labor force? 1=yes 0=no
  k5               # kids < 6

.-
Author: Scott Long - www.indiana.edu/~jslsoc/workflow.htm
