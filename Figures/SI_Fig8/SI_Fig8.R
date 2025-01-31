# Packages ----------------------------------------------------------
library(tidyverse)
library(cowplot)
library(egg)
library(grid)
library(readxl)
theme_set(theme_cowplot())

# Plot filtering ----------------------------------------------------------
Incubation_time = 9.25 # The max incubation time for the x-axis

# General plotting customization -------------------------------------------------
Figure_height = 2.1
Figure_width = 3
Figure_label_size = 10
plot_width = 1
point_size = 0.5
text_size_axis_title = 8
text_size_axis_tick_labels = 8
axis_line_size = 0.75/(ggplot2::.pt*72.27/96) # pt size for the axis lines
axis_tick_size = 0.75/(ggplot2::.pt*72.27/96)
axis_tick_lengths = 0.03
x_axis_min = 0
x_axis_max = Incubation_time
x_axis_breaks = c(0,3,6,9)
x_axis_label = "Time (hrs)"

# Density plotting customization -------------------------------------------------
density_cell_colors <- c('firebrick1', 'darkorchid2', 'blue2') # the line colors for donor, recipient, and transconjugant trajectories
density_linetype = 'solid' # the linetype used to plot the density trajectories
density_line_size = 1/(ggplot2::.pt*72.27/96) # pt size for the density trajectories
density_y_axis_min = 1e4
density_y_axis_max = 1e10
density_y_axis_number_of_ticks = 4
density_height = 1
density_y_axis_label = expression(paste("Cell density (CFU ", 'ml'^-1, ")"))
density_x_axis_label = "Time (hr)"
# Growth plotting customization -------------------------------------------------
growth_y_axis_label = expression(paste("Growth rate (", 'hr'^-1, ")"))

# Density data -------------------------------------------------------------
dat <- read_xlsx("2021-08-09_plating_scheme_AMT.xlsx")
dat <- dat %>% 
  select(Day, Set, Experiment, Mixture, Replicate, Time, Dilution, Counts, Density) 
# Filtering data -------------------------------------------------------------
dat_f <- dat  %>%
  mutate(Counts = as.numeric(Counts)) %>% 
  filter(!is.na(Counts), Counts != 0) %>%
  group_by(Day, Set, Experiment, Time, Mixture) %>%
  summarise(N = n(), 
            Countmin = min(Counts),
            Countmax = max(Counts),
            CFUs = mean(Density),
            SD = sd(Density),
            SE = SD/sqrt(N))  %>%
  mutate(Time = as.numeric(Time))
# Analyzing data -------------------------------------------------------------
dat_g <- dat_f %>%
  arrange(Time) %>%
  group_by(Day, Set, Experiment, Mixture) %>%
  mutate(Growthrate = log((CFUs/lag(CFUs, default = first(CFUs))))/(Time-lag(Time, default = 0)))
dat_g$Set <- factor(x = dat_g$Set, levels = c("G", "DG", "D"))
write_csv(dat_g, file = "analyzed.csv")
# Density plot -------------------------------------------------------------
p1 <- ggplot(data = dat_g, aes(x = Time, y = CFUs, color = interaction(Set, Experiment, Mixture),
                              group = interaction(Set, Experiment, Mixture))) +
  geom_errorbar(aes(ymin=CFUs-SE, ymax=CFUs+SE, width = 0)) +
  geom_line(size = density_line_size, linetype = density_linetype) +
  geom_point(size = point_size) + 
  scale_color_manual(values = density_cell_colors) +
  scale_x_continuous(limits = c(x_axis_min, x_axis_max), breaks = x_axis_breaks)+
  scale_y_log10(limits = c(density_y_axis_min, density_y_axis_max), breaks = scales::trans_breaks("log10", function(x) 10^x, n = density_y_axis_number_of_ticks), labels = scales::trans_format("log10", scales::math_format(10^.x))) +
  ylab(density_y_axis_label) + 
  xlab(density_x_axis_label) + 
  theme(axis.title = element_text(size = text_size_axis_title)) +
  theme(axis.line.y = element_line(size = axis_line_size)) +
  theme(axis.line.x = element_line(size = axis_line_size)) +
  theme(axis.ticks = element_line(size = axis_tick_size))+
  theme(axis.ticks.length = unit(axis_tick_lengths, 'in'))+
  theme(axis.text.y = element_text(size = text_size_axis_tick_labels))+
  theme(axis.text.x = element_text(size = text_size_axis_tick_labels))+
  theme(legend.position = "none") +
  facet_wrap(~Set, nrow = 3)+
  theme(strip.background = element_blank(), strip.text.x = element_blank())
p1
# Growth rate plot -------------------------------------------------------------
p2 <- ggplot(data = dat_g, aes(x = Time, y = Growthrate, color = interaction(Set, Experiment, Mixture),
                               group = interaction(Set, Experiment, Mixture))) +
  geom_line(size = density_line_size, linetype = density_linetype) +
  geom_point(size = point_size) + 
  scale_color_manual(values = density_cell_colors) +
  scale_x_continuous(limits = c(x_axis_min, x_axis_max), breaks = x_axis_breaks)+
  ylab(growth_y_axis_label) + 
  xlab(density_x_axis_label) + 
  theme(axis.title = element_text(size = text_size_axis_title)) +
  theme(axis.line.y = element_line(size = axis_line_size)) +
  theme(axis.line.x = element_line(size = axis_line_size)) +
  theme(axis.ticks = element_line(size = axis_tick_size))+
  theme(axis.ticks.length = unit(axis_tick_lengths, 'in'))+
  theme(axis.text.y = element_text(size = text_size_axis_tick_labels))+
  theme(axis.text.x = element_text(size = text_size_axis_tick_labels))+
  theme(legend.position = "none") +
  facet_wrap(~Set, nrow = 3)+
  theme(strip.background = element_blank(), strip.text.x = element_blank())
p2
# Fix plot size -------------------------------------------------------------
Figp1_fixed <- set_panel_size(p1, width  = unit(1.5, "in"), height = unit(1, "in"))
Figp2_fixed <- set_panel_size(p2, width  = unit(1.5, "in"), height = unit(1, "in"))

# Fig assemble -------------------------------------------------------------
Figure_main <- plot_grid(Figp1_fixed, Figp2_fixed, labels = c('a','b'), label_size = Figure_label_size)
Figure <- grid.arrange(arrangeGrob(Figure_main))
save_plot("SI_fig_growthrates.pdf", plot = Figure, base_width = 4, base_height = 4)

