## ----setup_inference_regression, include=FALSE--------------------------------
chap <- 10
lc <- 0
rq <- 0
# **`r paste0("(LC", chap, ".", (lc <- lc + 1), ")")`**
# **`r paste0("(RQ", chap, ".", (rq <- rq + 1), ")")`**

knitr::opts_chunk$set(
  tidy = FALSE, 
  out.width = '\\textwidth', 
  fig.height = 4,
  warning = FALSE
  )

options(scipen = 99, digits = 3)

# Set random number generator see value for replicable pseudorandomness.
set.seed(76)


## ----message=FALSE, warning=FALSE---------------------------------------------
library(tidyverse)
library(moderndive)
library(infer)


## ----message=FALSE, warning=FALSE, echo=FALSE---------------------------------
# Packages needed internally, but not in text.
library(knitr)
library(tidyr)
library(kableExtra)
library(patchwork)


## -----------------------------------------------------------------------------
evals_ch5 <- evals %>%
  select(ID, score, bty_avg, age)
glimpse(evals_ch5)

## ---- echo=FALSE--------------------------------------------------------------
cor_ch6 <- evals_ch5 %>%
  summarize(correlation = cor(score, bty_avg)) %>%
  pull(correlation) %>%
  round(3)


## ----regline, fig.cap="Relationship with regression line.", fig.height=3.2----
ggplot(evals_ch5, 
       aes(x = bty_avg, y = score)) +
  geom_point() +
  labs(x = "Beauty Score", 
       y = "Teaching Score",
       title = "Relationship between teaching and beauty scores") +  
  geom_smooth(method = "lm", se = FALSE)


## ---- eval=FALSE--------------------------------------------------------------
## # Fit regression model:
## score_model <- lm(score ~ bty_avg, data = evals_ch5)
## # Get regression table:
## get_regression_table(score_model)

## ----regtable-11, echo=FALSE--------------------------------------------------
# Fit regression model:
score_model <- lm(score ~ bty_avg, data = evals_ch5)
get_regression_table(score_model) %>%
  knitr::kable(
    digits = 3,
    caption = "Previously seen linear regression table",
    booktabs = TRUE,
    linesep = ""
  ) %>%
  kable_styling(font_size = ifelse(knitr:::is_latex_output(), 10, 16),
                latex_options = c("hold_position"))

# slope:
slope_row <- get_regression_table(score_model) %>% 
  filter(term == "bty_avg")
b1 <- slope_row %>% pull(estimate)
se1 <- slope_row %>% pull(std_error)
t1 <- slope_row %>% pull(statistic)
lower1 <- slope_row %>% pull(lower_ci)
upper1 <- slope_row %>% pull(upper_ci)
# intercept:
intercept_row <- get_regression_table(score_model) %>% 
  filter(term == "intercept")
b0 <- intercept_row %>% pull(estimate)
se0 <- intercept_row %>% pull(std_error)
t0 <- intercept_row %>% pull(statistic)
lower0 <- intercept_row %>% pull(lower_ci)
upper0 <- intercept_row %>% pull(upper_ci)


## ----summarytable-ch11, echo=FALSE, message=FALSE-----------------------------
# The following Google Doc is published to CSV and loaded using read_csv():
# https://docs.google.com/spreadsheets/d/1QkOpnBGqOXGyJjwqx1T2O5G5D72wWGfWlPyufOgtkk4/edit#gid=0

if(!file.exists("rds/sampling_scenarios.rds")){
  sampling_scenarios <- "https://docs.google.com/spreadsheets/d/e/2PACX-1vRd6bBgNwM3z-AJ7o4gZOiPAdPfbTp_V15HVHRmOH5Fc9w62yaG-fEKtjNUD2wOSa5IJkrDMaEBjRnA/pub?gid=0&single=true&output=csv" %>% 
    read_csv(na = "") %>% 
    slice(1:5)
  write_rds(sampling_scenarios, "rds/sampling_scenarios.rds")
} else {
  sampling_scenarios <- read_rds("rds/sampling_scenarios.rds")
}

sampling_scenarios %>%  
#  filter(Scenario %in% 1:5) %>% 
  kable(
    caption = "Scenarios of sampling for inference", 
    booktabs = TRUE,
    escape = FALSE,
    linesep = ""
  ) %>% 
  kable_styling(font_size = ifelse(knitr:::is_latex_output(), 10, 16),
                latex_options = c("hold_position")) %>%
  column_spec(1, width = "0.5in") %>% 
  column_spec(2, width = "0.7in") %>%
  column_spec(3, width = "1in") %>%
  column_spec(4, width = "1.1in") %>% 
  column_spec(5, width = "1in")


## ----score-model-part-deux, echo=FALSE----------------------------------------
get_regression_table(score_model) %>%
  knitr::kable(
    caption = "Previously seen regression table", 
    digits = 3,
    booktabs = TRUE,
    linesep = ""
  ) %>%
  kable_styling(font_size = ifelse(knitr:::is_latex_output(), 10, 16),
                latex_options = c("hold_position"))


