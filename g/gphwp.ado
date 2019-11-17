program define gphwp
version 2.1
       if "%_*"=="" { 
             di in red "invalid syntax -- see help gphwp"
             exit 198
       }
       ! gphpen %_1 /dhp7475ls /oc:\word\files\graph.hpl
end
