#To clean the working space and directory
rm(list=ls())

#Importing the necessary packages
library(leaps)
library(DAAG)
library(car)
library(MASS)
library(Metrics)
library(caret)

#Changing the working directory to import files
setwd("C:/Users/vaibh/Desktop/Master of Data Science/Semester - 4/Regression Analysis/Project")

#Before we start building our regression model, we built a function for model adequacy & diagonstic check which shall be used multiple times
#This till save time, and code shall remain more structured
model_check <- function(model) {
  # Residual Plot of the Model
  plot(model)
  # Non-Constant Variance Test
  print(ncvTest(model))
  # Autocorrelation Test
  print(durbinWatsonTest(model))
  # Normality Test
  print(shapiro.test(model$residuals))
  # Multicollinearity Test
  print(vif(model))
  
  # Component Residual Plot
  print(crPlots(model))
  # Outliers Test
  print(outlierTest(model))
  # To check if we have any influential point
  print(summary(influence.measures(model)))
}
#Importing the dataset
med_ins <- read.csv("medical_insurance.csv")

#Exploratory Data Analysis (EDA)
#Sample of the dataset
head(med_ins)
#To understand the structure of the dataset
str(med_ins)

#Checking if there are any missing values
sum(is.na(med_ins))
colSums(is.na(med_ins))

#Summary of the dataset
summary(med_ins)

#To check the correlation between the numerical & target variables
med_corr <- cor(med_ins[, c("age", "bmi", "children", "charges")])
med_corr

#Before modelling, converting the categorial variables into factors
med_ins$sex <- as.factor(med_ins$sex)
med_ins$smoker <- as.factor(med_ins$smoker)
med_ins$region <- factor(med_ins$region, levels = c("southwest", "southeast", "northwest", "northeast"))

#Boxplot and Anova Test for Sex & Charges Column
boxplot(charges ~ sex, data=med_ins)
anova_sex <- aov(charges ~ sex, data = med_ins)
summary(anova_sex)

#Boxplot and Anova Test for Smoker & Charges Column
boxplot(charges ~ smoker, data=med_ins)
anova_smoker <- aov(charges ~ smoker, data = med_ins)
summary(anova_smoker)

#Boxplot and Anova Test for Region & Charges Column
boxplot(charges ~ region, data=med_ins)
anova_region <- aov(charges ~ region, data = med_ins)
summary(anova_region)

#To check whether the categorial values have been converted into factors or not
str(med_ins)

#Multiple Regression Estimation
#Linear Regression Model
model_medins <- lm(charges ~ age + sex + bmi + children + smoker + region, data = med_ins)

#Summary of the Model
summary(model_medins)
#Split the Training and Test Dataset
set.seed(3959656)
trainmed1 <- createDataPartition(med_ins$charges, p = .7, list = FALSE)
train_med1 <- med_ins[trainmed1, ]
test_med1 <- med_ins[-trainmed1, ]
#Predict the Charges Value
model_med <- lm(charges ~ age + sex + bmi + children + smoker + region, data = train_med1)
model_pred <- predict(model_med, newdata = test_med1)
model_pred

#Check the accuracy of the model through RMSE
model_acc <- sqrt(mean((test_med1$charges - model_pred)^2))
print(paste("RMSE:", model_acc))

#To check the significance of each regressor
anova_mod <- anova(model_medins)

# Print ANOVA table
print(anova_mod)

#Model Adequacy & Diagonastics Check
model_check(model_medins)

#Implementation of suitable corrective methods
#Consider Transformation to Deal with heteroscedasticity
b <-boxcox(lm(charges ~ age + sex + bmi + children + smoker + region, data = med_ins)) 
b
best_lambda <- b$x[which.max(b$y)]
best_lambda

#Linear Regression Model
model_medins_2 <- lm(log(charges) ~ age + sex + bmi + children + smoker + region, data = med_ins)
#Summary of the Model
summary(model_medins_2)
#Model Adequacy & Diagonastics
model_check(model_medins_2)

#Trimming down the dataset for the column charges to mitigate the outliers
q_low <- quantile(med_ins$charges, 0.05)
q_high <- quantile(med_ins$charges, 0.95)

# Filter the data to remove outliers
med_ins <- med_ins[med_ins$charges >= q_low & med_ins$charges <= q_high, ]

#Linear Regression Model
model_medins_sq <- lm(sqrt(charges) ~ age + sex + bmi + children + smoker + region, data = med_ins)

#Summary of the Model
summary(model_medins_sq)

#Model Adequacy & Diagonastics
model_check(model_medins_sq)

#Variable Selection
reg_med <- leaps::regsubsets(sqrt(charges) ~ age + sex + bmi + children + smoker + region, data = med_ins)
summary(reg_med)$which
#Variable selection using the two parameters
plot(reg_med, scale="Cp")
plot(reg_med, scale="adjr2")

 
#Based on the above two graphs, sub setting the necessary data as the variables and fitting the model at the same time
data <- subset(med_ins, region != "southeast")
reg_med_model1 <- lm(sqrt(charges) ~ age + bmi + children + smoker + region, data = data)

reg_med_model2 <- lm(sqrt(charges) ~ age + sex + bmi + children + smoker + region, data = data)

reg_med_model3 <- lm(sqrt(charges) ~ age + sex + bmi + children + smoker + region, data = med_ins)

data2 <- subset(med_ins, region = "northeast")
reg_med_model4 <- lm(sqrt(charges) ~ age + bmi + children + smoker + region, data = data2)

#To check the best fit model amongst the list
DAAG::press(reg_med_model1)
DAAG::press(reg_med_model2)
DAAG::press(reg_med_model3)
DAAG::press(reg_med_model4)

#Model Adequacy & Diagonastics
model_check(reg_med_model1)

#Model Validation
set.seed(3959656)
trainmed <- createDataPartition(data$charges, p = .7, list = FALSE)
train_med <- data[trainmed, ]
test_med <- data[-trainmed, ]

#Fitting the final model
final_model <- lm(sqrt(charges) ~ age + bmi + children + smoker + region, data = train_med)

#Insurance Charge Prediction
final_pred <- predict(final_model, newdata = test_med)
final_pred

#Checking the accuracy of the model
final_acc <- sqrt(mean((test_med$charges - final_pred)^2))
print(paste("RMSE:", final_acc))

# Perform 10-fold cross-validation for Model Validation
cv_res <- train(sqrt(charges) ~ age + bmi + children + smoker + region, data = data,
                method = "lm",
                trControl = trainControl(method = "cv", number = 10))
#Checking the accuracy of the model
print(paste("CV RMSE:", cv_res$results$RMSE))

# Get adjusted R-squared of the model
final_adjr <- summary(final_model)$adj.r.squared
print(paste("Adjusted R-squared:", final_adjr))