## ----residual-example, echo=FALSE, warning=FALSE, fig.cap="Example of observed value, fitted value, and residual."----
# Pick out one particular point to drill down on
index <- which(evals_ch5$bty_avg == 7.333 & evals_ch5$score == 4.9)
target_point <- score_model %>%
  get_regression_points() %>%
  slice(index)
x <- target_point$bty_avg
y <- target_point$score
y_hat <- target_point$score_hat
resid <- target_point$residual

# Plot residual
best_fit_plot <- ggplot(evals_ch5, aes(x = bty_avg, y = score)) +
  geom_point() +
  labs(x = "Beauty Score", y = "Teaching Score",
       title = "Relationship of teaching and beauty scores") +
  geom_smooth(method = "lm", se = FALSE) +
  annotate("point", x = x, y = y, col = "red", size = 4) +
  annotate("point", x = x, y = y_hat, col = "red", shape = 15, size = 4) +
  annotate("segment", x = x, xend = x, y = y, yend = y_hat, color = "blue",
           arrow = arrow(type = "closed", length = unit(0.02, "npc")))
best_fit_plot


## ---- eval=TRUE, echo=TRUE----------------------------------------------------
# Fit regression model:
score_model <- lm(score ~ bty_avg, data = evals_ch5)
# Get regression points:
regression_points <- get_regression_points(score_model)
regression_points


## ----non-linear, fig.cap="Example of a clearly non-linear relationship.", echo=FALSE, fig.height=3.3----
set.seed(76)
evals_ch5 %>% 
  mutate(
    x = bty_avg,
    y = (x-3)*(x-6) + rnorm(n(), 0, 0.75)
    ) %>% 
  ggplot(aes(x = x, y = y)) +
  geom_point() +
  labs(x = "Beauty Score", y = "Teaching Score") +  
  geom_smooth(method = "lm", se = FALSE) +
  expand_limits(y = 10)


## -----------------------------------------------------------------------------
evals %>% 
  select(ID, prof_ID, score, bty_avg)


## ---- eval=FALSE, echo=TRUE---------------------------------------------------
## ggplot(regression_points, aes(x = residual)) +
##   geom_histogram(binwidth = 0.25, color = "white") +
##   labs(x = "Residual")

## ----model1residualshist, echo=FALSE, warning=FALSE, fig.cap="Histogram of residuals."----
ggplot(regression_points, aes(x = residual)) +
  geom_histogram(binwidth = 0.25, color = "white") +
  labs(x = "Residual")


## ----normal-residuals, echo=FALSE, warning=FALSE, fig.cap="Example of clearly normal and clearly not normal residuals."----
sigma <- sd(regression_points$residual)
normal_and_not_examples <- evals_ch5 %>% 
  mutate(
    `Clearly normal` = rnorm(n = n(), 0, sd = sigma),
    `Clearly not normal` = rnorm(n = n(), mean = 0, sd = sigma)^2,
    `Clearly not normal` = `Clearly not normal` - mean(`Clearly not normal`)
  ) %>%
  select(bty_avg, `Clearly normal`, `Clearly not normal`) %>%
  gather(type, eps, -bty_avg) %>% 
  ggplot(aes(x = eps)) +
  geom_histogram(binwidth = 0.25, color = "white") +
  labs(x = "Residual") +
  facet_wrap(~ type, scales = "free")

if(knitr::is_latex_output()){
  normal_and_not_examples +
    theme(strip.text = element_text(colour = 'black'),
          strip.background = element_rect(fill = "grey93"))
} else {
  normal_and_not_examples
}
  


## ---- eval=FALSE, echo=TRUE---------------------------------------------------
## ggplot(regression_points, aes(x = bty_avg, y = residual)) +
##   geom_point() +
##   labs(x = "Beauty Score", y = "Residual") +
##   geom_hline(yintercept = 0, col = "blue", size = 1)

## ----numxplot6, echo=FALSE, warning=FALSE, fig.cap="Plot of residuals over beauty score."----
ggplot(regression_points, aes(x = bty_avg, y = residual)) +
  geom_point() +
  labs(x = "Beauty Score", y = "Residual") +
  geom_hline(yintercept = 0, col = "blue", size = 1)


## ----equal-variance-residuals, echo=FALSE, warning=FALSE, fig.cap="Example of clearly non-equal variance."----
evals_ch5 %>% 
  mutate(eps = (rnorm(n(), 0, 0.075 * bty_avg ^ 2)) * 0.4) %>% 
  ggplot(aes(x = bty_avg, y = eps)) +
  geom_point() +
  labs(x = "Beauty Score", y = "Residual") +
  geom_hline(yintercept = 0, col = "blue", size = 1)






## ----eval=FALSE---------------------------------------------------------------
## bootstrap_distn_slope <- evals_ch5 %>%
##   specify(formula = score ~ bty_avg) %>%
##   generate(reps = 1000, type = "bootstrap") %>%
##   calculate(stat = "slope")
## bootstrap_distn_slope

