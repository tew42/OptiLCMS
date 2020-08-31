#' Data inspectation
#' @description This functions provide a path for users to visually inspect their raw data before the data
#' trimming so as to remove the dirty or significantly uneluted peaks.
#' @param datapath Character, the path of the raw MS data files (.mzXML, .CDF and .mzML)
#' for the visual and intuitive data inspectation or the file folder (if only a folder path provided, the first file will
#' be inspected).
#' @param rt.range Numerics, a congregation of two values to define the lower and upper RT range (seconds) for
#' users to inspect. This is an optional parameter, if absent, will display the MS of the whole RT range.
#' @param mz.range Numerics, a congregation of two values to define the lower and upper mz range for
#' users to inspect. This is an optional parameter, if absent, will display the MS of the whole mz range.
#' @param dimension Character, the dimension for sample to display, including '2D' or '3D'. The default is '3D'.
#' @param res Numeric, the resolution for data inspectation. The larger the value, the higher the resolution.
#' The default value is 100. This value is usually clearly enough and also give consideration to the speed.
#' @export
#' @import MSnbase
#' @author Zhiqiang Pang \email{zhiqiang.pang@mail.mcgill.ca} Jeff Xia \email{jeff.xia@mcgill.ca}
#' Mcgill University
#' License: GNU GPL (>= 2)
PerformDataInspect <-
  function(datapath = NULL,
           rt.range,
           mz.range,
           dimension = "3D",
           res = 100) {
    
    if (datapath == "null" | is.null(datapath)) {
      if (.on.public.web & dir.exists("upload/QC")) {
        datapath <- "upload/QC"
        datapath <- paste0(fullUserPath, datapath)
      } else if (.on.public.web) {
        datapath <- paste0("upload/", list.files("upload", recursive = T)[1])
        datapath <- paste0(fullUserPath, datapath)
      } else {
        print("Local Inspectation !")
      }
    } else {
      files <-
        list.files(paste0(getwd(), "/upload/"),
                   full.names = T,
                   recursive = T)
      
      
      if (isEmpty(files)) {
        # Handle the example issue - show other files
        files <-
          list.files(
            "/home/glassfish/projects/MetaboDemoRawData/upload/",
            full.names = T,
            recursive = T
          )
        datapath =  files[datapath == basename(files)]
        
      } else {
        # Handle the regular data insepctation
        datapath =  files[datapath == basename(files)]
      }
      
    }
    
    suppressMessages(require("MSnbase"))
    
    if (basename(datapath) == "NA") {
      # Handle the example issue - default showing
      datapath <-
        "/home/glassfish/projects/MetaboDemoRawData/upload/QC"
    }
    
    if (!grepl(pattern = c("*.mzXML"), basename(datapath)) &
        !grepl(pattern = c("*.mzML"), basename(datapath)) &
        !grepl(pattern = c("*.CDF"), basename(datapath)) &
        !grepl(pattern = c("*.cdf"), basename(datapath))) {
      print(paste("First file in ", datapath, " will be inspected !"))
      mzf <- list.files(datapath, recursive = F, full.names = T)[1]
    } else {
      mzf <- datapath
    }
    
    if (grepl(pattern = c("*.CDF"), basename(mzf)) |
        grepl(pattern = c("*.cdf"), basename(mzf))) {
      # centroid_cdf();
      return()
    }
    
    ms <- openMSfile(mzf)
    hd <- header(ms)
    
    ms1 <- which(hd$msLevel == 1)
    
    if (missing(rt.range) | (rt.range[1] == 0 & rt.range[2] == 0)) {
      rtsel <-
        hd$retentionTime[ms1] > min(hd$retentionTime) &
        hd$retentionTime[ms1] < max(hd$retentionTime)
      
      rt.extension <- F
      print(paste(
        "RT range is:",
        min(hd$retentionTime),
        "and",
        max(hd$retentionTime),
        "seconds !"
      ))
      
    } else{
      if (rt.range[2] < rt.range[1]) {
        a1 <- rt.range[1]
        rt.range[1] <- rt.range[2]
        rt.range[2] <- a1
      } else if (rt.range[2] == rt.range[1]) {
        rt.range[2] <- rt.range[2] + 1
        rt.range[1] <- rt.range[1] - 1
      }
      print(paste("RT range is:", rt.range[1], "and", rt.range[2], "seconds !"))
      
      rtsel <-
        hd$retentionTime[ms1] > rt.range[1] &
        hd$retentionTime[ms1] < rt.range[2]
      
      rt.min <- min(hd$retentionTime[ms1])
      rt.max <- max(hd$retentionTime[ms1])
      
      if (rt.range[1] < rt.min | rt.range[2] > rt.max) {
        rt.extension <- T
      } else {
        rt.extension <- F
      }
    }
    if (missing(mz.range) | (mz.range[1] == 0 & mz.range[2] == 0)) {
      min.mz <- min(hd$lowMZ)
      max.mz <- max(hd$highMZ)
      
      if (min.mz == 0 & max.mz == 0 | min.mz == max.mz) {
        print(
          "mz.range information is missing in your data file. mz between 100 and 1200 will be shown here !"
        )
        min.mz <- 100
        max.mz <- 1200
        
      } else if (is.infinite(min.mz) |
                 is.infinite(max.mz) | min.mz == -1 | max.mz == -1) {
        print(
          "mz.range information is missing in your data file. mz between 50 and 2000 will be shown here !"
        )
        min.mz <- 50
        max.mz <- 2000
      }
      
      print(paste("MZ range is:", min.mz, "and", max.mz, "Thomson !"))
      
      res.mz <- (max.mz - min.mz) / res
      M <- MSmap(ms,
                 ms1[rtsel],
                 min.mz,
                 max.mz,
                 res.mz,
                 hd,
                 zeroIsNA = TRUE)
      
    } else{
      if (mz.range[2] < mz.range[1]) {
        a1 <- mz.range[1]
        mz.range[1] <- mz.range[2]
        mz.range[2] <- a1
      } else if (mz.range[2] == mz.range[1]) {
        mz.range[2] <- mz.range[2] + 0.01
        mz.range[1] <- mz.range[1] - 0.01
      }
      
      print(paste("MZ range is:", mz.range[1], "and", mz.range[2], "Thomson !"))
      
      res.mz <- (mz.range[2] - mz.range[1]) / res
      M <- MSmap(ms,
                 ms1[rtsel],
                 mz.range[1],
                 mz.range[2],
                 res.mz,
                 hd,
                 zeroIsNA = TRUE)
    }
    
    if (rt.extension) {
      if (min(M@rt) > rt.range[1]) {
        M@rt <- c(rt.range[1], M@rt)
        M@map <- rbind(rep(NA, dim(M@map)[2]), M@map)
        M@ms <- c(M@ms, 1)
      }
      
      if (max(M@rt) < rt.range[2]) {
        M@rt <- c(M@rt, rt.range[2])
        M@map <- rbind(M@map, rep(NA, dim(M@map)[2]))
        M@ms <- c(M@ms, 1)
      }
    }
    
    if (missing(dimension)) {
      dimension = "3D"
    }
    
    FN <- tools::file_path_sans_ext(basename(mzf))
    
    filename <-
      paste0(
        FN,
        "_mz_",
        mz.range[1],
        "_",
        mz.range[2],
        "_RT_",
        rt.range[1],
        "_",
        rt.range[2],
        dimension,
        ".png"
      )
    
    
    Cairo::Cairo(
      file = filename,
      unit = "in",
      dpi = 72,
      width = 7,
      height = 7,
      type = "png",
      bg = "white"
    )
    
    par(mfrow = c(1, 2))
    
    if (dimension == "3D") {
      print(plot.MS_3D(M))
    } else {
      print(plot(M, aspect = 1, allTicks = FALSE))
    }
    
    dev.off()
    
    return(filename)
  }


