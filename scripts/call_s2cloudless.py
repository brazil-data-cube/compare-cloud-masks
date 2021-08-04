#!/usr/bin/env python3

"""
Run the s2cloudless algorithm on a set of Sentinel2 images. Adapted from
https://github.com/sentinel-hub/sentinel2-cloud-detector/blob/master/examples/sentinel2-cloud-detector-example.ipynb
"""

import gdal
import numpy as np
import os
import argparse
from osgeo import gdal_array
from s2cloudless import S2PixelCloudDetector


def subdirs(path):
    """Return a list of the subdirectories of path."""
    return([os.path.join(path, item) for item in os.listdir(path)
            if os.path.isdir(path + "/" + item)])


def get_img_dir(path):
    """Given a directory of Sentinel2 images, return a list of paths to the
       IMG_DATA on each image."""
    img_dirs = subdirs(path)
    img_dirs = [os.path.join(item, "GRANULE") for item in img_dirs
                if 'GRANULE' in os.listdir(item)]
    img_dirs = [subdirs(item) for item in img_dirs]
    img_dirs = [item for sublist in img_dirs for item in sublist]
    img_dirs = [os.path.join(item, "IMG_DATA") for item in img_dirs
                if 'IMG_DATA' in os.listdir(item)]
    return(img_dirs)


def create_bandarray(path):
    """Creates a list of Gdal Datasets from the band files in path."""
    subdatasets = [os.path.join(path, item) for item in os.listdir(path)
                   if item.endswith("jp2")]
    wms_bands = []
    for entry in subdatasets:
        if entry.find("B01") != - 1 or entry.find("band01") != - 1:
            dataset = gdal.Open(entry)
            buff_xsize = dataset.RasterXSize
            buff_ysize = dataset.RasterYSize

    bands = ['B01', 'B02', 'B04', 'B05', 'B08', 'B8A', 'B09', 
             'B10', 'B11', 'B12']
    for b in bands:
        band = [s for s in subdatasets if b in s][0]
        if len(band) == 0:
            raise ValueError("Band not found {}!".format(b))
        dataset = gdal.Open(band)
        wms_bands.append(dataset.ReadAsArray(buf_xsize = buff_xsize,
                                             buf_ysize = buff_ysize,
                                             buf_type  = gdal.GDT_UInt16))

    return wms_bands


def create_mask(band_array, path):
    """Crete the mask."""
    stacked = np.stack(band_array, -1)
    arr4d = np.expand_dims(stacked / 10000, 0)
    cloud_detector = S2PixelCloudDetector(threshold = 0.4, average_over = 4,
                                          dilation_size = 2)
    cloud_prob_map = cloud_detector.get_cloud_probability_maps(np.array(arr4d))
    cloud_masks = cloud_detector.get_cloud_masks(np.array(arr4d))
    template_file = [os.path.join(path, item) for item in os.listdir(path)
                     if item.endswith("01.jp2")][0]
    # save files
    out_prob = os.path.dirname(path) + "_s2cloudless_prob.tif"
    out_mask = os.path.dirname(path) + "_s2cloudless_mask.tif"
    output = gdal_array.SaveArray(cloud_prob_map[0, :, :], out_prob,
                                  format="GTiff", prototype=template_file)
    output = None
    output = gdal_array.SaveArray(cloud_masks[0, :, :], out_mask,
                                  format="GTiff", prototype=template_file)
    output = None
    return(out_prob, out_mask)


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument("-i", "--in_dir",
                        help="directory with Sentinel-2 images")
    args = parser.parse_args()

    # Run the algoritmh on each image.
    for img in get_img_dir(args.in_dir):
        band_array = create_bandarray(img)
        out_prob, out_mask = create_mask(band_array, img)
        print("Saving probability map to {}".format(out_prob))
        print("Saving mask map to        {}".format(out_mask))
