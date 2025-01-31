# Load packages -----------------------------------------------------------
library(tidyverse)
library(readxl)
library(patchwork)
library(scales)
library(cowplot)
library(ggpubr)
library(rstatix)  
library(ggpubr)
library(ggpmisc)
library(egg)
library(grid)
theme_set(theme_cowplot())
# Plot filtering ----------------------------------------------------------
Incubation_time = 24 # The max incubation time for the x-axis
num_of_rows_to_skip = 100 # This skips datapoints so that the ggplot linetypes will work

# General plotting customization -------------------------------------------------
Figure_height = 3.75
Figure_width = 6.5
Figure_label_size = 10
plot_width = 1.7
text_size_axis_title = 8
text_size_axis_tick_labels = 8
axis_line_size = 0.75/(ggplot2::.pt*72.27/96) # pt size for the axis lines
axis_tick_size = 0.75/(ggplot2::.pt*72.27/96)
axis_tick_lengths = 0.03
x_axis_min = 0
x_axis_max = 24
x_axis_breaks = c(0,6,12,18,24)
x_axis_label = "Time (hr)"
margins_top_left <- c(0,0,0,0.0)
margins_bottom_left <- c(0.1,0,0,0.0)
margins_top_right <- c(0,0,0,0.0)
margins_bottom_right <- c(0.1,0,0,0.0)

# Density plotting customization -------------------------------------------------
density_cell_colors <- c('firebrick1', 'blue2', 'darkorchid2') # the line colors for donor, recipient, and transconjugant trajectories
density_linetype = 'solid' # the linetype used to plot the density trajectories
density_line_size = 1.5/(ggplot2::.pt*72.27/96) # pt size for the density trajectories
density_line_dodge = 0.5 # to jitter the overlapping density trajectories
density_y_axis_min = 1
density_y_axis_max = 1e10
density_y_axis_number_of_ticks = 4
density_height = plot_width*0.75
density_y_axis_label = expression(atop("Cell density", paste("(cfu ", 'ml'^-1, ")")))
point_size = 1.5
# SIM plotting customization -------------------------------------------------
SIM_set_conjugation_rate_color = c(rgb(169, 169, 169, maxColorValue = 255)) #darkgrey
SIM_set_conjugation_rate_linetype = 'dotted'
SIM_set_conjugation_rate_line_size = 0.75/(ggplot2::.pt*72.27/96)
SIM_line_size = 1.5/(ggplot2::.pt*72.27/96)
SIM_line_color = c(rgb(205, 102, 0, maxColorValue = 255)) #darkorange3
SIM_y_axis_number_of_ticks = 4
SIM_y_axis_min = 1e-14
SIM_y_axis_max = 1e-6
SIM_height = plot_width*0.75
SIM_y_axis_label = expression(atop("SIM estimate", paste("(ml ", 'cfu'^-1, ' hr'^-1, ")")))

# Load Experimental data ---------------------------------------------------------------
exp <- read.csv("Experimental_data/Average_experimental_densities.csv")
exp$Cell.type <- recode_factor(exp$Cell.type, "Dc" = "Donor", "Rc" = "Recipient", "Tc" = "Transconjugant")

expSIM <- read.csv("Experimental_data/Experimental_conjugation_rate.csv")
expSIM <- expSIM %>%
  filter(Set != 'D', Time != 4, Method != 'LDM')  %>%
  mutate(SIM = Conjugation.rate)


# a. ------------------------------------------------------------
dat <- read.csv("Monod_sim_data/M1.csv")
T_1 = (dat$Time[dat$Transconjugant>1]/3600)[1]
num_of_rows_to_skip = 100 # This skips datapoints so that the ggplot linetypes will work
dat2 <- dat %>%
  filter(row_number() %% num_of_rows_to_skip == 1)
dat1 <- dat2 %>%
  select(-X, -PlasmidFreeDonor) %>%
  gather(Cell.type, Density, 2:4) 

