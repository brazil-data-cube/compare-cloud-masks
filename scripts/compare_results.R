#!/usr/bin/env Rscript
# Compare the performance of the cloud masks.

library(caret)
library(dplyr)
source("util.R")

#---- Util ----

# @param base_dir      Directory with Sentinel images.
# @param mask_patthern Pattern of the file names of the cloud masks.
find_masks <- function(base_dir, mask_pattern){
    base_dir %>%
        list.dirs() %>%
        tibble::enframe(name = NULL) %>%
        dplyr::rename(file_path = "value") %>%
        dplyr::filter(endsWith(file_path, ".SAFE")) %>%
        dplyr::mutate(dir_name = tools::file_path_sans_ext(basename(file_path))) %>%
        tidyr::separate(col = dir_name, into = c("mission", "level", "img_date",
                                                 "baseline", "orbit", "tile",
                                                 "processing"), sep = '_')  %>%
        dplyr::mutate(mask_file = purrr::map_chr(file_path, find_files,
                                         pattern = mask_pattern)) %>%
        dplyr::select(-file_path, -baseline, -processing, -level) %>%
        return()
}

# Join and filter the two classified point samples provided by experts
join_samples <- function(sf_1, sf_2) {
    sf_1 %>%
        sf::st_join(y = sf_2, join = sf::st_is_within_distance, dist = 1) %>%
        dplyr::filter(label.x == label.y) %>%
        dplyr::select(FID = FID.x, label = label.x) %>%
        return()
}

#---- Script ----

# Build tables of masks.
fm4_tb <- file.path("..", "data", "fmask4_s2cloudless") %>%
    find_masks(mask_pattern = "._Fmask4[.]tif$") %>%
    dplyr::rename(fmask4 = "mask_file")
sen2cor_tb <- file.path("..", "data", "sen2cor") %>%
    find_masks(mask_pattern = "(._SCL[.]tif$|._SCL_20m[.]jp2$)") %>%
    dplyr::rename(sen2cor = "mask_file")
maja_tb <- file.path("..", "data", "maja") %>%
    find_masks(mask_pattern = "._CLM_R1[.]tif$") %>%
    dplyr::rename(maja = "mask_file")
#s2cloud_tb <- file.path("..", "data", "fmask4_s2cloudless") %>%
s2cloud_tb <- args[1] %>%
    find_masks(mask_pattern = "._s2cloudless_mask[.]tif$") %>%
    dplyr::rename(s2cloudless = "mask_file")

# Join tables.
join_col_names <- c("mission", "img_date", "tile", "orbit")
fm4_s2cloud_maja_s2cor_tb <- fm4_tb %>%
    dplyr::full_join(s2cloud_tb, by = join_col_names) %>%
    dplyr::full_join(maja_tb,    by = join_col_names) %>%
    dplyr::full_join(sen2cor_tb, by = join_col_names) %>%
    ensurer::ensure_that(nrow(.) == 20, !all(is.na(.)),
                         err_desc = "Missing cloud masks!")

cloud_mask_tb <- fm4_s2cloud_maja_s2cor_tb %>%
    dplyr::mutate(fmask4_r      = purrr::map(fmask4,       raster::raster),
                  maja_r        = purrr::map(maja,         raster::raster),
                  sen2cor_r     = purrr::map(sen2cor,      raster::raster),
                  s2cloudless_r = purrr::map(s2cloudless,  raster::raster)) %>%
    dplyr::select(-c(mission, orbit, fmask4, maja, sen2cor, s2cloudless))

# Second classification made by experts.
second_classification <- file.path("..", "data", "samples",
                                   "point_second_classification") %>%
    get_sample_shps() %>%
    dplyr::rename(file_path_2 = file_path)

# Read the sample point classified by experts.
cloud_experts <- file.path("..", "data", "samples", "point") %>%
    get_sample_shps() %>%
    dplyr::filter((mission == "S2A" & tile == "T19LFK" & img_date %in% c("20161004T144732", "20170102T144722", "20180507T144731", "20181103T144731")) |
                  (mission == "S2A" & tile == "T20NPH" & img_date %in% c("20160901T143752", "20161110T143752", "20170218T143751", "20170718T143751")) |
                  (mission == "S2A" & tile == "T21LXH" & img_date %in% c("20170328T140051", "20180611T140051", "20180919T140051", "20181009T140051")) |
                  (mission == "S2A" & tile == "T22MCA" & img_date %in% c("20170603T135111", "20170623T135111", "20180419T135111", "20180628T135111")) |
                  (mission == "S2A" & tile == "T22NCG" & img_date %in% c("20160929T140052", "20161019T140052", "20170527T140101", "20170706T140051"))) %>%
    dplyr::left_join(second_classification,
                     by = c("mission", "level", "tile", "img_date")) %>%
    ensurer::ensure_that(nrow(.) == 20,
                         err_desc = "Wrong number of shapefiles!") %>%
    dplyr::mutate(samples_sf_1 = purrr::map(file_path, read_samples),
                  samples_sf_2 = purrr::map(file_path_2, read_samples)) %>%
    dplyr::mutate(samples_sf = purrr::map2(samples_sf_1, samples_sf_2,
                                           join_samples)) %>%
    dplyr::mutate(n_samples = purrr::map(samples_sf, nrow),
                  n_samples_1 = purrr::map(samples_sf_1, nrow),
                  n_samples_2 = purrr::map(samples_sf_2, nrow))

