#' @title Add user and producer accuracies to a confusion matrix.
#' @author Alber Sanchez, \email{alber.ipia@@inpe.br}
#' @description Add user and produser accuracies to a confusion matrix.
#'
#' @param conmat A confusion matrix or a list.
#' @return       The conmat with an extra row and column, or a list.
add_upacc <- function(conmat){
    if (is.matrix(conmat)) {
        stopifnot(nrow(conmat) == ncol(conmat))
        ac_mat <- asses_accuracy_simple(conmat)
        cmat <- cbind(conmat, ac_mat$user)
        cmat <- rbind(cmat, c(ac_mat$producer, ac_mat$overall))
        colnames(cmat)[ncol(cmat)] <- "user_acc"
        rownames(cmat)[nrow(cmat)] <- "prod_acc"
        return(cmat)
    }else if (is.list(conmat)) {
        return(lapply(conmat, add_upacc))
    }else {
        stop("Unknow type of argument")
    }
}


#' @title Asses accuracy and estimate area according to Olofsson.
#' @author Alber Sanchez, \email{alber.ipia@@inpe.br}
#' @description Compute the accuracy normalized by the area. Note that, these
#'              computations don't work on clustered sampling.
#'
#' @param confusion_matrix A matrix given in sample counts. Columns represent
#'                         the reference data and rows the results of the
#'                         classification.
#' @param label_areas      A named vector of the total area of each label on the
#'                         map.
#' @return                 A tibble of the label areas, their inferior and
#'                         superior 95% confidence interval, and the
#'                         area-adjusted overall, user, and producer accuracies.
#' @export
asses_accuracy_area <- function(confusion_matrix, label_areas){

    stopifnot(length(colnames(confusion_matrix)) > 0 && length(rownames(confusion_matrix)) > 0)
    stopifnot(sum(colnames(confusion_matrix) == rownames(confusion_matrix)) == length(colnames(confusion_matrix))) # the order of columns and rows do not match
    stopifnot(all(colnames(confusion_matrix) %in% names(label_areas))) # do names match?
    stopifnot(all(names(label_areas) %in% colnames(confusion_matrix))) # do names match?
    label_areas <- label_areas[colnames(confusion_matrix)] # re-order elements
    stopifnot(all(colnames(confusion_matrix) == names(label_areas))) # do names' positions match?

    W <- label_areas/sum(label_areas)
    #W.mat <- matrix(rep(W, times = ncol(confusion_matrix)), ncol = ncol(confusion_matrix))
    n <- rowSums(confusion_matrix)
    n.mat <- matrix(rep(n, times = ncol(confusion_matrix)), ncol = ncol(confusion_matrix))
    p <- W * confusion_matrix / n.mat                                             # estimated area proportions
    # rowSums(p) * sum(label_areas)                                               # class areas according to the map, that is, the label_areas vector
    error_adjusted_area_estimate <- colSums(p) * sum(label_areas)                 # class areas according to the reference data
    Sphat_1 <- vapply(1:ncol(confusion_matrix), function(i){                      # S(phat_1) - The standard error of the area estimative is given as a function area proportions and sample counts
        sqrt(sum(W^2 * confusion_matrix[, i]/n * (1 - confusion_matrix[, i]/n)/(n - 1)))
    }, numeric(1))
    #
    SAhat <- sum(label_areas) * Sphat_1                                           # S(Ahat_1) - Standard error of the area estimate
    Ahat_sup <- error_adjusted_area_estimate + 2 * SAhat                          # Ahat_1 - 95% superior confidence interval
    Ahat_inf <- error_adjusted_area_estimate - 2 * SAhat                          # Ahat_1 - 95% inferior confidence interval
    Ohat <- sum(diag(p))                                                          # Ohat   - Overall accuracy
    Uhat <- diag(p) / rowSums(p)                                                  # Uhat_i - User accuracy
    Phat <- diag(p) / colSums(p)                                                  # Phat_i - Producer accuracy
    #
    value <- NULL
    label_areas %>%
        names() %>%
        tibble::enframe(name = NULL) %>%
        dplyr::rename(label = value) %>%
        dplyr::mutate(area = label_areas,
                      a_conf95_inf = Ahat_inf,
                      a_conf95_sup = Ahat_sup,
                      overall  = Ohat,
                      user     = Uhat,
                      producer = Phat) %>%
        return()
}


#' @title Asses accuracy.
#' @author Alber Sanchez, \email{alber.ipia@@inpe.br}
#' @description Compute the overall, user, and producer accuracies.
#'
#' @param confusion_matrix A matrix given in sample counts. Columns represent the reference data and rows the results of the classification.
#' @return                 A tibble with the f1 score along the overall, user, and producer accuracies.
asses_accuracy_simple <- function(confusion_matrix){
    overall <- producer <- user <- f1_score <- NULL
    confusion_matrix %>%
        compute_f1() %>%
        dplyr::mutate(overall  = sum(diag(confusion_matrix)) / sum(confusion_matrix),
                      producer = diag(confusion_matrix)      / colSums(confusion_matrix),
                      user     = diag(confusion_matrix)      / rowSums(confusion_matrix)) %>%
        dplyr::select(label, f1_score, overall, user, producer) %>%
        return()
}


