#delim ;
prog def htmlclose;
version 10.0;
/*
 Close a file for input using HTML.
*!Author: Roger Newson
*!Date: 04 April 2016
*/
;

syntax name [, BOdy ];

if "`body'"!="" {;
  file write `namelist' "</body>" _n;
};
file write `namelist' "</html>" _n;
file close `namelist';

end;
