library(ggplot2)
library(tidyr)
library(dplyr)
library(readr)
library(stringr)
library(tidyverse)
theme_set(theme_linedraw()) 

kRootDir <- '/Volumes/Samsung_T3/Annotated Cases'
setwd(kRootDir)

SplitPath <- function(path){
  split_path <- stringr::str_split(path, "/")
  samples <- purrr::map_chr(split_path, function(x) {
    tail(x, n = 3)[1]
  })
  setNames(path, samples)
}

ReadFile <- function(path, ...) {
  df <- read.delim(path, ...)
  if ("Intensity_Spot_" %in% colnames(df)) {
    df <- dplyr::rename(df, SpotIntensity = Intensity_Spot_, 
                        Intensity_Raw = Intensity_Raw_)
    df <- dplyr::filter(df, SpotCall == "Acc")
  }
  # df <- dplyr::select(df, SpotIntensity, Circularity)
  return(df)
}

filelist_Cy3 = SplitPath(
  list.files(kRootDir, pattern = "._localized_particles_experiment.txt", 
             recursive = TRUE, full.names = TRUE))
filelist_Cy5 = SplitPath(
  list.files(kRootDir, pattern = "._localized_particles_control.txt", 
             recursive = TRUE, full.names = TRUE))

df_Cy3 <- purrr::map_df(filelist_Cy3, ReadFile, na.strings = "", 
                        stringsAsFactors = FALSE, .id = "SampleName")
df_Cy5 <- purrr::map_df(filelist_Cy5, ReadFile, na.strings = "", 
                        stringsAsFactors = FALSE, .id = "SampleName")

df_Cy3 <- dplyr::mutate(df_Cy3, cell_tile = paste(tile, cell, SampleName, sep = '_'))
df_Cy5 <- dplyr::mutate(df_Cy5, cell_tile = paste(tile, cell, SampleName, sep = '_'))#%>%
#group_by(cell_tile)%>%
#mutate(avg_Cy5 = mean(SpotIntensity), med_Cy5 = median(SpotIntensity))
#df_Cy3 <- dplyr::full_join(df_Cy3, df_Cy5, by = "cell_tile")

summary_Cy5 <- df_Cy5%>%
  group_by(cell_tile)%>%
  dplyr::summarise(avg_Cy5 = mean(SpotIntensity), 
                   med_Cy5 = median(SpotIntensity), 
                   sd_Cy5 = sd(SpotIntensity))

summary_Cy3 <- df_Cy3%>%
  group_by(cell_tile, color, SampleName)%>%
  dplyr::summarise(avg_Cy3 = mean(SpotIntensity), 
                   sd_Cy3 = sd(SpotIntensity), 
                   avg_Cy3_norm = mean(Cy3_avgnorm))

df_Cy3 <- dplyr::full_join(df_Cy3, summary_Cy5, by = "cell_tile")
df_Cy3 <- df_Cy3 %>% 
  mutate(Cy3_avgnorm = SpotIntensity/avg_Cy5) #%>%
  #mutate(Cy3_mednorm = SpotIntensity/med_Cy5)

summary_spots <- dplyr::full_join(summary_Cy3, summary_Cy5, by = "cell_tile")

#keeps <- c('SampleName', 'X', 'Y', 
#           'SpotIntensity', 'Area', 'Perimeter', 
 #          'Circularity', 'SpotCall', 'color', 'cell_tile', 
  #         'avg_Cy5', 'med_Cy5', 'sd_Cy5', 'Cy3_avgnorm', 'Cy3_mednorm')

#test <- which(summary_Cy3$color == 'green'& summary_Cy3$SampleName == 'T17-118014_Piece_01')
#length(test)

write.table(df_Cy3, "AllCy3_spots.txt", sep="\t",quote = FALSE, row.names = FALSE)
write.table(df_Cy5, "AllCy5_spots.txt", sep="\t", quote = FALSE, row.names = FALSE)
write.table(summary_spots, "All_spots_summarized.txt", sep="\t", quote = FALSE, row.names = FALSE)

test_g <- subset(df_Cy3, color == 'green')
test_g <- ecdf(test_g$SpotIntensity)
test_r <- subset(df_Cy3, color == 'red')
test_r <- ecdf(test_r$SpotIntensity)
plot(test_g, col = "green")
plot(test_r, col = "red", add = TRUE)

# only annotated ones
df_Cy3 %>%
  dplyr::filter(color != "") %>%
  ggplot(aes(y=Cy3_avgnorm, x = color, fill = color)) + 
  geom_boxplot() +
  scale_y_continuous(trans = scales::log2_trans())+
  scale_fill_manual(values = c("blue" = "navy", "red" = "red", 
                               "green" = "green", "orange" = "orange"),
                    name = "cell types")+
  facet_wrap(~ SampleName) +
  theme_bw()

# summary plot
summary_spots %>%
  dplyr::mutate(SampleName = factor(SampleName,
                                    levels = c("T16-119468_Piece_02", 
                                               "T17-20901_Piece_01",
                                               "T16-126258A_Piece_02",
                                               "T16-97347_Piece_02",
                                               "T17-26455B_Piece_02",
                                               "T17-28040A_Piece_01",
                                               "T17-118014_Piece_01"))) %>%
  dplyr::filter(color != "") %>%
  ggplot(aes(y=avg_Cy3_norm, x = SampleName, fill = color)) + 
  geom_boxplot() +
  scale_y_continuous(trans = scales::log2_trans())+
  scale_fill_manual(values = c("blue" = "navy", "red" = "red", 
                               "green" = "green", "orange" = "orange"),
                    name = "cell types")+
  facet_wrap(~ color) +
  theme_bw()

# summary plot #2
summary_spots %>%
  dplyr::mutate(SampleName = factor(SampleName,
                                    levels = c("T16-119468_Piece_02", 
                                               "T17-20901_Piece_01",
                                               "T16-126258A_Piece_02",
                                               "T16-97347_Piece_02",
                                               "T17-26455B_Piece_02",
                                               "T17-28040A_Piece_01",
                                               "T17-118014_Piece_01"))) %>%
  dplyr::filter(color != "") %>%
  ggplot(aes(y=avg_Cy3_norm, x = color, fill = color)) + 
  geom_boxplot() +
  scale_y_continuous(trans = scales::log2_trans())+
  scale_fill_manual(values = c("blue" = "navy", "red" = "red", 
                               "green" = "green", "orange" = "orange"),
                    name = "cell types")+
  facet_wrap(~ SampleName, ncol = 7) +
  labs(y = "normalized telomere signal")+
  theme_bw() +theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank())


# overlay attempt
df_Cy3 %>%
  dplyr::filter(color != "") %>%
  ggplot(aes(x=Cy3_mednorm)) + 
  geom_histogram(data = subset(df_Cy3, color == 'red'), fill = "red", binwidth = 0.02, alpha = 0.6) +
  geom_histogram(data = subset(df_Cy3, color == 'green'), fill = "green", binwidth = 0.02, alpha = 0.7) +
  geom_histogram(data = subset(df_Cy3, color == 'blue'), fill = "navy", binwidth = 0.02, alpha = 0.8) +
  geom_histogram(data = subset(df_Cy3, color == 'orange'), fill = "orange", binwidth = 0.02, alpha = 0.8) +
  facet_wrap(~ SampleName) +
  theme_bw()