#' @title Compute the F1 score.
#' @author Alber Sanchez, \email{alber.ipia@@inpe.br}
#' @description Compute the F1 score from a confusion matrix.
#'
#' @param confusion_matrix A matrix given in sample counts. Columns represent the reference data and rows the results of the classification.
#' @return                 A tibble with precision, recall and f1 score.
compute_f1 <- function(confusion_matrix){
    # cm <- matrix(c(24, 2,  1, 3, 30,  4, 0,  5, 31), byrow = TRUE, ncol = 3)
    # f1_score(cm)
    # precision recall    f1
    # <dbl>  <dbl> <dbl>
    # 1     0.889  0.889 0.889
    # 2     0.811  0.811 0.811
    # 3     0.861  0.861 0.861
    precision <- diag(confusion_matrix)/colSums(confusion_matrix)
    recall    <- diag(confusion_matrix)/rowSums(confusion_matrix)
    f1_score <- 2 * precision * recall/(precision + recall)
    return(tibble::tibble(label = names(f1_score), precision, recall, f1_score))
}


#' @title Export a table to a latex file.
#' @author Alber Sanchez, \email{alber.ipia@@inpe.br}
#' @description Save an object as a latex table in latex format.
#'
#' @param filter_chr     A length-one character. This is used to filter data_tb using the column filter_var.
#' @param filter_var     A obj. A column in data_tb.
#' @param prediction_var An obj. A column in data_tb.
#' @param reference_var  An obj. A column in data_tb.
#' @param data          A tibble.
#' @param caption_chr    A lenght-one character. A caption for a TEX table.
#' @param tex_dir        A lenght-one character. Path to a directory for storing TEX files.
confusion_matrix2tex <- function(filter_chr, filter_var, prediction_var,
                                 reference_var, data,  caption_chr, tex_dir){

    filter_var     <- rlang::enquo(filter_var)
    prediction_var <- rlang::enquo(prediction_var)
    reference_var  <- rlang::enquo(reference_var)

    cloud_detector <- as.character(rlang::get_expr(prediction_var))
    recode_expert2thing <- recode_experts_detector(cloud_detector)

    data_tb %>%
        dplyr::filter(!!filter_var == filter_chr) %>%
        dplyr::select(!!reference_var, !!prediction_var) %>%
        dplyr::mutate(!!reference_var := recode_expert2thing(dplyr::pull(., !!reference_var))) %>%
        get_confusion_matrix(prediction = !!prediction_var,
                             reference = !!reference_var) %>%
        table_to_latex(file_path = file.path(tex_dir,
                                             paste0("confusion_matrix_",
                                                    cloud_detector, "_",
                                                    stringr::str_replace(filter_chr, " ", "-"),
                                                    ".tex")),
                       caption = sprintf(caption_chr, cloud_detector,
                                         filter_chr))
}


#' @title List the files in a directory.
#' @author Alber Sanchez, \email{alber.ipia@@inpe.br}
#' @description List the files in the given directory matching a pattern.
#'
#' @param in_dir  A length-one character. A path to a directory.
#' @param patterh A length-one character. A pattern to match.
#' @return        A character.
find_files <- function(in_dir, pattern){
    res <- in_dir %>%
        list.files(pattern, full.names = TRUE, recursive = TRUE)
    if (length(res) == 0)
        return(NA)
    return(res)
}




#' @title Find the maks files in the given directory.
#' @author Alber Sanchez, \email{alber.ipia@@inpe.br}
#' @description Find the maks files in the given directory.
#'
#' @param base_dir      Directory with Sentinel images.
#' @param mask_patthern Pattern of the file names of the cloud masks.
#' @return        A character.
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






#' @title Format the accuracy matrix of a detector.
#' @author Alber Sanchez, \email{alber.ipia@@inpe.br}
#' @description Format the accuracy matrix of a detector.
#'
#' @param .data  A tibble representing the confusion matrix of a cloud-detecting algorithm.
#' @param suffix A length-one character. A suffix to be appended to the colum names.
#' @return       A tibble.
format_accuracy <- function(.data, suffix){
    test <- NULL
    producer_acc <- .data %>%
        dplyr::slice(nrow(.)) %>%
        dplyr::select(-1) %>%
        unlist() %>%
        tibble::enframe() %>%
        dplyr::select(-1) %>%
        dplyr::rename("prod_acc" = 1)
    .data %>%
        dplyr::select(1, ncol(.)) %>%
        dplyr::mutate(test = replace(test, test == "prod_acc", "overall_acc")) %>%
        dplyr::bind_cols(producer_acc) %>%
        magrittr::set_colnames(c(colnames(.)[1], paste(colnames(.)[-1], suffix, sep = '_'))) %>%
        return()
}


