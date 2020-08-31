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