#' Set generic Plotting Parameters
#' @description This function sets the generic Plotting Parameters for different functions
#' @param Plot Logical, if true, the function will plot internal figures for different functions.
#' @param labels Logical, if true, the labels in the plot will be added.
#' @param format Numeric, input the format of the image to create.
#' @param dpi Numeric, input the dpi of the image to create.
#' @param width Numeric, input the width of the image to create.
#' @param ... Other specific parameters for specific function. Please set them according to the corresponding function.
#' @author Zhiqiang Pang \email{zhiqiang.pang@mail.mcgill.ca}, and Jeff Xia \email{jeff.xia@mcgill.ca}
#' McGill University, Canada
#' License: GNU GPL (>= 2)
#' @export
SetPlotParam <-
  function(Plot = F,
           labels = TRUE,
           format = "png",
           dpi = 72,
           width = 9,
           ...) {
    return(list(
      Plot = Plot,
      labels = labels,
      format = format,
      dpi = dpi,
      width = width,
      ...
    ))
  }

#' Plot EIC
#' @description This functionn creates an extracted ion chromatogram (EIC) for a specific
#' m/z and retention time. This is used for quality-control of raw m/s data.
#' @param raw_data The object created using the ImportRawMSData function,
#' containing the raw MS data.
#' @param rt_mn Numeric, specify the minimum bound of the retention time range.
#' @param rt_mx Numeric, specify the maximum bound of the retention time range.
#' @param mz_mn Numeric, specify the minimum bound of the m/z range.
#' @param mz_mx Numeric, specify the maximum bound of the m/z range.
#' @param aggreg Character, if "sum", creates a total ion chromatogram.
#' If "max", creates a base peak chromatogram. By default it is set
#' to "sum".
#' @param format Character, input the format of the image to create.
#' @param dpi Numeric, input the dpi of the image to create.
#' @param width Numeric, input the width of the image to create.
#' @export
PlotXIC <-
  function(featureNum,
           sample_labeled,
           Group_labeled,
           format,
           dpi,
           width,
           height) {
    # Parameters initialization
    if (missing(sample_labeled)) {
      sample_labeled <- FALSE
    }
    if (missing(Group_labeled)) {
      Group_labeled <- TRUE
    }
    if (missing(format)) {
      format <- "png"
    }
    if (missing(dpi)) {
      dpi <- 72
    }
    if (missing(width)) {
      width <- 6
    }
    if (missing(height)) {
      height <- width * 1.05
    }
    
    # Load data results
    load("mSet.rda")
    
    require("MSnbase")
    
    
    raw_data <- mSet[["onDiskData"]]
    raw_data@featureData$retentionTime <-
      unlist(mSet[["msFeatureData"]][["adjustedRT"]])
    
    # Get groups information
    groupsInfo <- raw_data@phenoData@data[["sample_group"]]
    group_levels <- levels(groupsInfo)
    
    groupsInfo <-
      sapply(
        group_levels,
        FUN = function(x) {
          which(x == groupsInfo)
        }
      )
    
    samples_names <- raw_data@phenoData@data[["sample_name"]]
    
    # Get current feature information
    peak_idx_current <-
      mSet[["FeatureGroupTable"]]@listData[["peakidx"]][[featureNum]]
    
    #peak_table <- mSet[["msFeatureData"]][["chromPeaks"]][peak_idx_current,];
    peak_table <- mSet[["xcmsSet"]]@peaks[peak_idx_current,]
    peak_table <- peakTableSUM(peak_table)
    
    rtrange <-
      c(mSet[["FeatureGroupTable"]]@listData[["rtmin"]][featureNum] - 10,
        mSet[["FeatureGroupTable"]]@listData[["rtmax"]][featureNum] + 10)
    
    mzrange <-
      c(mSet[["FeatureGroupTable"]]@listData[["mzmin"]][featureNum] - 0.2,
        mSet[["FeatureGroupTable"]]@listData[["mzmax"]][featureNum] + 0.2)
    
    RawData <- filterMz(filterRt(raw_data, rtrange), mzrange)
    
    title <-
      paste0(round(mSet[["FeatureGroupTable"]]@listData[["mzmed"]][[featureNum]], 4),
             "mz@",
             round(mSet[["FeatureGroupTable"]]@listData[["rtmed"]][[featureNum]], 2),
             "s")
    
    
    # Get feature details as a list in MSdb
    MSdb0 <- MSdb <- IntoLists <- IntoListg <- list()
    
    for (i in group_levels) {
      IntoListg[[i]] <- 0
      #Different groups
      if (class(groupsInfo)[1] == "list") {
        array_sample <- groupsInfo[[i]]
      } else {
        array_sample <- groupsInfo[, i]
      }
      nc <- 0
      
      for (x in array_sample) {
        #Different samples per group
        sample_idx <- which(x == peak_table[, "sample"])
        
        #print(paste0("sample_idx: ",x, sample_idx))
        for (j in sample_idx) {
          #Multiple features in corresponding sample  - extract a little bit more
          mzr <-
            c(peak_table[j, 2] - 0.001, peak_table[j, 3] + 0.001)
          rtr <- c(peak_table[j, 5] - 0.1, peak_table[j, 6] + 0.1)
          IntoListg[[i]] <- IntoListg[[i]] +  peak_table[j, 7]
          IntoLists[[i]][[samples_names[x]]] <- peak_table[j, 7]
          
          MSdb0[[samples_names[x]]] <-
            chromatogram(
              RawData,
              mz = mzr,
              rt = rtr,
              aggregationFun = "max"
            )[[x]]
          
          nc <- nc + 1
        }
      }
      # Do the average on the same group
      if (nc != 0) {
        IntoListg[[i]] <- IntoListg[[i]] / nc
      } else {
        IntoListg[[i]] <- 0.0
      }
      
      if (!identical(MSdb0, list())) {
        MSdb[[i]] <- MSdb0
        MSdb0 <- list()
      }
      
    }
    
    ## PLotting sample EIC begin -
    
    res0 <- lapply(
      MSdb,
      FUN = function(x) {
        res_sample <- data.frame()
        
        if (length(x) != 0) {
          for (j in 1:length(x)) {
            res_sample <- rbind(res_sample,
                                data.frame(x[[j]]@rtime, x[[j]]@intensity, rep(names(x)[j], length(x[[j]]@rtime))))
          }
        }
        
        res_sample[is.na(res_sample)] <- 0
        return(res_sample)
      }
    )
    
    res <- data.frame()
    
    for (w in 1:length(res0)) {
      ncouts <- nrow(res0[[w]])
      
      resds <-
        cbind(res0[[w]], rep(names(res0)[w], nrow(res0[[w]])), rep(NA, ncouts))
      
      for (ww in 1:length(unique(resds[, 3]))) {
        cn <- unique(resds[, 3])[ww]
        cint <- IntoLists[[w]][cn == names(IntoLists[[w]])]
        resds[resds[, 3] == cn,][which(resds[resds[, 3] == cn, 2] == max(resds[resds[, 3] == cn, 2])), 5] <-
          formatC(cint[[1]], format = "e", digits = 2)
      }
      
      res <- rbind(res, resds)
    }
    
    colnames(res) <-
      c("RT", "Intensity", "Samples", "Groups", "Labels")
    
    peak_width <- max(res$RT) - min(res$RT)
    
    require(ggplot2)
    require(ggrepel)
    
    Cairo::Cairo(
      file = paste0("EIC_", title, "_sample_", dpi, ".", format),
      unit = "in",
      dpi = dpi,
      width = width,
      height = height,
      type = format,
      bg = "white"
    )
    
    s_image <-
      ggplot(res, aes(x = RT, y = Intensity, color = Samples)) + #geom_line() #+
      stat_smooth(
        geom = 'area',
        method = "loess",
        se = F,
        span = 0.4,
        size = 0.35,
        formula = "y ~ x",
        alpha = 1 / 4,
        aes(fill = Samples)
      ) +
      theme_bw() +
      ylim(0, NA) +
      xlim(min(res$RT) - peak_width * 0.05 , max(res$RT) + peak_width * 0.35) +
      theme(
        legend.position = c(0.87, 0.85),
        plot.title = element_text(
          size = 12,
          face = "bold",
          hjust = 0.5
        ),
        legend.title = element_text(size = 8.5),
        legend.text = element_text(size = 8),
        legend.key.size = unit(3, "mm")
      ) +
      ggtitle(title)
    
    if (sample_labeled) {
      s_image <-
        s_image + geom_text_repel(aes(y = Intensity * 0.2, label = Labels),
                                  force = 1.5,
                                  show.legend = FALSE)
    }
    
    print(s_image)
    dev.off()
    ## PLotting sample EIC finished -
    
    ## PLotting group EIC begin --
    res <- NULL
    res <- lapply(MSdb, featureSUM, frtr = rtrange)
    
    if (any(sapply(res, is.null))) {
      res <- res[-which(sapply(res, is.null))]
    }
    
    res_data <- data.frame()
    
    for (k in 1:length(res)) {
      ncout <- nrow(res[[k]])
      
      resd <-
        cbind(res[[k]], rep(names(res[k]), ncout), rep(NA, ncout))
      
      resd[which(resd$Inten_mean == max(resd$Inten_mean)), 4] <-
        formatC(IntoListg[[k]], format = "e", digits = 2)
      
      res_data <- rbind(res_data, resd)
    }
    
    colnames(res_data) <- c("RT", "Intensity", "Groups", "Labels")
    rownames(res_data) <- NULL
    peak_width <- max(res_data$RT) - min(res_data$RT)
    
    Cairo::Cairo(
      file = paste0("EIC_", title, "_group_", dpi, ".", format),
      unit = "in",
      dpi = dpi,
      width = width,
      height = height,
      type = format,
      bg = "white"
    )
    
    g_image <-
      ggplot(res_data, aes(x = RT, y = Intensity, color = Groups)) + #geom_line() +
      stat_smooth(
        geom = 'area',
        method = "loess",
        se = F,
        span = 0.4,
        size = 0.35,
        formula = "y ~ x",
        alpha = 1 / 4,
        aes(fill = Groups)
      ) +
      theme_bw() +
      ylim(0, NA) +
      xlim(min(res_data$RT) - peak_width * 0.75 ,
           max(res_data$RT) + peak_width * 0.75) +
      theme(
        legend.position = c(0.85, 0.88),
        plot.title = element_text(
          size = 12,
          face = "bold",
          hjust = 0.5
        ),
        legend.title = element_text(size = 9),
        legend.text = element_text(size = 9),
        legend.key.size = unit(4, "mm")
      ) +
      ggtitle(title)
    
    if (Group_labeled) {
      g_image <-
        g_image + geom_text_repel(aes(y = Intensity * 0.2, label = Labels),
                                  force = 1.5,
                                  show.legend = FALSE)
    }
    
    print(g_image)
    dev.off()
    
    ## PLotting group EIC finished --
    return(title)
  }