#' @title Compute and format confusion matrices.
#' @author Alber Sanchez, \email{alber.ipia@@inpe.br}
#' @description Compute and format the confusion matrix of each detector.
#'
#' @param .data A tibble with tile, image date, fmask4, maja, s2cloudless, and sen2cor.
#' @return      A tibble.
format_conmat <- function(.data){

    fmask4_acc <- .data %>%
        get_confusion_matrix(prediction_var = Fmask4, reference_var = Label) %>%
        magrittr::extract2("table") %>%
        asses_accuracy_simple() %>%
        magrittr::set_names(c(names(.)[1], paste0("Fmask4_", names(.)[-1])))
    maja_acc <- .data %>%
        get_confusion_matrix(prediction_var = MAJA, reference_var = Label) %>%
        magrittr::extract2("table") %>%
        asses_accuracy_simple() %>%
        magrittr::set_names(c(names(.)[1], paste0("MAJA_", names(.)[-1])))
    s2cloud_acc <- .data %>%
        get_confusion_matrix(prediction_var = s2cloudless, reference_var = Label) %>%
        magrittr::extract2("table") %>%
        asses_accuracy_simple() %>%
        magrittr::set_names(c(names(.)[1], paste0("s2cloudless_", names(.)[-1])))
    sen2cor_acc <- .data %>%
        get_confusion_matrix(prediction_var = Sen2Cor, reference_var = Label) %>%
        magrittr::extract2("table") %>%
        asses_accuracy_simple() %>%
        magrittr::set_names(c(names(.)[1], paste0("Sen2Cor_", names(.)[-1])))

    fmask4_acc %>%
        dplyr::left_join(maja_acc, by = "label") %>%
        dplyr::left_join(s2cloud_acc, by = "label") %>%
        dplyr::left_join(sen2cor_acc, by = "label") %>%
    return()
}


#' @title Format a tibble of frequencies of a cloud detection algorithm.
#' @author Alber Sanchez, \email{alber.ipia@@inpe.br}
#' @description Save an object as a latex table in latex format.
#'
#' @param .data    A tibble.
#' @param detector An object. The name of a column in .data.
format_freq <- function(.data, detector) {
    detector <- rlang::enquo(detector)
    .data %>%
        dplyr::select(tile, img_date, !!detector) %>%
        tidyr::unnest(!!detector) %>%
        dplyr::mutate(detector = rlang::quo_name(detector)) %>%
        dplyr::rename(label = 3, total = 4) %>%
        return()
}


#' @title Compute the confusion matrix.
#' @author Alber Sanchez, \email{alber.ipia@@inpe.br}
#' @description Compute the confusion matrix along the overall, user, and producer accuracies.
#'
#' @param conmat A confusion matrix or a list.
#' @return       A tibble with the reference data in the columns and the test in the rows.
#'               The last row and column have the producer and user accuracies respectively.
#'               The overall accuracy is in the last diagonal cell.
.get_accuracy <- function(.data, detector){
    expert <- NULL
    detector <- rlang::enquo(detector)
    res <- .data %>%
        dplyr::select(expert, !!detector) %>%
        get_confusion_matrix(prediction = !!detector, reference = expert)

    res %>%
        magrittr::extract2("table") %>%
        add_upacc() %>%
        tibble::as_tibble(rownames = "test") %>%
        tibble::as_tibble() %>%
        return()
}


#' @title Compute a consfusion matrix.
#' @author Alber Sanchez, \email{alber.ipia@@inpe.br}
#' @description Compute a confusion matrix from the input data.
#'
#' @param obj            A tibble.
#' @param prediction_var An object. A column in obj.
#' @param reference_var  An object. A column in obj.
#' @return               A confusion matrix object (from the caret package).
get_confusion_matrix <- function(data_tb, prediction_var, reference_var) {
    prediction_var <- rlang::enquo(prediction_var)
    reference_var  <- rlang::enquo(reference_var)

    prediction_vector <- data_tb %>%
        dplyr::pull(!!prediction_var)
    reference_vector <- data_tb %>%
        dplyr::pull(!!reference_var)

    factor_labels <- c(prediction_vector, reference_vector) %>%
        unique() %>%
        sort()

    #  Handle the special case of perfect prediction of a single label.
    if (length(factor_labels) == 1) {
        res <- list("positive" = NA, "table" = NA, "overall" = NA,
                    "byClass" = NA, "mode" = NA, "dots" = NA)
        res[["table"]] <- reference_vector %>%
            length() %>%
            as.matrix() %>%
            magrittr::set_colnames(factor_labels[1]) %>%
            magrittr::set_rownames(factor_labels[1])
        return(res)
    }

    if (length(factor_labels) < 2) {
        warning("Not enough levels for factor.")
        return(NA)
    }

    caret::confusionMatrix(factor(prediction_vector, levels = factor_labels),
                           factor(reference_vector,  levels = factor_labels)) %>%
        return()
}


#' @title Get all the labels used by the experts.
#' @author Alber Sanchez, \email{alber.ipia@@inpe.br}
#' @description Get all the labels used by the experts.
#'
#' @param expert_sf A sf object.
#' @param col_name   An  object. Name of the coded column in samples_sf.
#' @return           A sf object.
get_expert_labels <- function(expert_sf){
    expert <- label <- samples_sf <- samples_tb <- NULL
    expert_sf %>%
        dplyr::mutate(samples_tb = purrr::map(samples_sf, sf::st_set_geometry,
                                              value = NULL)) %>%
        dplyr::pull(samples_tb) %>%
        dplyr::bind_rows() %>%
        {
            if ("label" %in% names(.))
                return(dplyr::pull(., label))
            if ("expert" %in% names(.))
                return(dplyr::pull(., expert))
        } %>%
        unique() %>%
        sort() %>%
        return()
}


#' @title Get the labels from the polygons to the points.
#' @author Alber Sanchez, \email{alber.ipia@@inpe.br}
#' @description Intersect points and polygongs, getting a label in the latter
#' for the former.
#'
#' @param point_sf    A sf object of point geometry.
#' @param polygon_sf  A sf object of polygon geometry.
#' @param polygon_var The name of a variable in polygon_sf.
#' @return           A sf object.
get_label <- function(point_sf, polygon_sf, polygon_var){
    polygon_var <- rlang::enquo(polygon_var)
    point_sf %>%
        sf::st_transform(crs = sf::st_crs(polygon_sf)) %>%
        sf::st_intersection(dplyr::select(polygon_sf, !!polygon_var)) %>%
        return()
}


