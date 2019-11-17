#delim ;
program define adoind;
version 10.0;
*
 Alter ado path to start with the Stata system folders
 UPDATES, BASE, PERSONAL, PLUS, SITE,  . and OLDPLACE
 (for independent-minded users).
*!Author: Roger Newson
*!Date: 29 March 2009
*;

qui{;
  cap adopath - .;
  cap adopath - BASE;
  cap adopath - UPDATES;
  cap adopath - PERSONAL;
  cap adopath - PLUS;
  cap adopath - SITE;
  cap adopath - OLDPLACE;
  adopath ++ OLDPLACE;
  adopath ++ .;
  adopath ++ SITE;
  adopath ++ PLUS;
  adopath ++ PERSONAL;
  adopath ++ BASE;
  adopath ++ UPDATES;
};

* Display final adopath *;
adopath;

end;

