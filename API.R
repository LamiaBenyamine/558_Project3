#title: "ST 558 Project 3: App"
#author: "Lamia Benyamine"
#date: "July 29, 2024"
###################################

# Libraries
library(plumber)
library(readr)
library(tidyverse)
library(dplyr)
library(caret)

# Read in the Diabetes data.

# Fit the best model on the full data set based on the modeling file. 

diabetes_tb <- read_csv("data/diabetes_binary_health_indicators_BRFSS2015.csv", show_col_types = FALSE) |>
  select(-c(CholCheck, MentHlth, DiffWalk, NoDocbcCost, Education, PhysHlth)) |>
  mutate(across(-c(Diabetes_binary, BMI, GenHlth, Sex, Age, Income), \(x) factor(x, levels = c("0","1"), labels = c("No", "Yes"))),
         Diabetes = factor(Diabetes_binary, levels = c(0:1), labels = c("no diabetes", "diabetes")),
         GenHlth = factor(GenHlth, levels = c(1:5), labels = c("excellent", "very good", "good", "fair", "poor")),
         Sex = factor(Sex, levels = c("0", "1"), labels = c("Female", "Male")),
         Age = factor(Age, levels = c(1:13), labels=c("18-24", "25-34", "25-34", "35-44", "35-44", "45-54", "45-54", "55-64", "55-64", "65-74", "65-74", "75+", "75+")),
         Income = factor(Income, levels = c(1:8), labels = c("less than $10k","less than $35k", "less than $35k", "less than $35k", "less than $35k", "less than $75k", "less than $75k", "more than $75k" ))) |>
  select(-Diabetes_binary)

# add '-' to variables that have spaces in their levels in order to run the regression model
levels(diabetes_tb$Diabetes) <- gsub("[^[:alnum:]]", "_", levels(diabetes_tb$Diabetes))
levels(diabetes_tb$Income) <- gsub("[^[:alnum:]]", "_", levels(diabetes_tb$Income))
levels(diabetes_tb$GenHlth) <- gsub("[^[:alnum:]]", "_", levels(diabetes_tb$GenHlth))

# Split data into a training and test set with 70:30 ratio and set seed to get the same training and test set each time.
set.seed(99)
split <- createDataPartition(y = diabetes_tb$Diabetes, p = 0.7, list = FALSE)
train <- diabetes_tb[split, ]
test <- diabetes_tb[-split, ]

# Fit the best model found from the modeling file
logRegFit1 <- train(Diabetes ~ Sex + Age + GenHlth + HighBP + HighChol + Income + PhysActivity + Fruits + Veggies + Smoker + Stroke + HeartDiseaseorAttack + BMI + HvyAlcoholConsump + AnyHealthcare,
                    data = train,
                    method = "glm",
                    family = "binomial",
                    metric = "logLoss",
                    trControl = trainControl(method = "cv", number = 5,
                                             classProbs = TRUE, summaryFunction = mnLogLoss))

# Refit the model on the full diabetes data set.
logRegFit <- update(logRegFit1, data = rbind(train,test))

# Create two API endpoints.

## prediction endpoint on the best model. 
# default values are set to the mean for numeric variables and the most prevalent class for categorical variables
#* @param sx sex variable
#* @param ag Age  variable
#* @param ghth GenHlth variable
#* @param hbp HighBP variable
#* @param hch HighChol variable
#* @param inc Income variable
#* @param phac PhysActivity variable
#* @param fru Fruits variable
#* @param veg Veggies variable
#* @param smok Smoker variable
#* @param strok Stroke variable
#* @param hdoa HeartDiseaseorAttack variable
#* @param mi BMI variable
#* @param alc HvyAlcoholConsump variable
#* @param hcare AnyHealthcare variable
#* @get /pred
function(sx = "Female", ag = "55-64", ghth = "very_good", hbp = "No", hch = "No", inc = "more_than__75k", 
               phac = "Yes", fru = "Yes", veg = "Yes", smok = "No", strok = "No", 
         hdoa = "No", alc = "No", hcare = "Yes", mi = 28.3824){
  
  newdata = data.frame(Sex = sx, Age = ag, GenHlth = ghth, HighBP = hbp, HighChol = hch, 
                       Income = inc, PhysActivity = phac, Fruits = fru, Veggies = veg, Smoker = smok, 
                       Stroke = strok, HeartDiseaseorAttack = hdoa, HvyAlcoholConsump = alc, AnyHealthcare = hcare, BMI = mi)
  
  # Update the structure of the input values
  colFact <- c(1:14)
  newdata[,colFact] <-lapply(newdata[,colFact] , factor)
  newdata[,15] <- as.numeric(newdata[,15])
  
  # Using the user input, predict if the conditions will predict diabetes.
  predict(logRegFit, newdata)
}

# Example calls
#http://localhost:PORT/pred
#http://localhost:PORT/pred?sx=male&ghth=good&mi=32
#http://localhost:PORT/pred?ghth=fair&hbp=No&smok=Yes&inc=less_than__75k


## info endpoint
#* @get /info
function(){
  "Lamia Benyamine"
  "https://lamiabenyamine.github.io/558_Project3/"
}

#http://localhost:PORT/info