#' Title
#'
#' @param mSet
#' @param imgName
#' @param format
#' @param dpi
#' @param width
#'
#' @return
#' @export
#'
#' @examples
PlotSpectraInsensityStistics <-
  function(mSet,
           imgName,
           format = "png",
           dpi = 72,
           width = NA) {
    sample_idx <- mSet[["onDiskData"]]@phenoData@data[["sample_group"]]
    
    sample_num <-
      mSet[["onDiskData"]]@phenoData@data[["sample_name"]]
    
    Cairo::Cairo(
      file = imgName,
      unit = "in",
      dpi = dpi,
      width = width,
      height = length(sample_num) * 0.65,
      type = format,
      bg = "white"
    )
    
    if (length(unique(sample_idx)) > 9) {
      col.fun <-
        grDevices::colorRampPalette(RColorBrewer::brewer.pal(12, "Set3"))
      group_colors <- col.fun(length(unique(sample_idx)))
      
    } else{
      group_colors <-
        paste0(RColorBrewer::brewer.pal(9, "Set1")[1:length(unique(sample_idx))], "60")
    }
    
    ints <-
      split(log2(mSet[["msFeatureData"]][["chromPeaks"]][, "into"]),
            f = mSet[["msFeatureData"]][["chromPeaks"]][, "sample"])
    
    names(ints) <- as.character(sample_num)
    
    group_colors <-
      sapply(
        seq(length(levels(sample_idx))),
        FUN = function(x) {
          rep(group_colors[x], length(sample_idx[sample_idx == levels(sample_idx)[x]]))
        }
      )
    
    op <- par(mar = c(3.5, 10, 4, 1.5), xaxt = "s")
    
    boxplot(
      ints,
      varwidth = TRUE,
      col = as.character(unlist(group_colors)),
      ylab = "",
      horizontal = TRUE,
      las = 2,
      main = expression(log[2] ~ intensity),
      cex.lab = 0.8,
      cex.main = 1.25
    )
    
    #title(ylab=expression(log[2]~intensity), line=7.5, cex.lab=1.2)
    grid(nx = NA, ny = NULL)
    
    dev.off()
  }