#' @title Get the labels from the raster to the points.
#' @author Alber Sanchez, \email{alber.ipia@@inpe.br}
#' @description Intersect points and raster, getting a label in the latter
#' for the former.
#'
#' @param point_sf   A sf object of point geometry.
#' @param raster_obj A raster object.
#' @param new_col    An object. Name of the new colum where the raster values are stored.
#' @return           A sf object.
get_label_raster <- function(point_sf, raster_obj, new_col){
    new_col <- rlang::enquo(new_col)
    point_sp <- point_sf %>%
        sf::st_transform(crs = raster::crs(raster_obj)) %>%
        as("Spatial") %>%
        sp::SpatialPoints()
    raster_obj %>%
        raster::extract(point_sp, sp = TRUE) %>%
        sf::st_as_sf() %>%
        dplyr::rename(!!new_col := 1) %>%
        return()
}


#' @title Compute the frequencies of a raster.
#' @author Alber Sanchez, \email{alber.ipia@@inpe.br}
#' @description Compute the frequencies of a raster.
#'
#' @param r        A raster.
#' @param detector A length-one character. The name of a cloud detection algorithm.
#' @return         A tibble.
get_raster_freq <- function(r, detector){
    detector <- rlang::enquo(detector)
    detector <- rlang::quo_name(detector)
    stopifnot(detector %in% c("fmask4", "maja", "s2cloudless", "sen2cor"))
    recode_detector <- NULL
    if (detector == "fmask4")
        recode_detector <- recode_fmask4
    if (detector == "maja")
        recode_detector <- recode_maja
    if (detector == "s2cloudless")
        recode_detector <- recode_s2cloudless
    if (detector == "sen2cor")
        recode_detector <- recode_sen2cor
    # Compute frequencies.
    res <- r %>%
        raster::freq() %>%
        tibble::as_tibble() %>%
        dplyr::mutate(label = recode_detector(value)) %>%
        dplyr::group_by(label) %>%
        dplyr::summarise(total = sum(count))
    # Add missing labels.
    labels <- c("cirrus", "clear", "cloud", "shadow", NA)
    missing_labels <-  labels[!(labels %in% res$label)]
    if (length(missing_labels) > 0) {
        res <- missing_labels %>%
            tibble::enframe(name = NULL) %>%
            dplyr::rename(label = value) %>%
            dplyr::mutate(total = 0) %>%
            dplyr::select(label, total) %>%
            dplyr::bind_rows(res)
    }
    #colnames(res) <- paste(colnames(res), detector, sep = '_')
    return(res)
}


#' @title Match landsat scenes to sentinel tiles.
#' @author Alber Sanchez, \email{alber.ipia@@inpe.br}
#' @description Match landsat scenes to sentinel tiles.
#'
#' @param tile_path  A length-one character. Path to a shapefile of Sentinel tiles.
#' @param scene_path A length-one character. Path to a shapefile of Landsat
#' scenes (Worldwide Reference System).
#' @param tiles      A character. A subset of tiles to be matched. i.e. "22MCA".
#' @param scenes     A character. A subset of scenes to match. i.e. "226064".
#' @return           A tibble.
match_scenes2tiles <- function(tile_path, scene_path, tiles = NULL,
                               scenes = NULL, mode = "D") {

    Name <- PATH <- ROW <- scene <- tile <- NULL
    sentinel_shp <- tile_path %>%
        sf::st_read(quiet = TRUE, stringsAsFactors = FALSE) %>%
        dplyr::rename(tile = Name) %>%
        {if (is.null(tiles)) return(.) else dplyr::filter(., tile %in% tiles)}

    landsat_shp <- scene_path %>%
        sf::st_read(quiet = TRUE, stringsAsFactors = FALSE) %>%
        dplyr::mutate(scene = stringr::str_c(stringr::str_pad(PATH, 3, pad = "0"),
                                             stringr::str_pad(ROW, 3, pad = "0"))) %>%
        sf::st_transform(crs = sf::st_crs(sentinel_shp)$proj4string) %>%
        dplyr::filter(MODE == mode) %>%
        {if (is.null(scenes)) return(.) else dplyr::filter(., scene %in% scenes)}

    sf::st_intersection(sentinel_shp, landsat_shp) %>%
        sf::st_set_geometry(NULL) %>%
        dplyr::as_tibble() %>%
        dplyr::select(tile, scene) %>%
        #tidyr::nest(scene = c("scene")) %>%
        return()
}


#' @title Get the metadata of the sample point shapefiles.
#' @author Alber Sanchez, \email{alber.ipia@@inpe.br}
#' @description Get the metadata of the sample point shapefiles.
#'
#' @param dir_path  Path to a directory with shapefiles.
#' @return          A sf object.
get_sample_shps <- function(dir_path) {
    dir_path %>%
        list.files(pattern = "[.]shp$", full.names = TRUE) %>%
        ensurer::ensure_that(length(.) > 0,
                             err_desc = "No shapefiles found") %>%
        tibble::enframe(name = NULL) %>%
        dplyr::rename(file_path = value) %>%
        dplyr::mutate(file_name = tools::file_path_sans_ext(basename(file_path))) %>%
        tidyr::separate(col = file_name, into = c("mission", "level", "tile",
                                                  NA, "img_date")) %>%
        return()
}


