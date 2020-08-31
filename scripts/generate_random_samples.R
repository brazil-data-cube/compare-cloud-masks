# GENERATE RANDOM POINTS
library(dplyr)
library(sf)
library(raster)

base_path <- "/home/alber/Documents/ghProjects/compare-cloud-masks"
out_dir   <- file.path(base_path, "data", "samples", "template_point")
stopifnot(all(sapply(c(base_path, out_dir), dir.exists)))

source(file.path(base_path, "scripts", "util.R"))

n_samples <- 450
set.seed(666)

# Get the extent of a raster file as an SF object.
raster_extent_as_sf <- function(file_path){
    r <- file_path %>%
        raster::raster()
    sf_df <- r %>%
        raster::extent() %>%
        as(Class = "SpatialPolygons") %>%
        sf::st_as_sf() %>%
        sf::st_set_crs(value = raster::crs(r)) %>%
        return()
}

band_01 <- dir_name <- file_path <- img_date <- mission <- tile <- NULL
images_tb <- base_path %>%
    file.path("data", "img_l1c") %>%
    list.dirs() %>%
    tibble::enframe(name = NULL) %>%
    dplyr::rename(file_path = "value") %>%
    dplyr::filter(endsWith(file_path, ".SAFE")) %>%
    dplyr::mutate(dir_name = tools::file_path_sans_ext(basename(file_path))) %>%
    tidyr::separate(col = dir_name,
                    into = c("mission", "level", "img_date", "baseline",
                             "orbit", "tile", "processing"), sep = '_') %>%
    dplyr::filter(mission == "S2A",
                  tile %in% c("T19LFK", "T20NPH", "T21LXH", "T22MCA",
                              "T22NCG")) %>%
    dplyr::group_by(mission, tile) %>%
    dplyr::arrange(img_date) %>%
    dplyr::slice(1) %>%
    dplyr::ungroup() %>%
    dplyr::mutate(band01  = purrr::map_chr(file_path, find_files,
                                           pattern = "_B01[.]jp2"),
                  ext     = purrr::map(band01, raster_extent_as_sf),
                  obj     = purrr::map(ext, sf::st_sample, size = n_samples,
                                       type = "random"),
                  layer = file.path(out_dir, stringr::str_c(mission, level, tile,
                                            "samples.shp", sep = "_"))) %>%
    ensurer::ensure_that(nrow(.) > 0,err_desc = "No images found") %>%
    dplyr::mutate(w = purrr::map2(obj, layer, sf::st_write))