#' Title
#'
#' @param mSet
#' @param imgName
#' @param format
#' @param dpi
#' @param width
#'
#' @return
#' @export
#'
#' @examples
PlotSpectraPCA <-
  function(mSet,
           imgName,
           format = "png",
           dpi = 72,
           width = NA) {
    Cairo::Cairo(
      file = imgName,
      unit = "in",
      dpi = dpi,
      width = width,
      height = width * 0.80,
      type = format,
      bg = "white"
    )
    
    sample_idx <-
      mSet[["onDiskData"]]@phenoData@data[["sample_group"]]
    
    feature_value <-
      .feature_values(
        pks = mSet[["msFeatureData"]][["chromPeaks"]],
        fts = mSet[["FeatureGroupTable"]],
        method = "medret",
        value = "into",
        intensity = "into",
        colnames = mSet[["onDiskData"]]@phenoData@data[["sample_name"]],
        missing = NA
      )
    
    pca_feats <- log2(feature_value)
    
    if (nrow(feature_value) < 2) {
      MessageOutput(
        mes =  paste0(
          "<font color=\"red\">",
          "\nERROR: No enough peaks detected, please adjust your parameters or use other Peak/Alignment method",
          "</font>"
        ),
        ecol = "\n",
        progress = 65
      )
      
      dev.off()
      return(NULL)
    }
    
    df0 <- na.omit(pca_feats)
    
    df1 <- df0[is.finite(rowSums(df0)),]
    df <- t(df1)
    
    mSet_pca <- prcomp(df, center = TRUE, scale = T)
    sum.pca <- summary(mSet_pca)
    var.pca <-
      sum.pca$importance[2,] # variance explained by each PCA
    
    xlabel <- paste("PC1", "(", round(100 * var.pca[1], 1), "%)")
    ylabel <- paste("PC2", "(", round(100 * var.pca[2], 1), "%)")
    
    # using ggplot2
    df <- as.data.frame(mSet_pca$x)
    df$group <- sample_idx
    
    require("ggrepel")
    
    if (nrow(df) < 30) {
      if (length(unique(sample_idx)) > 9) {
        col.fun <-
          grDevices::colorRampPalette(RColorBrewer::brewer.pal(12, "Set3"))
        p <-
          ggplot2::ggplot(df, aes(
            x = PC1,
            y = PC2,
            color = group,
            label = row.names(df)
          )) +
          geom_text_repel(force = 1.5) + geom_point(size = 5) + fill = col.fun(length(unique(sample_idx))) + theme(axis.text =
                                                                                                                     element_text(size = 12))
        
      } else{
        p <-
          ggplot2::ggplot(df, aes(
            x = PC1,
            y = PC2,
            color = group,
            label = row.names(df)
          )) +
          geom_text_repel(force = 1.5) + geom_point(size = 5) + scale_color_brewer(palette =
                                                                                     "Set1") + theme(axis.text = element_text(size = 12))
      }
      
    } else {
      if (length(unique(sample_idx)) > 9) {
        p <-
          ggplot2::ggplot(df, aes(x = PC1,
                                  y = PC2,
                                  color = group)) + geom_point(size = 5)
        
      } else{
        p <-
          ggplot2::ggplot(df, aes(x = PC1,
                                  y = PC2,
                                  color = group)) + geom_point(size = 5) + scale_color_brewer(palette = "Set1")
      }
    }
    
    p <-
      p + xlab(xlabel) + ylab(ylabel) + theme_bw() + theme(axis.title = element_text(size =
                                                                                       12))
    print(p)
    dev.off()
  }