top_left <- ggplot(data = dat1 %>% filter(time < Incubation_time), aes(x = time, y = Density, color = Cell.type)) +
  geom_vline(xintercept = 5, color = SIM_set_conjugation_rate_color, linetype = SIM_set_conjugation_rate_linetype, size = SIM_set_conjugation_rate_line_size) +
  geom_vline(xintercept = 24, color = SIM_set_conjugation_rate_color, linetype = SIM_set_conjugation_rate_linetype, size = SIM_set_conjugation_rate_line_size) +
  geom_line(size = density_line_size, linetype = density_linetype) +
  geom_point(data = exp %>% filter(Time != 4), aes(x = Time, y = Density, color = Cell.type), size = point_size)+
  geom_errorbar(data = exp %>% filter(Time != 4), aes(x = Time, ymin = Density - SE, ymax = Density + SE), width=.1) +
  scale_color_manual(values = density_cell_colors) +
  scale_x_continuous(limits = c(x_axis_min, x_axis_max), breaks = x_axis_breaks)+
  scale_y_log10(limits = c(density_y_axis_min, density_y_axis_max), breaks = scales::trans_breaks("log10", function(x) 10^x, n = density_y_axis_number_of_ticks), labels = scales::trans_format("log10", scales::math_format(10^.x))) +
  ylab(density_y_axis_label) + 
  theme(axis.title.x = element_blank()) +
  theme(axis.title = element_text(size = text_size_axis_title)) +
  theme(axis.line.y = element_line(size = axis_line_size)) +
  theme(axis.line.x = element_line(size = axis_line_size)) +
  theme(axis.ticks = element_line(size = axis_tick_size))+
  theme(axis.ticks.length = unit(axis_tick_lengths, 'in'))+
  theme(axis.text.y = element_text(size = text_size_axis_tick_labels))+
  theme(axis.text.x = element_blank()) +
  theme(legend.position = "none") +
  theme(plot.margin = unit(margins_top_left, "in"))

bottom_left <- ggplot(data = dat1, aes(x = time, y = SIM)) +
  geom_vline(xintercept = 5, color = SIM_set_conjugation_rate_color, linetype = SIM_set_conjugation_rate_linetype, size = SIM_set_conjugation_rate_line_size) +
  geom_vline(xintercept = 24, color = SIM_set_conjugation_rate_color, linetype = SIM_set_conjugation_rate_linetype, size = SIM_set_conjugation_rate_line_size) +
  geom_line(size = SIM_line_size, color = SIM_line_color) +
  geom_point(data = expSIM, aes(x = Time, y = Conjugation.rate), size = point_size, color = SIM_line_color) +
  geom_errorbar(data = expSIM , aes(x = Time, ymin = Conjugation.rate - SE, ymax = Conjugation.rate + SE), width=.1, color = SIM_line_color) +
  scale_x_continuous(limits = c(x_axis_min, x_axis_max), breaks = x_axis_breaks)+
  scale_y_log10(limits=c(SIM_y_axis_min, SIM_y_axis_max), breaks = scales::trans_breaks("log10", function(x) 10^x, n = SIM_y_axis_number_of_ticks), labels = scales::trans_format("log10", scales::math_format(10^.x))) +
  ylab(SIM_y_axis_label) + 
  theme(axis.title.x = element_blank()) +
  theme(axis.title = element_text(size = text_size_axis_title)) +
  theme(axis.line.y = element_line(size = axis_line_size)) +
  theme(axis.line.x = element_line(size = axis_line_size)) +
  theme(axis.ticks = element_line(size = axis_tick_size))+
  theme(axis.ticks.length = unit(axis_tick_lengths, 'in'))+
  theme(axis.text = element_text(size = text_size_axis_tick_labels))+
  theme(legend.position = "none") +
  theme(plot.margin = unit(margins_bottom_left, "in"))

# b. ---------------------------------------------------------------
dat <- read.csv("Monod_sim_data/M2.csv")
T_1 = (dat$Time[dat$Transconjugant>1]/3600)[1]
num_of_rows_to_skip = 100 # This skips datapoints so that the ggplot linetypes will work
dat2 <- dat %>%
  filter(row_number() %% num_of_rows_to_skip == 1)
dat1 <- dat2 %>%
  select(-X, -PlasmidFreeDonor) %>%
  gather(Cell.type, Density, 2:4) 