#' @title Merge PRODES tiles.
#' @author Alber Sanchez, \email{alber.ipia@@inpe.br}
#' @description Merge PRODES tiles into a single object.
#'
#' @param scene     A tibble of Landsat scenes to merge. It must have path and
#' row columns.
#' @param prodes_tb A tibble. One row for each PRODES tile. It must have path
#' path, and prodes (sf object) columns.
#' @param srs       A coordinate reference system.
#' @return          A sf object.
merge_prodes_scenes <- function(scene, prodes_tb, srs = NULL){
    prodes <- prodes_proj <- NULL
    res <- scene %>%
        dplyr::left_join(prodes_tb, by = c("path", "row")) %>%
        {if (is.null(srs))
            dplyr::mutate(., prodes_proj = prodes)
         else
            dplyr::mutate(., prodes_proj = purrr::map(.$prodes,
                                                   sf::st_transform,
                                                   crs = srs))
        }
    return(do.call(rbind, dplyr::pull(res, prodes_proj)))
}

# Multiple plot function
# Taken from http://www.cookbook-r.com/Graphs/Multiple_graphs_on_one_page_(ggplot2)/
#
# ggplot objects can be passed in ..., or to plotlist (as a list of ggplot objects)
# - cols:   Number of columns in layout
# - layout: A matrix specifying the layout. If present, 'cols' is ignored.
#
# If the layout is something like matrix(c(1,2,3,3), nrow=2, byrow=TRUE),
# then plot 1 will go in the upper left, 2 will go in the upper right, and
# 3 will go all the way across the bottom.
#
multiplot <- function(..., plotlist = NULL, file, cols = 1, layout = NULL) {
    library(grid)

    # Make a list from the ... arguments and plotlist
    plots <- c(list(...), plotlist)

    numPlots = length(plots)

    # If layout is NULL, then use 'cols' to determine layout
    if (is.null(layout)) {
        # Make the panel
        # ncol: Number of columns of plots
        # nrow: Number of rows needed, calculated from # of cols
        layout <- matrix(seq(1, cols * ceiling(numPlots/cols)),
                         ncol = cols, nrow = ceiling(numPlots/cols))
    }

    if (numPlots == 1) {
        print(plots[[1]])
    } else {
        # Set up the page
        grid.newpage()
        pushViewport(viewport(layout = grid.layout(nrow(layout), ncol(layout))))

        # Make each plot, in the correct location
        for (i in 1:numPlots) {
            # Get the i,j matrix positions of the regions that contain this subplot
            matchidx <- as.data.frame(which(layout == i, arr.ind = TRUE))

            print(plots[[i]], vp = viewport(layout.pos.row = matchidx$row,
                                            layout.pos.col = matchidx$col))
        }
    }
}


#' @title Format the plots of pixels' class per image.
#' @author Alber Sanchez, \email{alber.ipia@@inpe.br}
#' @description Format the plots of pixels' class per image.
#'
#' @param .data A tibble with images' tiles, dates, labels, number of pixels per
#'              label, and cloud detector algorithm (tile, img_date, label,
#'              total, detector).
#' @return      A plot object.
plot_image_pixels <- function(.data, title, legend = FALSE, xlabel = FALSE,
                              ylabel = FALSE, only_legend = FALSE){
    detector <- img_date <- tile <- total <- NULL
    res <- .data %>%
        ggplot2::ggplot() +
        ggplot2::geom_bar(mapping = ggplot2::aes(x = img_date,
                                                 y = total/1000000,
                                                 fill = Label),
                          position = "dodge",
                          stat = "identity") +
        ggplot2::facet_wrap(dplyr::vars(tile, detector), ncol = 1) +
        ggplot2::theme(axis.text.x = ggplot2::element_text(angle = -90,
                                                           hjust = 0,
                                                           size = 10),
                       axis.text.y = ggplot2::element_text(size = 10),
                       axis.title.y = ggplot2::element_text(size = 14),
                       plot.margin = ggplot2::margin(1, 1, 1, 1)) +
        ggplot2::xlab("Image date.") +
        #ggplot2::scale_x_date(labels = scales::date_format("%Y-%m-%d")) +
        ggplot2::ylab("Number of pixels (millions).")
    if (only_legend)
        return(ggpubr::as_ggplot(ggpubr::get_legend(res)))
    if (!ylabel) {
        res <- res + ggplot2::theme(axis.title.y = element_blank(),
                                    axis.text.y  = element_blank(),
                                    axis.ticks.y = element_blank())
    }
    if (!xlabel)
        res <- res + ggplot2::theme(axis.title.x = element_blank())
    if (!legend)
        res <- res + ggplot2::theme(legend.position = "none")
    return(res)
}


#' @title Read a shapefile of sample points.
#' @author Alber Sanchez, \email{alber.ipia@@inpe.br}
#' @description Read a shapefile of sample points.
#'
#' @param in_path A length-one character. A path to a shapefile.
#' @return        An sf object.
read_samples <- function(in_path) {
    empty_geom <- NULL
    in_path %>%
        sf::read_sf(options = "ENCODING=latin1") %>%
        ensurer::ensure_that(ncol(.) == 3,
                             err_desc = sprintf("Invalid number of columns in %s",
                                                in_path)) %>%
        dplyr::rename(FID = 1, label = 2) %>%
        .recode_samples(coded_var = label) %>%
        dplyr::filter(!is.na(label)) %>%
        dplyr::mutate(empty_geom = st_is_empty(.)) %>%
        dplyr::filter(empty_geom == FALSE) %>%
        dplyr::select(-empty_geom) %>%
        return()
}


