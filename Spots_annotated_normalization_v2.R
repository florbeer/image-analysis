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
  df <- read_tsv(path, col_types = cols(), ...)
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

df_Cy3 <- purrr::map_df(filelist_Cy3, ReadFile, .id = "SampleName")
df_Cy5 <- purrr::map_df(filelist_Cy5, ReadFile, .id = "SampleName")

df_Cy3 <- dplyr::mutate(df_Cy3, cell_tile = paste(tile, cell, SampleName, sep = '_'))
df_Cy5 <- dplyr::mutate(df_Cy5, cell_tile = paste(tile, cell, SampleName, sep = '_'))#%>%
#group_by(cell_tile)%>%
#mutate(avg_Cy5 = mean(Intensity_Spot_), med_Cy5 = median(Intensity_Spot_))
#df_Cy3 <- dplyr::full_join(df_Cy3, df_Cy5, by = "cell_tile")

summary_Cy5 <- df_Cy5%>%
  group_by(cell_tile)%>%
  dplyr::summarise(avg_Cy5 = mean(Intensity_Spot_), 
                   med_Cy5 = median(Intensity_Spot_), 
                   sd_Cy5 = sd(Intensity_Spot_))

summary_Cy3 <- df_Cy3%>%
  group_by(cell_tile, color, SampleName)%>%
  dplyr::summarise(avg_Cy3 = mean(Intensity_Spot_), sd_Cy3 = sd(Intensity_Spot_))

df_Cy3 <- dplyr::full_join(df_Cy3, summary_Cy5, by = "cell_tile")
df_Cy3 <- df_Cy3 %>% 
  mutate(Cy3_avgnorm = Intensity_Spot_/avg_Cy5) %>%
  mutate(Cy3_mednorm = Intensity_Spot_/med_Cy5)

summary_spots <- dplyr::full_join(summary_Cy3, summary_Cy5, by = "cell_tile")

#keeps <- c('SampleName', 'X', 'Y', 
#           'Intensity_Spot_', 'Area', 'Perimeter', 
 #          'Circularity', 'SpotCall', 'color', 'cell_tile', 
  #         'avg_Cy5', 'med_Cy5', 'sd_Cy5', 'Cy3_avgnorm', 'Cy3_mednorm')

#test <- which(summary_Cy3$color == 'green'& summary_Cy3$SampleName == 'T17-118014_Piece_01')
#length(test)

write.table(df_Cy3, "AllCy3_spots.txt", sep="\t",quote = FALSE, row.names = FALSE)
write.table(df_Cy5, "AllCy5_spots.txt", sep="\t", quote = FALSE, row.names = FALSE)
write.table(summary_spots, "All_spots_summarized.txt", sep="\t", quote = FALSE, row.names = FALSE)

test_g <- subset(df_Cy3, color == 'green')
test_g <- ecdf(test_g$Intensity_Spot_)
test_r <- subset(df_Cy3, color == 'red')
test_r <- ecdf(test_r$Intensity_Spot_)
plot(test_g, col = "green")
plot(test_r, col = "red", add = TRUE)

# only annotated ones
df_Cy3 %>%
  dplyr::filter(color != "") %>%
  ggplot(aes(y=Cy3_mednorm, x = color)) + 
  geom_boxplot() +
  scale_y_continuous(trans = scales::log2_trans())+
  facet_wrap(~ SampleName) +
  theme_bw()

# summary plot
summary_spots %>%
  dplyr::filter(color != "") %>%
  ggplot(aes(y=avg_Cy5, x = SampleName)) + 
  geom_boxplot() +
  scale_y_continuous(trans = scales::log2_trans())+
  facet_wrap(~ color) +
  theme_bw()

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