## ----echo=FALSE---------------------------------------------------------------
if(!file.exists("rds/bootstrap_distn_slope.rds")){
  set.seed(76)
  bootstrap_distn_slope <- evals %>% 
    specify(score ~ bty_avg) %>%
    generate(reps = 1000, type = "bootstrap") %>% 
    calculate(stat = "slope")
  saveRDS(object = bootstrap_distn_slope, 
           "rds/bootstrap_distn_slope.rds")
} else {
  bootstrap_distn_slope <- readRDS("rds/bootstrap_distn_slope.rds")
}
bootstrap_distn_slope


## ----eval=FALSE---------------------------------------------------------------
## visualize(bootstrap_distn_slope)




## -----------------------------------------------------------------------------
percentile_ci <- bootstrap_distn_slope %>% 
  get_confidence_interval(type = "percentile", level = 0.95)
percentile_ci


## -----------------------------------------------------------------------------
observed_slope <- evals %>% 
  specify(score ~ bty_avg) %>% 
  calculate(stat = "slope")
observed_slope


## -----------------------------------------------------------------------------
se_ci <- bootstrap_distn_slope %>% 
  get_ci(level = 0.95, type = "se", point_estimate = observed_slope)
se_ci


## ---- eval=FALSE--------------------------------------------------------------
## visualize(bootstrap_distn_slope) +
##   shade_confidence_interval(endpoints = percentile_ci, fill = NULL,
##                             linetype = "solid", color = "grey90") +
##   shade_confidence_interval(endpoints = se_ci, fill = NULL,
##                             linetype = "dashed", color = "grey60") +
##   shade_confidence_interval(endpoints = c(0.035, 0.099), fill = NULL,
##                             linetype = "dotted", color = "black")




## ----eval=FALSE---------------------------------------------------------------
## null_distn_slope <- evals %>%
##   specify(score ~ bty_avg) %>%
##   hypothesize(null = "independence") %>%
##   generate(reps = 1000, type = "permute") %>%
##   calculate(stat = "slope")

## ----echo=FALSE---------------------------------------------------------------
if(!file.exists("rds/null_distn_slope.rds")){
  set.seed(76)
  null_distn_slope <- evals %>% 
    specify(score ~ bty_avg) %>%
    hypothesize(null = "independence") %>% 
    generate(reps = 1000, type = "permute") %>% 
    calculate(stat = "slope")
   saveRDS(object = null_distn_slope, 
           "rds/null_distn_slope.rds")
} else {
   null_distn_slope <- readRDS("rds/null_distn_slope.rds")
}


## ----null-distribution-slope, echo=FALSE, fig.show='hold', fig.cap="Null distribution of slopes.", fig.height=2.5----
visualize(null_distn_slope)


## ----p-value-slope, echo=FALSE, fig.show='hold', fig.cap="Null distribution and $p$-value.", fig.height=3----
visualize(null_distn_slope) + 
  shade_p_value(obs_stat = observed_slope, direction = "both")


## -----------------------------------------------------------------------------
null_distn_slope %>% 
  get_p_value(obs_stat = observed_slope, direction = "both")






## ----table-ch11, echo=FALSE, message=FALSE------------------------------------
# The following Google Doc is published to CSV and loaded using read_csv():
# https://docs.google.com/spreadsheets/d/1QkOpnBGqOXGyJjwqx1T2O5G5D72wWGfWlPyufOgtkk4/edit#gid=0

if(!file.exists("rds/sampling_scenarios.rds")){
  sampling_scenarios <- "https://docs.google.com/spreadsheets/d/e/2PACX-1vRd6bBgNwM3z-AJ7o4gZOiPAdPfbTp_V15HVHRmOH5Fc9w62yaG-fEKtjNUD2wOSa5IJkrDMaEBjRnA/pub?gid=0&single=true&output=csv" %>% 
    read_csv(na = "") %>% 
    slice(1:5)
  write_rds(sampling_scenarios, "rds/sampling_scenarios.rds")
} else {
  sampling_scenarios <- read_rds("rds/sampling_scenarios.rds")
}

sampling_scenarios %>%  
  filter(Scenario %in% 1:6) %>% 
  kable(
    caption = "\\label{tab:summarytable-ch9}Scenarios of sampling for inference", 
    booktabs = TRUE,
    escape = FALSE,
    linesep = ""
  ) %>% 
  kable_styling(font_size = ifelse(knitr:::is_latex_output(), 10, 16),
                latex_options = c("hold_position")) %>%
  column_spec(1, width = "0.5in") %>% 
  column_spec(2, width = "1.5in") %>%
  column_spec(3, width = "0.65in") %>%
  column_spec(4, width = "1.6in") %>% 
  column_spec(5, width = "0.65in")


## ----echo=FALSE, results="asis"-----------------------------------------------
if(knitr::is_latex_output()){
  cat("Solutions to all *Learning checks* can be found online in [Appendix D](https://moderndive.com/D-appendixD.html).")
} 

