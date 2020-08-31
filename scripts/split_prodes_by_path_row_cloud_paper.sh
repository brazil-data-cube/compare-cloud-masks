#!/bin/bash

# SPLIT PRODES DATA BY LANDSAT SCENE

BASE_PATH="/home/alber/Documents/data/experiments/prodes_reproduction"
PRODES_TAR="$BASE_PATH"/data/vector/prodes/prodes_2017.tar.gz
WD="$BASE_PATH"/papers/clouds/data/masks/prodes
PRODES_SHP="$WD"/prodes_2017/PDigital2017_AMZ_pol.shp

mkdir "$WD"/tiled

tar -xzf $PRODES_TAR --directory "$WD"

# get the landsat scenes of AOI                                                                 T22MCA T19LFK                  T21LXH
parallel -j6 ogr2ogr -skipfailures -where \"pathrow=\'{1}\'\" "$WD"/tiled/{2/.}_{1}.shp {2} ::: 00463  00266 00267 00166 00167 22767 22768 22668 ::: "$PRODES_SHP"

# fix topological issues
parallel ogr2ogr -sql '"SELECT ST_Buffer(geometry, 0.0), linkcolumn, uf, pathrow, scene_id, mainclass, class_name, dsfnv, julday, view_date, ano, areameters FROM {1/.}"' -dialect SQLite "$WD"/buffer/{1/} {1} ::: $(find "$WD"/tiled -maxdepth 1 -type f -name "*.shp")

# rename 
ogr2ogr -f "ESRI Shapefile" "$WD"/tiled/PDigital2017_AMZ_pol_001_066.shp "$WD"/tiled/PDigital2017_AMZ_pol_00166.shp 
ogr2ogr -f "ESRI Shapefile" "$WD"/tiled/PDigital2017_AMZ_pol_001_067.shp "$WD"/tiled/PDigital2017_AMZ_pol_00167.shp
ogr2ogr -f "ESRI Shapefile" "$WD"/tiled/PDigital2017_AMZ_pol_002_066.shp "$WD"/tiled/PDigital2017_AMZ_pol_00266.shp
ogr2ogr -f "ESRI Shapefile" "$WD"/tiled/PDigital2017_AMZ_pol_002_067.shp "$WD"/tiled/PDigital2017_AMZ_pol_00267.shp
ogr2ogr -f "ESRI Shapefile" "$WD"/tiled/PDigital2017_AMZ_pol_004_063.shp "$WD"/tiled/PDigital2017_AMZ_pol_00463.shp
ogr2ogr -f "ESRI Shapefile" "$WD"/tiled/PDigital2017_AMZ_pol_226_068.shp "$WD"/tiled/PDigital2017_AMZ_pol_22668.shp
ogr2ogr -f "ESRI Shapefile" "$WD"/tiled/PDigital2017_AMZ_pol_227_067.shp "$WD"/tiled/PDigital2017_AMZ_pol_22767.shp
ogr2ogr -f "ESRI Shapefile" "$WD"/tiled/PDigital2017_AMZ_pol_227_068.shp "$WD"/tiled/PDigital2017_AMZ_pol_22768.shp

# cleaning
rm -rf "$WD"/prodes_2017
rm "$WD"/tiled/PDigital2017_AMZ_pol_00166.*
rm "$WD"/tiled/PDigital2017_AMZ_pol_00167.* 
rm "$WD"/tiled/PDigital2017_AMZ_pol_00266.*
rm "$WD"/tiled/PDigital2017_AMZ_pol_00267.*
rm "$WD"/tiled/PDigital2017_AMZ_pol_00463.*
rm "$WD"/tiled/PDigital2017_AMZ_pol_22668.*
rm "$WD"/tiled/PDigital2017_AMZ_pol_22767.*
rm "$WD"/tiled/PDigital2017_AMZ_pol_22768.*

exit 0