cloud_experts <- cloud_experts %>%
    dplyr::mutate(srs = purrr::map(samples_sf, sf::st_crs)) %>%
    dplyr::inner_join(cloud_mask_tb, by = c("tile", "img_date")) %>%
    ensurer::ensure_that(nrow(.) == 20,
                         err_desc = "Wrong number of cloud masks!") %>%
    dplyr::mutate(fmask4_sf  = purrr::map2(samples_sf, fmask4_r,
                                           purrr::possibly(get_label_raster, NA),
                                           new_col = Fmask4)) %>%
    dplyr::mutate(maja_sf    = purrr::map2(samples_sf, maja_r,
                                           purrr::possibly(get_label_raster, NA),
                                           new_col = MAJA)) %>%
    dplyr::mutate(sen2cor_sf = purrr::map2(samples_sf, sen2cor_r,
                                           purrr::possibly(get_label_raster, NA),
                                           new_col = Sen2Cor)) %>%
    dplyr::mutate(s2cloud_sf = purrr::map2(samples_sf, s2cloudless_r,
                                           purrr::possibly(get_label_raster, NA),
                                           new_col = s2cloudless)) %>%
    ensurer::ensure_that(all(!vapply(.$fmask4_sf,  tibble::is_tibble, logical(1))),
                         all(!vapply(.$maja_sf,    tibble::is_tibble, logical(1))),
                         all(!vapply(.$sen2cor_sf, tibble::is_tibble, logical(1))),
                         all(!vapply(.$s2cloud_sf, tibble::is_tibble, logical(1))),
                         err_desc = "Failed to get samples labels from cloud masks!") %>%
    dplyr::mutate(samples_sf = purrr::pmap(dplyr::select(., samples_sf, fmask4_sf, maja_sf, sen2cor_sf, s2cloud_sf),
                                           function(samples_sf, fmask4_sf, maja_sf, sen2cor_sf, s2cloud_sf){
                                               samples_sf %>%
                                                   dplyr::bind_cols(sf::st_set_geometry(fmask4_sf,  NULL),
                                                                    sf::st_set_geometry(maja_sf,    NULL),
                                                                    sf::st_set_geometry(sen2cor_sf, NULL),
                                                                    sf::st_set_geometry(s2cloud_sf, NULL)) %>%
                                                   return()
                                           })) %>%
    # Recode.
    dplyr::mutate(samples_sf = purrr::map(samples_sf, recode_sf_fmask4,      coded_var = Fmask4),
                  samples_sf = purrr::map(samples_sf, recode_sf_maja,        coded_var = MAJA),
                  samples_sf = purrr::map(samples_sf, recode_sf_sen2cor,     coded_var = Sen2Cor),
                  samples_sf = purrr::map(samples_sf, recode_sf_s2cloudless, coded_var = s2cloudless)) %>%
    # Compute the frequency of each class in each image.
    dplyr::mutate(fmask4_freq      = purrr::map(fmask4_r,      purrr::possibly(get_raster_freq, NA), detector = fmask4),
                  maja_freq        = purrr::map(maja_r,        purrr::possibly(get_raster_freq, NA), detector = maja),
                  s2cloudless_freq = purrr::map(s2cloudless_r, purrr::possibly(get_raster_freq, NA), detector = s2cloudless),
                  sen2cor_freq     = purrr::map(sen2cor_r,     purrr::possibly(get_raster_freq, NA), detector = sen2cor)) %>%
    ensurer::ensure_that(all(!vapply(.$fmask4_r,      tibble::is_tibble, logical(1))),
                         all(!vapply(.$maja_r,        tibble::is_tibble, logical(1))),
                         all(!vapply(.$sen2cor_r,     tibble::is_tibble, logical(1))),
                         all(!vapply(.$s2cloudless_r, tibble::is_tibble, logical(1))),
                         err_desc = "Failed to get label frequencies from cloud masks!")

recode_vec <- c("cirrus" = "cloud",
                "clear"  = "clear",
                "cloud"  = "cloud",
                "shadow" = "shadow")

data_tb <- cloud_experts %>%
    dplyr::select(mission, level, tile, img_date, samples_sf) %>%
    dplyr::mutate(samples_tb = purrr::map(samples_sf, sf::st_set_geometry,
                                          value = NULL)) %>%
    dplyr::select(-samples_sf) %>%
    tidyr::unnest(cols = c(samples_tb)) %>%
    dplyr::select(-FID) %>%
    tidyr::drop_na() %>%
    tibble::as_tibble() %>%
    dplyr::mutate(Label       = dplyr::recode(label,       !!!recode_vec),
                  Fmask4      = dplyr::recode(Fmask4,      !!!recode_vec),
                  MAJA        = dplyr::recode(MAJA,        !!!recode_vec),
                  s2cloudless = dplyr::recode(s2cloudless, !!!recode_vec),
                  Sen2Cor     = dplyr::recode(Sen2Cor,     !!!recode_vec)) %>%
    dplyr::select(mission, level, tile, img_date, Label, Fmask4, MAJA, Sen2Cor,
                  s2cloudless) %>%
    ensurer::ensure_that(all(!is.na(.$Label)),
                         all(!is.na(.$Fmask4)),
                         all(!is.na(.$MAJA)),
                         all(!is.na(.$s2cloudless)),
                         all(!is.na(.$Sen2Cor)),
                         err_desc = "NAs found in analysis data!")

print("Total accuracy.")
data_tb %>%
    format_conmat() %>%
    (function(x){print(x, n = Inf); invisible(x)}) %>%
    readr::write_csv(path = paste0(basename(args[[1]]), ".csv"))