#' Title
#'
#' @param mSet
#' @param imgName
#' @param format
#' @param dpi
#' @param width
#'
#' @return
#' @export
#'
#' @examples
PlotSpectraRTadj <-
  function(mSet,
           imgName,
           format = "png",
           dpi = 72,
           width = NA) {
    sample_idx <- mSet[["onDiskData"]]@phenoData@data[["sample_group"]]
    
    Cairo::Cairo(
      file = imgName,
      unit = "in",
      dpi = dpi,
      width = width,
      height = width * 0.75,
      type = format,
      bg = "white"
    )
    
    if (length(unique(sample_idx)) > 9) {
      col.fun <-
        grDevices::colorRampPalette(RColorBrewer::brewer.pal(12, "Set3"))
      group_colors <- col.fun(length(unique(sample_idx)))
    } else{
      group_colors <-
        paste0(RColorBrewer::brewer.pal(9, "Set1")[1:length(unique(sample_idx))], "60")
    }
    
    names(group_colors) <- unique(sample_idx)
    
    ## Extract RT information
    rt.set <-
      list(mSet[["xcmsSet"]]@rt$raw, unlist(mSet[["xcmsSet"]]@rt$corrected))
    
    diffRt <- rt.set[[2]] - rt.set[[1]]
    diffRt <- split(diffRt, fromFile(mSet$onDiskData))
    xRt <- mSet[["msFeatureData"]][["adjustedRT"]]
    col = group_colors[sample_idx]
    lty = 1
    lwd = 1
    col <- rep(col, length(diffRt))
    lty <- rep(lty, length(diffRt))
    lwd <- rep(lwd, length(diffRt))
    ylim <- range(diffRt, na.rm = TRUE)
    
    plot(
      3,
      3,
      pch = NA,
      xlim = range(xRt, na.rm = TRUE),
      ylim = ylim,
      xlab = "RT_adj",
      ylab = "RT_diff"
    )
    
    for (i in 1:length(diffRt)) {
      points(
        x = xRt[[i]],
        y = diffRt[[i]],
        col = col[i],
        lty = lty[i],
        type = "l",
        lwd = lwd[i]
      )
    }
    
    rawRt <-
      split(mSet[["xcmsSet"]]@rt$raw, fromFile(mSet$onDiskData))
    
    adjRt <- xRt
    
    ####
    peaks_0 <- mSet[["msFeatureData"]][["chromPeaks"]]
    subs <-
      seq_along(mSet[["onDiskData"]]@phenoData@data[["sample_name"]])
    ####
    pkGroup <- mSet[["msFeatureData"]][["pkGrpMat_Raw"]]
    ####
    
    rawRt <- rawRt[subs]
    adjRt <- adjRt[subs]
    ## Have to "adjust" these:
    pkGroupAdj <- pkGroup
    if (!is.null(pkGroup)) {
      for (i in 1:ncol(pkGroup)) {
        pkGroupAdj[, i] <-
          .applyRtAdjustment(pkGroup[, i], rawRt[[i]], adjRt[[i]])
      }
      
      diffRt <- pkGroupAdj - pkGroup
      xRt <- pkGroupAdj
      
      ## Loop through the rows and plot points - ordered by diffRt!
      for (i in 1:nrow(xRt)) {
        idx <- order(diffRt[i, ])
        points(
          x = xRt[i, ][idx],
          diffRt[i, ][idx],
          col = "#00000080",
          type = "b",
          pch = 16,
          lty = 3
        )
      }
      
    }
    
    legend(
      "topright",
      legend = unique(sample_idx),
      pch = 15,
      col = group_colors
    )
    
    dev.off()
  }

