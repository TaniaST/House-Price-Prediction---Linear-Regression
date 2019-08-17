dataprice<-read.csv("housing.csv", header=TRUE)
library(GGally)
library(car)
library(ggplot2)
library(gridExtra)


#1.Exploratory analysis
#1.1 Exploring the dataset

str(dataprice)
#Our dataset is composed by 500 observations with 9 variables: 8 quantitative and 1 categorical

rownames(dataprice)<-seq(1,500)

summary(dataprice)
#Explanatory variables:
#elevation: Elevation of the base of the house
#dist_am1: Distance to Amenity 1
#dist_am2: Distance to Amenity 2
#dist_am3: Distance to Amenity 3
#bath: Number of bathrooms
#sqft: Square footage of the house
#parking: Parking type
#precip: Amount of precipitation
#Response variable:
#price: Final House Sale Price

#From the summary of our data set, we can see that there is an odd observation negative figure for precipitation.
#As the precipitation should be >=0, we need to exclude this line from our data

dataprice<-dataprice[dataprice$precip>=0,]

#we can also see that for bath, sqft and price variables the maximum values are much higher than the 3rd quantile figures,
#let us see these extreme values on the corresponding boxplots:
#boxplot - Number of bathrooms
boxpl1<-ggplot(data=dataprice,aes(y=bath))+geom_boxplot(outlier.colour = "red")+
  theme(axis.title.x=element_blank(),
        axis.text.x=element_blank(),
        axis.ticks.x=element_blank())+
  labs(y="Number of bathrooms")
#boxplot - Square footage of the house
boxpl2<-ggplot(data=dataprice,aes(y=sqft))+geom_boxplot(outlier.colour = "red")+
  theme(axis.title.x=element_blank(),
        axis.text.x=element_blank(),
        axis.ticks.x=element_blank())+
  labs(y="Square footage of the house")
#boxplot - Price
boxpl3<-ggplot(data=dataprice,aes(y=price))+geom_boxplot(outlier.colour = "red")+
  theme(axis.title.x=element_blank(),
        axis.text.x=element_blank(),
        axis.ticks.x=element_blank())+
  labs(y="Price")

#visualising boxplots
grid.arrange(boxpl1,boxpl2,boxpl3,nrow=1, top="Boxplots")

#We will need to investigate if this line is an outlier.


#1.2 Pairs plot - to visualise the relationship between all the variables and to identify any explanatory variables correlating between them

ggpairs(dataprice, lower = list(continuous = wrap("points",alpha = 0.3, color = "blue")), diag = list(continuous = wrap("barDiag", colour = "blue")), upper = list(continuous = wrap("cor", size = 5)))
#outcomes:
#all the graphs of explanatory vs. response variables show an odd pattern, there is one point standing very far from the others
#and there is no visible linear relationship between the explanatory variables and the response one.
#The pairs graphs confirm the presence of a potential outlier for price, sqft and bath parameters.
#It can be also seen from the graphs that the three explanatory variables reflecting the distance to amenities strongly correlate between each other.
#The square footage of the house positively correlates with the number of the bathrooms, but the pattern seems to be affected by one extreme point. 



#2. Model diagnostics and outlier detection
#Let's start with the most general linear model including all the variables:
pricemodel<-lm(formula=price~.,data=dataprice)

summary(pricemodel)
#As we can see from the initial model summary, the bath and sqft variables seem to have a significant relationship
#with the response, but let's check the assumptions of the model.

par(mfrow=c(2,2))
plot(pricemodel)
#Let's analyse the residuals plots to check the assumptions of our model
#Residuals vs. Fitted - there is one fitted value standing very far from the rest of the points, 
#on the far right part of the graph which creats an odd pattern,the red line which should be roughly horizontal and close to zero, goes steeply down and then up again.
#This indicates the nonconstancy of the variance, we will probably need to exclude the outlier (if the point is an outlier)
#or carry out a transformation to fix this.

#Normal Q-Q plot - the 348 row stands out of the main curve, it will probably need to be excluded from the model 

#Scale-Location plot - the Fitted values vs. standardized residuals plot shows the similar pattern to Residuals vs. Fitted plot
#and confirms that the 348 will probably need to be excluded from the model

#Cook's distance - finally, the Cook's distance on the Residuals vs. Leverage graph confirms that the row 348 should be excluded

#Formal outlier test - to confirm our choice of the outlier formally, let's carry out the outliers test:
outlierTest(pricemodel)
#The test gives us the same result, so the row 348 should be excluded from the data.

dataprice<-dataprice[rownames(dataprice)!="348",]

#Let's analyse the residuals plots again to see if the removal of the outlier fixed the violations of the assumptions.
pricemodel<-lm(formula=price~.,data=dataprice)