#' @title Recode the FMASK4 labels.
#' @author Alber Sanchez, \email{alber.ipia@@inpe.br}
#' @description Recode the FMASK4 mask labels.
#'
#' @param coded_vec  An integer vector. Coded values of a variable.
#' @return           A character vector.
recode_fmask4 <- function(coded_vec){
    # QIU, Shi; ZHU, Zhe; HE, Binbin. Fmask 4.0 Handbook. [s.l.: s.n.], 2018.
    # https://github.com/gersl/fmask
    # https://drive.google.com/drive/folders/1SXBnEBDJ1Kbv7IQ9qIgqloYHZfdP6O1O
    coded_vec %>%
        dplyr::recode(`0`   = "clear",       # "clear land pixel",
                      `1`   = "clear",       # "clear water pixel",
                      `2`   = "shadow",      # "cloud shadow",
                      `3`   = "clear",       # "snow",
                      `4`   = "cloud",       # "cloud",
                      `255` = NA_character_, # "no observation")) %>%
                      .default = NA_character_,
                      .missing = NA_character_) %>%
        return()
}


#' @title Recode the MAJA labels.
#' @author Alber Sanchez, \email{alber.ipia@@inpe.br}
#' @description Recode the MAJA mask labels.
#'
#' @param coded_vec An integer vector. .
#' @return          A character vector.
recode_maja <- function(coded_vec){
    #' @title Parse a MAJA mask value.
    #' @author Alber Sanchez, \email{alber.ipia@@inpe.br}
    #' @description Given a integer MAJA's mask value, returns its interpretation.
    #'
    #' @param value An integer.
    #' @return      A tibble.
    .parse_maja_mask <- function(value) {
        #' @title Test a value against a mask.
        #' @author Alber Sanchez, \email{alber.ipia@@inpe.br}
        #' @description Given a integer MAJA's mask value, returns its interpretation.
        #'
        #' @param true_value An integer. Representation of the TRUE value of a binary mask.
        #' @param value      An integer. Value to test.
        #' @return           A tibble.
        .test_mask <- function(true_value, value) {
            return(any(as.logical(intToBits(value) & intToBits(true_value))))
        }

        # MAJA's Native Sentinel-2 format
        # https://labo.obs-mip.fr/multitemp/sentinel-2/majas-native-sentinel-2-format/
        bit <- true_value <- NULL

        mask_tb <- tibble::tribble(~bit, ~description,
                                   0L,    "all clouds except the thinnest and all shadows",
                                   1L,    "all clouds (except the thinnest)",
                                   2L,    "cloud shadows cast by a detected cloud",
                                   3L,    "cloud shadows cast by a cloud outside image",
                                   4L,    "clouds detected via mono-temporal thresholds",
                                   5L,    "clouds detected via multi-temporal thresholds",
                                   6L,    "thinnest clouds",
                                   7L,    "high clouds detected by 1.38 µm") %>%
            dplyr::mutate(true_value = as.integer(2^bit))

        mask_tb %>%
            dplyr::mutate(result = purrr::map_lgl(true_value, .test_mask,
                                                  value = value)) %>%
            dplyr::select(-true_value) %>%
            return()
    }
    #' @title Map the MAJA mask values to a general set of labels.
    #' @author Alber Sanchez, \email{alber.ipia@@inpe.br}
    #' @description Map the MAJA mask values to a general set of labels.
    #'
    #' @param mask_tb A tibble.
    #' @return        A tibble.
    .map_maja <- function(mask_tb) {
        result <- NULL
        # bit                 0     1       2     3      4      5      6      7
        cirrus_pattern <- c(FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, TRUE,  FALSE)
        cloud_pattern  <- c(FALSE, TRUE,  FALSE, FALSE, TRUE,  TRUE,  TRUE,  TRUE)
        shadow_pattern <- c(FALSE, FALSE, TRUE,  TRUE,  FALSE, FALSE, FALSE, FALSE)
        maja_res <- mask_tb %>%
            dplyr::pull(result)
        if (any(maja_res & cirrus_pattern))
            return("cirrus")
        if (any(maja_res & cloud_pattern))
            return("cloud")
        if (any(maja_res & shadow_pattern))
            return("shadow")
        return("clear")
    }
    maja_recoded <- maja_results <- recoded_vec <- value <- NULL
    coded_vec %>%
        tibble::enframe(name = NULL) %>%
        dplyr::rename(recoded_vec = value) %>%
        dplyr::mutate(maja_results = purrr::map(recoded_vec, .parse_maja_mask)) %>%
        dplyr::mutate(maja_recoded = purrr::map_chr(maja_results, .map_maja)) %>%
        dplyr::pull(maja_recoded) %>%
        return()
}


#' @title Recode the S2CLOUDLESS labels.
#' @author Alber Sanchez, \email{alber.ipia@@inpe.br}
#' @description Recode the SEN2CLOUDLESS mask labels.
#'
#' @param coded_vec An integer vector. .
#' @return          A character vector.
recode_s2cloudless <- function(coded_vec){
    coded_vec %>%
        dplyr::recode(`0` = "clear",
                      `1` = "cloud",
                      .default = NA_character_,
                      .missing = NA_character_) %>%
        return()
}