#' Title
#'
#' @param mSet
#' @param imgName
#' @param format
#' @param dpi
#' @param width
#'
#' @return
#' @export
#'
#' @examples
PlotSpectraBPIadj <-
  function(mSet,
           imgName,
           format = "png",
           dpi = 72,
           width = NA) {
    Cairo::Cairo(
      file = imgName,
      unit = "in",
      dpi = dpi,
      width = width,
      height = width * 0.618,
      type = format,
      bg = "white"
    )
    
    sample_idx <-
      mSet[["onDiskData"]]@phenoData@data[["sample_group"]]
    
    
    if (length(unique(sample_idx)) > 9) {
      col.fun <-
        grDevices::colorRampPalette(RColorBrewer::brewer.pal(12, "Set3"))
      group_colors <- col.fun(length(unique(sample_idx)))
      
    } else{
      group_colors <-
        paste0(RColorBrewer::brewer.pal(9, "Set1")[1:length(unique(sample_idx))], "60")
    }
    group_colors2 <- group_colors
    
    names(group_colors2) <- unique(sample_idx)
    
    
    group_colors <-
      sapply(
        seq(length(levels(sample_idx))),
        FUN = function(x) {
          rep(group_colors[x], length(sample_idx[sample_idx == levels(sample_idx)[x]]))
        }
      )
    
    object_od <- mSet$onDiskData
    adj_rt <- unlist(mSet$msFeatureData$adjustedRT)
    
    object_od <- selectFeatureData(
      object_od,
      fcol = c(
        "fileIdx",
        "spIdx",
        "seqNum",
        "acquisitionNum",
        "msLevel",
        "polarity",
        "retentionTime",
        "precursorScanNum"
      )
    )
    object_od@featureData$retentionTime <- adj_rt
    
    res <- MSnbase::chromatogram(
      object_od,
      aggregationFun = "max",
      missing = NA_real_,
      msLevel = 1,
      BPPARAM = bpparam()
    )
    
    plot(res, col = as.character(unlist(group_colors)))
    
    legend(
      "topright",
      legend = unique(sample_idx),
      pch = 15,
      col = group_colors2
    )
    
    dev.off()
  }

