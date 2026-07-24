setwd("C:/Users/Stuart/Downloads/pangenome")

if (!require("tidyverse")) install.packages("tidyverse")
if (!require("ggvenn")) install.packages("ggvenn")

install.packages("ggvenn", repos = "https://cloud.r-project.org")

library(tidyverse)
library(ggvenn)

rtab <- read_tsv("gene_presence_absence.Rtab",show_col_types = FALSE)

View(rtab)

sample_cols <- colnames(rtab)[-1]

View(sample_cols)


gene_sets <- map(sample_cols, function(col) {
  rtab$Gene[rtab[[col]] > 0]
})
names(gene_sets) <- sample_cols

print(gene_sets)

# Check it worked - should show actual gene names, not TRUE/FALSE
head(gene_sets$L_plantarum)

venn_plot <- ggvenn (
    gene_sets,
    fill_color = c("#1B9E77", "#D95F02", "#7570B3"),
    stroke_size = 0.5,
    set_name_size = 5,
    text_size = 4.5,
) +

labs(title = "Shared vs Species-Specific Genes (Pangenome)") +
  theme(plot.title = element_text(face = "bold", hjust = 0.5, size = 14))

ggsave("pangenome_venn.pdf", plot = venn_plot, width = 8, height = 5, dpi = 500)
print(venn_plot)

summary_df <- read_tsv(
    "summary_statistics.txt" , col_names = c("category", "range", "count")
) %>%
select(-range) %>%
filter(category %in% c("Core genes", "Soft core genes", "Shell genes", "Cloud genes")) %>%
mutate(category = factor(category, levels = c(
    "Core genes", "Soft core genes", "Shell genes", "Cloud genes"
)))

bar_plot <- ggplot(summary_df, aes(x = count , y = category , fill = category)) +
geom_col(width = 0.6) +
geom_text(aes(label = count), vjust = -0.4 , size = 4.5 , fontface = "bold") +
scale_fill_manual(values = c ("Core genes" = "#2E7D32", "Soft core genes" = "#66BB6A",
    "Shell genes" = "#F9A825", "Cloud genes" = "#C62828")) +
labs(
    title = "Pangenome Gene Category Breakdown",
    subtitle = "L. plantarum, L. brevis, B. animalis (Panaroo, strict mode)",
    x = NULL, y = "Number of genes"
  ) +
  labs(
    title = "Pangenome Gene Category Breakdown",
    subtitle = "L. plantarum, L. brevis, B. animalis (Panaroo, strict mode)",
    x = NULL, y = "Number of genes"
  ) +
  theme_minimal(base_size = 13) +
  theme(
    plot.title = element_text(face = "bold"),
    legend.position = "right",
    axis.text.x = element_text(angle = 20, hjust = 1)
  )

ggsave("pangenome_categories.png", plot = bar_plot, width = 8, height = 6, dpi = 300)
print(bar_plot)



bar_plot <- ggplot(summary_df, aes(x = count, y = category, fill = category)) +
  geom_col(width = 0.6) +
  geom_text(aes(label = count), hjust = -0.2, size = 4.5, fontface = "bold") +
  scale_fill_manual(values = c(
    "Core genes" = "#2E7D32", "Soft core genes" = "#66BB6A",
    "Shell genes" = "#F9A825", "Cloud genes" = "#C62828"
  )) +
  scale_y_discrete(limits = rev(c("Core genes", "Soft core genes", "Shell genes", "Cloud genes"))) +
  labs(
    title = "Pangenome Gene Category Breakdown",
    subtitle = "L. plantarum, L. brevis, B. animalis (Panaroo, strict mode)",
    x = "Number of genes", y = NULL
  ) +
  theme_minimal(base_size = 13) +
  theme(
    plot.title = element_text(face = "bold"),
    legend.position = "none",
    axis.text.y = element_text(face = "bold")
  )

print(bar_plot)