#' @title Recode the SEN2COR labels.
#' @author Alber Sanchez, \email{alber.ipia@@inpe.br}
#' @description Recode the SEN2COR mask labels.
#'
#' @param coded_vec An integer vector. .
#' @return          A character vector.
recode_sen2cor <- function(coded_vec){
    # BAETENS, Louis; DESJARDINS, Camille; HAGOLLE, Olivier. Validation of
    # Copernicus Sentinel-2 Cloud Masks Obtained from MAJA, Sen2Cor, and FMask
    # Processors Using Reference Cloud Masks Generated with a Supervised Active
    # Learning Procedure. Remote Sensing, v. 11, n. 4, p. 433, 2019. Disponível
    # em: <http://www.mdpi.com/2072-4292/11/4/433>.
    coded_vec %>%
        dplyr::recode(`0`  = NA_character_, # "no data",
                      `1`  = NA_character_, # "saturated or defective",
                      `2`  = "shadow",      # "dark area pixels",
                      `3`  = "shadow",      # "cloud shadows",
                      `4`  = "clear",       # "vegetation",
                      `5`  = "clear",       # "bare soils",
                      `6`  = "clear",       # "water",
                      `7`  = NA_character_, # "unclassified",
                      `8`  = "cloud",       # "cloud medium probability",
                      `9`  = "cloud",       # "cloud high probability",
                      `10` = "cirrus",      # "thin cirrus",
                      `11` = "clear",       # "snow"
                      .default = NA_character_,
                      .missing = NA_character_) %>%
        return()
}


#' @title Recode the PRODES labels.
#' @author Alber Sanchez, \email{alber.ipia@@inpe.br}
#' @description Recode the PRODES labels.
#'
#' @param samples_sf A sf object.
#' @param coded_var  An  object. Name of the coded column in samples_sf.
#' @return           A sf object.
recode_sf_prodes <- function(samples_sf, coded_var) {
    coded_var <- rlang::enquo(coded_var)
    samples_sf %>%
        dplyr::mutate(prodes = dplyr::recode(!!coded_var,
                                             "d2007"         = "deforestation",
                                             "d2008"         = "deforestation",
                                             "d2009"         = "deforestation",
                                             "d2010"         = "deforestation",
                                             "d2011"         = "deforestation",
                                             "d2012"         = "deforestation",
                                             "d2013"         = "deforestation",
                                             "d2014"         = "deforestation",
                                             "d2015"         = "deforestation",
                                             "d2016"         = "deforestation",
                                             "d2017"         = "deforestation",
                                             "r2007"         = "deforestation",
                                             "r2008"         = "deforestation",
                                             "r2009"         = "deforestation",
                                             "r2010"         = "deforestation",
                                             "r2011"         = "deforestation",
                                             "r2012"         = "deforestation",
                                             "r2013"         = "deforestation",
                                             "r2014"         = "deforestation",
                                             "r2015"         = "deforestation",
                                             "r2016"         = "deforestation",
                                             "r2017"         = "deforestation",
                                             "DESMATAMENTO"  = "deforestation",
                                             "RESIDUO"       = "deforestation",
                                             "FLORESTA"      = "forest",
                                             "NAO_FLORESTA"  = "no forest",
                                             "NAO_FLORESTA2" = "no forest",
                                             "HIDROGRAFIA"   = "water")) %>%
        return()
}


#' @title Recode the FMASK4 labels.
#' @author Alber Sanchez, \email{alber.ipia@@inpe.br}
#' @description Recode the FMASK4 mask labels.
#'
#' @param samples_sf A sf object.
#' @param coded_var  An  object. Name of the coded column in samples_sf.
#' @return           A sf object.
recode_sf_fmask4 <- function(samples_sf, coded_var){
    coded_var <- rlang::enquo(coded_var)
    samples_sf %>%
        dplyr::mutate(!!coded_var := recode_fmask4(!!coded_var)) %>%
        return()
}


#' @title Recode the MAJA labels.
#' @author Alber Sanchez, \email{alber.ipia@@inpe.br}
#' @description Recode the MAJA mask labels.
#'
#' @param samples_sf A sf object.
#' @param coded_var  An  object. Name of the coded column in samples_sf.
#' @return           A sf object.
recode_sf_maja <- function(samples_sf, coded_var){
    coded_var <- rlang::enquo(coded_var)
    samples_sf %>%
        dplyr::mutate(!!coded_var := recode_maja(!!coded_var)) %>%
        return()
}


#' @title Recode the S2CLOUDLESS labels.
#' @author Alber Sanchez, \email{alber.ipia@@inpe.br}
#' @description Recode the SEN2CLOUDLESS mask labels.
#'
#' @param samples_sf A sf object.
#' @param coded_var  An  object. Name of the coded column in samples_sf.
#' @return           A sf object.
recode_sf_s2cloudless <- function(samples_sf, coded_var){
    coded_var <- rlang::enquo(coded_var)
    samples_sf %>%
        dplyr::mutate(!!coded_var := recode_s2cloudless(!!coded_var)) %>%
        return()
}


#' @title Recode the SEN2COR labels.
#' @author Alber Sanchez, \email{alber.ipia@@inpe.br}
#' @description Recode the SEN2COR mask labels.
#'
#' @param samples_sf A sf object.
#' @param coded_var  An  object. Name of the coded column in samples_sf.
#' @return           A sf object.
recode_sf_sen2cor <- function(samples_sf, coded_var){
    coded_var <- rlang::enquo(coded_var)
    samples_sf %>%
        dplyr::mutate(!!coded_var := recode_sen2cor(!!coded_var)) %>%
        return()
}


