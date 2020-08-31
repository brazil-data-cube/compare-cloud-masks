# compare-cloud-masks

This repository contais the code used in the analysis section of the paper entitled
*Comparison of cloud cover detection algorithms for land use classification of the Amazon tropical forest*

## Directories:
    * cloud_notebook         R notebook files.
    * data/masks/image_tiles Shapefiles of tiling systems of satellite imagery.
    * qgis                   Qgis files including maps, virtual rasters, and layers' styles.
    * scripts                Utilitary script file (bash, python, and R)


## Algorithms

### Fmask 4.0
    * Code downloaded from this git [repostory](https://github.com/gersl/fmask)
    * Algorithm description in this [paper](doi.org/10.1016/j.rse.2019.05.024)
    * Run by creating a container from the docker image container in server e-sensing6:
    + Repository: fmask
    + Tag: 4.0
    + Image Id: 74de3d7c5a73
    + Virtual size 13.3 GB
    * While creating a dockerfile, take into account an issue related to MATLAB's runtime and the LD_LIBRARY_PATH. See below.

MATLAB Runtine is unable to find some of the required libraries. A workaround is to replace Ubuntu's LD_LIBRARY_PATH for the one below. However, this mixes up Ubuntu's configuration. MATLAB runtime:
```
XAPPLRESDIR=/usr/local/MATLAB/MATLAB_Runtime/v95/X11/app-defaults
export LD_LIBRARY_PATH="/lib:/usr/lib:/usr/local/lib"
LD_LIBRARY_PATH="${LD_LIBRARY_PATH}:/usr/local/MATLAB/MATLAB_Runtime/v95/runtime/glnxa64:/usr/local/MATLAB/MATLAB_Runtime/v95/bin/glnxa64:/usr/local/MATLAB/MATLAB_Runtime/v95/sys/os/glnxa64:/usr/local/MATLAB/MATLAB_Runtime/v95/sys/opengl/lib/glnxa64"
export PATH=$PATH:$LD_LIBRARY_PATH
```

### MAJA
    * Algorithm description in this [paper](https://www.mdpi.com/2072-4292/7/3/2668)
    * MAJA is ran by the Sen2Agri instances on server e-sensing6.
### s2cloudless
    * Algorithm desciption  in this [paper](https://medium.com/sentinel-hub/improving-cloud-detection-with-machine-learning-c09dc5d7cf13)
    * Run it using the script call_s2cloudless.py
### Sen2Cor
    * Algorithm description in this [paper](https://www.spiedigitallibrary.org/conference-proceedings-of-spie/10427/2278218/Sen2Cor-for-Sentinel-2/10.1117/12.2278218.full)
    * Run it using the docker container prepared by the Brazil Data Cube containers.
    * Repository: sen2cor_2
    * Tag: latest
    * Image Id: ba7400c9bba6
    * Virtual size 2.034 GB


## Notes.


### Fmask 4

* Use the docker container in server e-sensing6: 
```
sudo docker run -it -v /home/alber/Documents/data/experiments/prodes_reproduction/papers/clouds/data/fmask4_s2cloudless:/root/images fmask:4.0 /bin/bash
```
* Call the script call_fmask.sh from inside the docker container.


### MAJA

* Copy the processed images from sen2agri's docker (instance running in server e-sensing6). Use script copy_maja_images.sh


### S2CLOUDLESS

* Run it from sdb-desktop.
* Mount remote directory of images locally to run the algorithm 
```
sshfs alber@e-sensing6:/net/150.163.2.206/disks/d6/shared/alber/prodes_reproduction/papers/clouds/data/fmask4 /home/alber/Documents/ghProjects/sentinel2-cloud-detector/alber_test/images
```
* Use script create_s2cloudless_mask.py*


### SEN2COR
files in :
/home/scidb/docker_sen2cor

# run sen2cor for the cloud paper on sdb-desktop using a the docker container of Brazil Data Cubes provided by Renan Marujo.

# step 1: build docker image: Go to Dockerfile dir and:
docker build -t sen2cor_2.8.0 .

# step 2: Download auxiliarie files download from http://maps.elie.ucl.ac.be/CCI/viewer/download.php (fill info on the right and download "ESACCI-LC for Sen2Cor data package") or you can get it from ( /gfs/ds_data/CCI4SEN2COR ). Then extract the file

# step 3: Run docker mounting volumes
docker run --rm -it -v /home/alber/Desktop/sen2cor/CCI4SEN2COR:/home/lib/python2.7/site-packages/sen2cor/aux_data -v /home/alber/Desktop/sen2cor/data:/root/data sen2cor_2.8.0 bash

scidb@esensing-006:~/docker_sen2cor$ sudo docker run --rm -it -v /home/scidb/docker_sen2cor/CCI4SEN2COR:/home/lib/python2.7/site-packages/sen2cor/aux_data -v /home/alber/Documents/data/experiments/prodes_reproduction/papers/deforestation/data/raster/sentinel_L1C:/root/data sen2cor_2.8.0   bash


# step 4: Execute Sen2cor
time L2A_Process --resolution 10 /root/data/S2A_MSIL1C_20160901T143752_N0204_R096_T20NPH_20160901T143746.SAFE
time L2A_Process --resolution 10 /root/data/S2A_MSIL1C_20160929T140052_N0204_R067_T22NCG_20160929T140047.SAFE
time L2A_Process --resolution 10 /root/data/S2A_MSIL1C_20161004T144732_N0204_R139_T19LFK_20161004T144903.SAFE
time L2A_Process --resolution 10 /root/data/S2A_MSIL1C_20161019T140052_N0204_R067_T22NCG_20161019T140047.SAFE
time L2A_Process --resolution 10 /root/data/S2A_MSIL1C_20161110T143752_N0204_R096_T20NPH_20161110T143750.SAFE
time L2A_Process --resolution 10 /root/data/S2A_MSIL1C_20170102T144722_N0204_R139_T19LFK_20170102T144743.SAFE
time L2A_Process --resolution 10 /root/data/S2A_MSIL1C_20170218T143751_N0204_R096_T20NPH_20170218T143931.SAFE
time L2A_Process --resolution 10 /root/data/S2A_MSIL1C_20170328T140051_N0204_R067_T21LXH_20170328T140141.SAFE
time L2A_Process --resolution 10 /root/data/S2A_MSIL1C_20170527T140101_N0205_R067_T22NCG_20170527T140055.SAFE
time L2A_Process --resolution 10 /root/data/S2A_MSIL1C_20170603T135111_N0205_R024_T22MCA_20170603T135143.SAFE
time L2A_Process --resolution 10 /root/data/S2A_MSIL1C_20170623T135111_N0205_R024_T22MCA_20170623T135111.SAFE
time L2A_Process --resolution 10 /root/data/S2A_MSIL1C_20170706T140051_N0205_R067_T22NCG_20170706T140051.SAFE
time L2A_Process --resolution 10 /root/data/S2A_MSIL1C_20170718T143751_N0205_R096_T20NPH_20170718T143752.SAFE
time L2A_Process --resolution 10 /root/data/S2A_MSIL1C_20180419T135111_N0206_R024_T22MCA_20180419T153418.SAFE
time L2A_Process --resolution 10 /root/data/S2A_MSIL1C_20180507T144731_N0206_R139_T19LFK_20180507T182218.SAFE
time L2A_Process --resolution 10 /root/data/S2A_MSIL1C_20180611T140051_N0206_R067_T21LXH_20180611T154709.SAFE
time L2A_Process --resolution 10 /root/data/S2A_MSIL1C_20180628T135111_N0206_R024_T22MCA_20180628T153546.SAFE
time L2A_Process --resolution 10 /root/data/S2A_MSIL1C_20180919T140051_N0206_R067_T21LXH_20180919T174008.SAFE
time L2A_Process --resolution 10 /root/data/S2A_MSIL1C_20181009T140051_N0206_R067_T21LXH_20181009T173159.SAFE
time L2A_Process --resolution 10 /root/data/S2A_MSIL1C_20181103T144731_N0206_R139_T19LFK_20181103T163457.SAFE