#' Title
#'
#' @param FeatureNM
#' @param dpi
#' @param format
#'
#' @return
#' @export
#'
#' @examples
plotMSfeature <- function(FeatureNM,
                          dpi = 72,
                          format = "png") {
  require(ggplot2)
  require(RColorBrewer)
  
  peakdata <- readRDS("annotated_peaklist.rds")
  
  peakdata1 <-
    peakdata[, c(-1:-6,-ncol(peakdata),-ncol(peakdata) + 1,-ncol(peakdata) + 2)]
  
  peakdata1[is.na(peakdata1)] <- 0
  
  group_info <- read.csv("metaboanalyst_input.csv")[c(1),-1]
  
  data_table <-
    as.data.frame(t(rbind(
      round(as.numeric(peakdata1[FeatureNM,]), 1), as.character(as.matrix(group_info))
    )))
  
  data_table[, 1] <- as.numeric(data_table[, 1])
  colnames(data_table) <- c("value", "Group")
  rownames(data_table) <- NULL
  title = paste0(round(peakdata[FeatureNM, 1], 4), "mz@", round(peakdata[FeatureNM, 4], 2), "s")
  
  Cairo::Cairo(
    file = paste0(title, ".png"),
    unit = "in",
    dpi = dpi,
    width = 6,
    height = 6.18,
    type = format,
    bg = "white"
  )
  
  p1 <-
    ggplot(data_table, aes(
      x = Group,
      y = log2(value + 1),
      fill = Group
    )) + # geom_violin(trim = T,draw_quantiles = T) +
    stat_boxplot(geom = "errorbar", width = 0.15, aes(color = "black")) +
    geom_boxplot(
      size = 0.35,
      width = 0.5,
      fill = "white",
      outlier.fill = "white",
      outlier.color = "white"
    ) +
    geom_jitter(aes(fill = Group),
                width = 0.2,
                shape = 21,
                size = 2.5) +
    scale_color_manual(
      values = c(
        "black",
        "black",
        "black",
        "black",
        "black",
        "black",
        "black",
        "black",
        "black",
        "black",
        "black",
        "black",
        "black"
      )
    ) +
    theme_bw() +
    theme(
      legend.position = "none",
      axis.text.x = element_text(
        family = "Arial",
        size = 12,
        angle = 45,
        hjust = 1
      ),
      axis.text.y = element_text(
        family = "Arial",
        size = 12,
        face = "plain"
      ),
      axis.title.y = element_text(
        family = "Arial",
        size = 16,
        face = "plain"
      ),
      axis.title.x = element_text(
        family = "Arial",
        size = 16,
        face = "plain"
      ),
      plot.title = element_text(
        family = "Arial",
        size = 16,
        face = "bold",
        hjust = 0.5
      )
    ) +
    ylab(expression(log[2] ~ intensity)) + xlab("Groups") + ggtitle(title)
  
  print(p1)
  dev.off()
  
  return(paste0(title, ".png"))
}



#' plotSingleTIC
#'
#' @param filename
#' @param imagename
#'
#' @return
#' @export
#'
#' @examples
plotSingleTIC <- function(filename, imagename) {
  load_msnbase()
  
  load("raw_data_filt.rda")
  load("tics.rda")
  
  file_order <-
    which(filename == raw_data_filt@phenoData@data[["sample_name"]])
  
  Cairo::Cairo(
    file = paste0(imagename, ".png"),
    unit = "in",
    dpi = 72,
    width = 7,
    height = 5,
    type = "png",
    bg = "white"
  )
  
  plot(tics[[file_order]], col = "#0080FF", main = filename)
  dev.off()
}