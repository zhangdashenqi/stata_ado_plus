program emap

syntax [, shp]

if "`shp'" == "shp" {
   db shp2dta
}
else {
   db spmap
}   

end
