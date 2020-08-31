# Remove the labels from previous expert-labelling in order to prepare for a
# new labelling round.
library(dplyr)
library(sf)

base_path <- "/home/alber/Documents/ghProjects/compare-cloud-masks"

out_dir <- base_path %>%
    file.path("data/samples/cross_classification_clean")

# Remove attributes
clean_shp <- function(file_path, out_path){
    file_path %>%
        sf::read_sf() %>%
        dplyr::mutate(second_id = 1:dplyr::n(),
                      label2 = "") %>%
        dplyr::select(second_id, label2) %>%
        sf::st_write(out_path)
        return()
}

cloud_experts <- base_path %>%
    file.path("data", "samples", "point") %>%
    list.files(pattern = "[.]shp$", full.names = TRUE) %>%
    ensurer::ensure_that(length(.) > 0, err_desc = "No shapefiles found!") %>%
    tibble::enframe(name = NULL) %>%
    dplyr::rename(file_path = value) %>%
    dplyr::mutate(file_name = tools::file_path_sans_ext(basename(file_path))) %>%
    tidyr::separate(col = file_name, into = c("mission", "level", "tile", NA,
                                              "img_date")) %>%
    dplyr::filter((mission == "S2A" & tile == "T19LFK" & img_date %in% c("20161004T144732", "20170102T144722", "20180507T144731", "20181103T144731")) |
                  (mission == "S2A" & tile == "T20NPH" & img_date %in% c("20160901T143752", "20161110T143752", "20170218T143751", "20170718T143751")) |
                  (mission == "S2A" & tile == "T21LXH" & img_date %in% c("20170328T140051", "20180611T140051", "20180919T140051", "20181009T140051")) |
                  (mission == "S2A" & tile == "T22MCA" & img_date %in% c("20170603T135111", "20170623T135111", "20180419T135111", "20180628T135111")) |
                  (mission == "S2A" & tile == "T22NCG" & img_date %in% c("20160929T140052", "20161019T140052", "20170527T140101", "20170706T140051"))) %>%
    ensurer::ensure_that(nrow(.) == 20, err_desc = "Wrong number of shapefiles!") %>%
    dplyr::mutate(out_path = file.path(out_dir, basename(file_path))) %>%
    dplyr::mutate(sf = purrr::map2(file_path, out_path, clean_shp))