top_middle <- ggplot(data = dat1 %>% filter(time < Incubation_time), aes(x = time, y = Density, color = Cell.type)) +
  geom_vline(xintercept = 5, color = SIM_set_conjugation_rate_color, linetype = SIM_set_conjugation_rate_linetype, size = SIM_set_conjugation_rate_line_size) +
  geom_vline(xintercept = 24, color = SIM_set_conjugation_rate_color, linetype = SIM_set_conjugation_rate_linetype, size = SIM_set_conjugation_rate_line_size) +
  geom_line(size = density_line_size, linetype = density_linetype) +
  geom_point(data = exp %>% filter(Time != 4), aes(x = Time, y = Density, color = Cell.type), size = point_size)+
  geom_errorbar(data = exp %>% filter(Time != 4), aes(x = Time, ymin = Density - SE, ymax = Density + SE), width=.1) +
  scale_color_manual(values = density_cell_colors) +
  scale_x_continuous(limits = c(x_axis_min, x_axis_max), breaks = x_axis_breaks)+
  scale_y_log10(limits = c(density_y_axis_min, density_y_axis_max), breaks = scales::trans_breaks("log10", function(x) 10^x, n = density_y_axis_number_of_ticks), labels = scales::trans_format("log10", scales::math_format(10^.x))) +
  theme(axis.title.y = element_blank()) +
  theme(axis.title.x = element_blank()) +
  theme(axis.line.y = element_line(size = axis_line_size)) +
  theme(axis.line.x = element_line(size = axis_line_size)) +
  theme(axis.ticks = element_line(size = axis_tick_size))+
  theme(axis.ticks.length = unit(axis_tick_lengths, 'in'))+
  theme(axis.text = element_blank())+
  theme(legend.position = "none") +
  theme(plot.margin = unit(margins_top_right, "in"))

bottom_middle <- ggplot(data = dat1, aes(x = time, y = SIM)) +
  geom_vline(xintercept = 5, color = SIM_set_conjugation_rate_color, linetype = SIM_set_conjugation_rate_linetype, size = SIM_set_conjugation_rate_line_size) +
  geom_vline(xintercept = 24, color = SIM_set_conjugation_rate_color, linetype = SIM_set_conjugation_rate_linetype, size = SIM_set_conjugation_rate_line_size) +
  geom_line(size = SIM_line_size, color = SIM_line_color) +
  geom_point(data = expSIM, aes(x = Time, y = Conjugation.rate), size = point_size, color = SIM_line_color) +
  geom_errorbar(data = expSIM , aes(x = Time, ymin = Conjugation.rate - SE, ymax = Conjugation.rate + SE), width=.1, color = SIM_line_color) +
  scale_x_continuous(limits = c(x_axis_min, x_axis_max), breaks = x_axis_breaks)+
  scale_y_log10(limits=c(SIM_y_axis_min, SIM_y_axis_max), breaks = scales::trans_breaks("log10", function(x) 10^x, n = SIM_y_axis_number_of_ticks), labels = scales::trans_format("log10", scales::math_format(10^.x))) +
  theme(axis.title.y = element_blank()) +
  theme(axis.title.x = element_blank()) +
  theme(axis.title = element_text(size = text_size_axis_title)) +
  theme(axis.line.y = element_line(size = axis_line_size)) +
  theme(axis.line.x = element_line(size = axis_line_size)) +
  theme(axis.ticks = element_line(size = axis_tick_size))+
  theme(axis.ticks.length = unit(axis_tick_lengths, 'in'))+
  theme(axis.text.y = element_blank())+
  theme(axis.text.x = element_text(size = text_size_axis_tick_labels))+
  theme(legend.position = "none") +
  theme(plot.margin = unit(margins_bottom_right, "in"))

# c. ---------------------------------------------------------------
dat <- read.csv("Monod_sim_data/M3.csv")
T_1 = (dat$Time[dat$Transconjugant>1]/3600)[1]
num_of_rows_to_skip = 100 # This skips datapoints so that the ggplot linetypes will work
dat2 <- dat %>%
  filter(row_number() %% num_of_rows_to_skip == 1)
dat1 <- dat2 %>%
  select(-X, -PlasmidFreeDonor) %>%
  gather(Cell.type, Density, 2:4) 