plot(pricemodel)

#Residuals vs. Fitted - the removal of the outlier has fixed the problem of nonconstancy in the variance,
#there is no need for transformation.

#Normal Q-Q plot - the plot shows a short-tailed distribution:the pattern corresponds to the theoretical line in the center,
#but the points are above the line in the bottom left part and under the line in the top right part. 

#The Scale-Location plot confirms that the variance of the residuals is constant (roughly horizontal red line).

#Cook's distance plot shows that there is no outliers in the data.

#Let's have a look at the pairs plot again to see if the patterns have changed after the outlier removal.

ggpairs(dataprice, lower = list(continuous = wrap("points",alpha = 0.3, color = "blue")), diag = list(continuous = wrap("barDiag", colour = "blue")), upper = list(continuous = wrap("cor", size = 5)))


#3. Model Selection
#3.1 Variables selection 
#We will use the stepwise model selection method to narrow down the selection of the variables:
model<-step(pricemodel,direction="both")

#the final model is: price ~ bath + sqft

#3.2 Checking assumptions of the model

plot(model)
#Residuals vs. Fitted - there is no problem of nonconstancy in the variance, the red line is roughly horizontal

#Normal Q-Q plot - the plot shows a short-tailed distribution with good fit for the majority of the points
#and more distant points on the tails. As the consequences of non-normality for short-tailed distributions are not serious,
#so can be ignored (as per p.80, "Linear Models with R, Second Edition", Julian J. Faraway,2016)

#The Scale-Location plot confirms that there is no major problems with nonconstance of the variance (roughly horizontal red line).

#Residuals vs. Leverage plot indicates that there are no outliers in the model.

#3.3 Checking the variables in the model
#As per our analysis, two explanatory variables out of 8 explain the variability of the house price:
#the number of bathrooms and the square footage of the house.
#Here are the plots visualising the relationship of each of this variables with the price
qplot(sqft,price,data=dataprice)+geom_smooth(method="lm",se=FALSE)
qplot(bath,price,data=dataprice)+geom_smooth(method="lm",se=FALSE)
#The bath vs. price plot illustrates a strong poisitive linear relationship, however the sqft vs. price relationship appears to be very weak.

summary(model)
#From the summary output, we can see that the p-value for the sqft variable is more than 0.05 (0.1424). This indicates
#that the relationship between this variable and the response is not significant.

#Before concluding anything, let's check the confidence intervals:
confint(model)
#The confidence interval for bath variable does not contain 0 (169095,181661), so the relationship between this
#explanatory variable and the response is significant. However, the CI for sqft variable contains 0 (-3.99,27.7),
#so the relationship between this variable and the price is not significant. We need to drop this variable, but let's
#check the single models first.

#Single models:
#bath vs. price
summary(lm(formula=price~bath,data=dataprice))
confint(lm(formula=price~bath,data=dataprice))
#both summary and confidence interval outputs confirm the significant relationship
#between bath variable alone and price, as p-value is less than 0.05
#and the CI doesn't contain 0 (169355,181916)

#sqft vs. price
summary(lm(formula=price~sqft,data=dataprice))
confint(lm(formula=price~sqft,data=dataprice))
#the sqft variable alone shows no significant relationship with price, as we can see from both 
#confidence interval which contains 0 (-5.96,78.01) and summary output where p-value is greater than 0.05

#As both the outcome of the confidence intervals and of the model summary suggest, the sqft variable does not have 
#a significant relationship with the price. 
finalmodel<-lm(price~bath,data=dataprice)
#Let's check the adjusted R squared coefficient of the model before dropping the sqft variable and after:
summary(model)
summary(finalmodel)
# The adj. R squared is 0.8589 for the model before dropping the sqft variable and 0.8586 after dropping the sqft variable.
#There is no major change in adj. R squared coefficient, we retain only one variable - the number of the bathrooms

#Let's check the assumptions again to ensure there is no violations:

plot(finalmodel)

#Residuals vs. Fitted - no problem of nonconstant variance

#Normal Q-Q plot - again a short-tailed distribution with good fit for the majority of the points
#and more distant points on the tails.

#The Scale-Location plot - no problems with nonconstance of the variance.

#Residuals vs. Leverage plot - no outliers in the model.

#4. Conclusions
#the final model: price=beta0+beta1*bath+epsilon
#beta0=58403
#beta1=175635

#The analysis of the data has shown that the number of bathrooms is the only variable explaining the variability of the price
#in our dataset. Even if initially the square footage of the house was included in the model, the confidence intervals check revealed
#the insignificance of the relationship. The final model explains 85.86% of variability of the house price
#and shows that for every one unit increase in the number of bathrooms, the price increases by 175635 on average.

