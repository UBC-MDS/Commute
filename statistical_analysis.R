suppressPackageStartupMessages(library(tidyverse))
suppressPackageStartupMessages(library(ggplot2))
suppressPackageStartupMessages(library(grid))
suppressPackageStartupMessages(library(gridExtra))
suppressPackageStartupMessages(library(randomForest))

# Create suitable column headers
headers <- c('rating', 'commute_time', 'sleep', 'work_exp', 
             'family', 'vanc_stay', 'mds_hrs', 'network')

# Load the rest of the data
data <- read_csv('data/commute.csv')

# Add the header names to the data
colnames(data) <- headers

# Convert both network and family to factors because they are 
# categorical variables.
data <- data %>% 
  mutate(network = as.factor(network),
         family = as.factor(family))

# Treat rating as a continuous variable.
data <- data %>% 
  mutate(rating = as.numeric(rating))

# Using intuition, we decided that sleep is a confounding variables.
# So we created a model using both commute time and sleep.
lm_int <- lm(rating~commute_time + sleep, data = data)
summary(lm_int)$coef

# We used a random forest to find out which predictors could be confounding variables.

rating_rf = randomForest(formula = rating ~., data = data)
rating_rf$importance

# We picked the top five variables in importance in the random forest
# and then used them in a regression.
lm_rf <- lm(rating~commute_time + sleep + work_exp + mds_hrs + network, 
          data = data)
summary(lm_rf)$coef

# Besides using a random forest, we used ANOVA to determine which 
# potentially confounding variables are significant.  
# First, we start with just commute time, and then we add one variable
# at a time, checking for significance using ANOVA.
summary(lm(rating~commute_time, data = data))$coef
lm1 <- lm(rating~commute_time, data = data)
lm2 <- lm(rating~commute_time + sleep, data = data)
anova(lm1, lm2)
summary(lm(rating~commute_time+sleep, data = data))$coef
lm3 <- lm(rating~commute_time + sleep + work_exp, data = data)
anova(lm2, lm3)
lm4 <- lm(rating~commute_time + sleep + work_exp + mds_hrs, data = data)
anova(lm3, lm4)
lm5 <- lm(rating~commute_time + sleep + work_exp + mds_hrs + network, data = data)
anova(lm5, lm6)

# Final model with significant confounding variables network and sleep 
lm_final <- lm(rating~commute_time + sleep + network, data = data)
summary(lm_final)$coef


# Plot rating, commute time, and networking events to check for confounding
# effects.
data %>% ggplot() +
  geom_point(aes(x = commute_time, y = rating, color = network))+
  labs(title = "Checking Confounding Effects for Networking",
       x = "Commute time (minutes)",
       y = "Rating for MDS")