#' @title Recode the URBAN labels.
#' @author Alber Sanchez, \email{alber.ipia@@inpe.br}
#' @description Recode the URBAN mask labels.
#'
#' @param samples_sf A sf object.
#' @param coded_var  An object. Name of the coded column in samples_sf.
#' @return           A sf object.
recode_sf_urban <- function(samples_sf, coded_var) {
    coded_var <- rlang::enquo(coded_var)
    samples_sf %>%
        .recode_int_lgl(!!coded_var) %>%
        return()
}


#' @title Recode the WATER labels.
#' @author Alber Sanchez, \email{alber.ipia@@inpe.br}
#' @description Recode the WATER mask labels.
#'
#' @param samples_sf A sf object.
#' @param coded_var  An object. Name of the coded column in samples_sf.
#' @return           A sf object.
recode_sf_water <- function(samples_sf, coded_var) {
    coded_var <- rlang::enquo(coded_var)
    samples_sf %>%
        .recode_int_lgl(!!coded_var) %>%
        return()
}


#' @title Export a table to a latex file.
#' @author Alber Sanchez, \email{alber.ipia@@inpe.br}
#' @description Save an object as a latex table in latex format.
#'
#' @param obj         A object.
#' @param out_file    A length-one character. Path to the output file.
#' @param caption_msg A length-one character. Table's caption.
#' @return            The input obj (invisible).
table_to_latex <- function(obj, out_file, caption_msg) {
    . <- NULL
    obj %>%
        {if ("table" %in% names(.))  magrittr::extract2(., "table") else  . } %>%
        xtable::xtable(caption = caption_msg,  type = "latex") %>%
        print(file = out_file)
    invisible(obj)
}


#' @title Recode an integer column into a logical.
#' @author Alber Sanchez, \email{alber.ipia@@inpe.br}
#' @description Recode an integer column into a logical.
#'
#' @param data_tb   A tibble.
#' @param coded_var An object. Name of the integer coded column in data_tb.
#' @return           A tibble.
.recode_int_lgl <- function(data_tb, coded_var){
    coded_var <- rlang::enquo(coded_var)
    data_tb %>%
        dplyr::mutate(!!coded_var := dplyr::recode(!!coded_var,
                                                   `0` = FALSE,
                                                   .default = TRUE,
                                                   .missing = NA)) %>%
        return()
}


#' @title Recode the labels given by experts.
#' @author Alber Sanchez, \email{alber.ipia@@inpe.br}
#' @description The experts give different labels with accents and typos. This
#' function cleans and merges them.
#'
#' @param samples_sf A sf object.
#' @param coded_var  An  object. Name of the coded column in samples_sf.
#' @return           A sf object.
.recode_samples <- function(samples_sf, coded_var) {
    coded_var <- rlang::enquo(coded_var)
    samples_sf %>%
        {
            # labels used by experts, including typos.
            # NOTE: It MUST match the recoding values!
            label_vector <- c("cirrus", "Cirrus", "claro", "clean", "clear",
                              "cloud", "Cloud", "fora", "Land", "nao nuvem",
                              "nao_nuvem", "não nuvem", "nuvem", "nï¿½o nuvem",
                              "nÃ£o nuvem",  "Nuvem", "other",  "others", "out",
                              "sem nuvem", "shadow", "Shadow", "shadow_new",
                              "sombra", "sombra_nuvem", "vloud") %>%
                sort()
            user_vector <- sort(unique(dplyr::pull(samples_sf, !!coded_var)))
            # Report any missing label in the data provided by the experts.
            if (any(!(user_vector %in% label_vector)))
                stop(sprintf("Missing labels found: %s \n",
                             user_vector[!(user_vector %in% label_vector)]))
            rm(label_vector, user_vector)
            invisible(.)
        } %>%
        dplyr::mutate(!!coded_var := dplyr::recode(!!coded_var,
                                               "cirrus"       = "cloud",
                                               "Cirrus"       = "cloud",
                                               "claro"        = "clear",
                                               "clean"        = "clear",
                                               "clear"        = "clear",
                                               "cloud"        = "cloud",
                                               "Cloud"        = "cloud",
                                               "fora"         = NA_character_,
                                               "Land"         = "clear",
                                               "nao nuvem"    = "clear",
                                               "nao_nuvem"    = "clear",
                                               "não nuvem"    = "clear",
                                               "nï¿½o nuvem"  = "clear",
                                               "nÃ£o nuvem"   = "clear",
                                               "nuvem"        = "cloud",
                                               "Nuvem"        = "cloud",
                                               "other"        = NA_character_,
                                               "others"       = NA_character_,
                                               "out"          = NA_character_,
                                               "sem nuvem"    = "clear",
                                               "shadow"       = "shadow",
                                               "Shadow"       = "shadow",
                                               "shadow_new"   = "shadow",
                                               "sombra"       = "shadow",
                                               "sombra_nuvem" = "shadow",
                                               "vloud"        = "cloud",
                                               .default       = "missing",
                                               .missing       = NA_character_)) %>%
        ensurer::ensure_that("missing" %in% unique(dplyr::pull(., !!coded_var)) == FALSE,
                             err_desc = "Unknown expert label!") %>%
        return()
}