top_right <- ggplot(data = dat1 %>% filter(time < Incubation_time), aes(x = time, y = Density, color = Cell.type)) +
  geom_vline(xintercept = 5, color = SIM_set_conjugation_rate_color, linetype = SIM_set_conjugation_rate_linetype, size = SIM_set_conjugation_rate_line_size) +
  geom_vline(xintercept = 24, color = SIM_set_conjugation_rate_color, linetype = SIM_set_conjugation_rate_linetype, size = SIM_set_conjugation_rate_line_size) +
  geom_line(size = density_line_size, linetype = density_linetype) +
  geom_point(data = exp %>% filter(Time != 4), aes(x = Time, y = Density, color = Cell.type), size = point_size)+
  geom_errorbar(data = exp %>% filter(Time != 4), aes(x = Time, ymin = Density - SE, ymax = Density + SE), width=.1) +
  scale_color_manual(values = density_cell_colors) +
  scale_x_continuous(limits = c(x_axis_min, x_axis_max), breaks = x_axis_breaks)+
  scale_y_log10(limits = c(density_y_axis_min, density_y_axis_max), breaks = scales::trans_breaks("log10", function(x) 10^x, n = density_y_axis_number_of_ticks), labels = scales::trans_format("log10", scales::math_format(10^.x))) +
  theme(axis.title.y = element_blank()) +
  theme(axis.title.x = element_blank()) +
  theme(axis.line.y = element_line(size = axis_line_size)) +
  theme(axis.line.x = element_line(size = axis_line_size)) +
  theme(axis.ticks = element_line(size = axis_tick_size))+
  theme(axis.ticks.length = unit(axis_tick_lengths, 'in'))+
  theme(axis.text = element_blank())+
  theme(legend.position = "none") +
  theme(plot.margin = unit(margins_top_right, "in"))

bottom_right <- ggplot(data = dat1 %>% filter(time < 4), aes(x = time, y = SIM)) +
  geom_vline(xintercept = 5, color = SIM_set_conjugation_rate_color, linetype = SIM_set_conjugation_rate_linetype, size = SIM_set_conjugation_rate_line_size) +
  geom_vline(xintercept = 24, color = SIM_set_conjugation_rate_color, linetype = SIM_set_conjugation_rate_linetype, size = SIM_set_conjugation_rate_line_size) +
  geom_line(size = SIM_line_size, color = SIM_line_color) +
  geom_point(data = expSIM, aes(x = Time, y = Conjugation.rate), size = point_size, color = SIM_line_color) +
  geom_errorbar(data = expSIM , aes(x = Time, ymin = Conjugation.rate - SE, ymax = Conjugation.rate + SE), width=.1, color = SIM_line_color) +
  scale_x_continuous(limits = c(x_axis_min, x_axis_max), breaks = x_axis_breaks)+
  scale_y_log10(limits=c(SIM_y_axis_min, SIM_y_axis_max), breaks = scales::trans_breaks("log10", function(x) 10^x, n = SIM_y_axis_number_of_ticks), labels = scales::trans_format("log10", scales::math_format(10^.x))) +
  theme(axis.title.y = element_blank()) +
  theme(axis.title.x = element_blank()) +
  theme(axis.title = element_text(size = text_size_axis_title)) +
  theme(axis.line.y = element_line(size = axis_line_size)) +
  theme(axis.line.x = element_line(size = axis_line_size)) +
  theme(axis.ticks = element_line(size = axis_tick_size))+
  theme(axis.ticks.length = unit(axis_tick_lengths, 'in'))+
  theme(axis.text.y = element_blank())+
  theme(axis.text.x = element_text(size = text_size_axis_tick_labels))+
  theme(legend.position = "none") +
  theme(plot.margin = unit(margins_bottom_right, "in"))

# Fig assemble with patchwork ------------------------------------------------------------
Figleft <- (top_left / bottom_left) + 
  plot_layout(widths = unit(c(plot_width), units = c('in')), heights = unit(c(density_height, SIM_height), c('in', 'in')))

Figmiddle <- (top_middle / bottom_middle) + 
  plot_layout(widths = unit(c(plot_width), units = c('in')), heights = unit(c(density_height, SIM_height), c('in', 'in')))

Figright <- (top_right / bottom_right) + 
  plot_layout(widths = unit(c(plot_width), units = c('in')), heights = unit(c(density_height, SIM_height), c('in', 'in')))

Fig <- (Figleft | Figmiddle| Figright)  +
  plot_annotation(tag_levels = list(c('a', '', 'b', '', 'c', ''))) & 
  theme(plot.tag.position = c(0, 1.1), plot.tag = element_text(size = Figure_label_size))

x.grob <- textGrob(x_axis_label, gp=gpar(fontsize=text_size_axis_title))
Figure <- grid.arrange(as_grob(Fig), x.grob, nrow = 2, heights = unit(c(density_height+SIM_height+0.4, 0.1), c("in", "in")))
save_plot("SI_Fig6.pdf", plot = Figure, base_width = Figure_width, base_height = Figure_height)
