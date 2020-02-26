source("helpers.R")
##used Kaggle dataset for coronavirus available at 
## https://www.kaggle.com/sudalairajkumar/novel-corona-virus-2019-dataset/data
##we haave 3 time-series datasets(reported cases,death cases,recovered cases) and 
## one dataset consisting in:
## Sno: index
## Date: date of reported cases
## Region/State: region/state
## Country: country where cases have been reported
## Last updated: 
## Reported,Deaths,Recovered number of cases
## data reported as cummullative - each row in the dataset contains the previously reported cases for a region in a country
##

r = read.csv(file = "2019_nCoV_data.csv",header = TRUE)
ncov = data.frame(r)

str(ncov)
Hmisc::describe(ncov)

##we do not need Sno and Last updated columns
ncov = ncov[c(-1,-5)]

##we check that there are no duplicate rows
cat("All rows are unique: ",nrow(ncov)==nrow(unique(ncov)),"\n")

##we remove the time from data as data has been updated following no pattern
ncov$Date=format(as.POSIXct(ncov$Date,format='%m/%d/%Y %H:%M:%S'),format='%m/%d/%Y')


##we sort the dataset by date
ncov = ncov[order(as.Date(ncov$Date, format="%m/%d/%Y")),]

##we replace Bavaria with null,as the province in not reported anymore from 31 february onwards
ncov[which(ncov$Province.State == "Bavaria"),]$Province.State = ""

##we replace China with Hong Kong,Macau,Taiwan on the Country column where Province.State column is one of the three
ncov[which(ncov$Province.State == "Macau" & ncov$Country == "China"),]$Country = "Macau"
ncov[which(ncov$Province.State == "Hong Kong" & ncov$Country == "China"),]$Country = "Hong Kong"
ncov[which(ncov$Province.State == "Taiwan" & ncov$Country == "China"),]$Country = "Taiwan"

##we replace Mainland China with China
ncov[which(ncov$Country == "Mainland China"),]$Country = "China"


##obtaining the max number of confirmed cases for each contry(that is the real number of confirmed cases) along with deaths and recovered
##same for Date
ncov_countries = get_stats(ncov,Country)
ncov_dates = get_stats(ncov,Date)



##adding daily stats for time - series analysis

ncov_dates$DailyConfirmed = c(0,diff(x= ncov_dates$Confirmed, n = 1) )
ncov_dates$DailyDeaths    = c(0,diff(x= ncov_dates$Deaths, n = 1) )
ncov_dates$DailyRecovered = c(0,diff(x= ncov_dates$Recovered , n = 1) )



print(ncov_dates)
print(sum(ncov_countries$Confirmed))


##convert Date column to Date class
ncov_dates$Date = as.Date(ncov_dates$Date, format="%m/%d/%Y")

library(ggplot2)
library(reshape2)


##we plot date against confirmed cases
png(file = "ConfirmedCasesOverTime.png")
print(ggplot(data = ncov_dates, aes(x = factor(Date), y = Confirmed)) +
  geom_bar(stat = "identity", fill = "orange" ,alpha = (c(1:25)/100)*4) +
  theme(axis.text.x = element_text(angle = 30, hjust = 1))+
  labs(title = "ncov2019 Confirmed cases over time",subtitle = "Winter 2020", x = "Date", y = "Confirmed cases"))
dev.off()


##Death and Recovering rates
png(file = "DeathRatevsRecoveryRate.png")
print(ggplot() + 
        scale_color_discrete(name = "Legend", labels = c("Death rate", "Recovery rate"))+
        geom_line(data=ncov_dates,aes(y= Deaths    , x= Date , colour="green"),size=2 )+
        geom_line(data=ncov_dates,aes(y= Recovered , x= Date , colour="red"),size=2 ) +
        labs(title = "ncov2019 Death Rate vs Recovery Rate", x = "Date", y = "")
)
dev.off()
##



##the firt 10 most affected countries
without_china_others = ncov_countries[which(ncov_countries$Country!="China" & ncov_countries$Country!="Others"),]
without_china_others = without_china_others[order(-without_china_others$Confirmed),]
first_ten = without_china_others[1:10,]

##we plot date against confirmed cases

##we tell ggplot we have an ordered factor already
first_ten$Country <- factor(first_ten$Country , levels = first_ten$Country )

png(file = "TenMostAffectedCountries.png")
print(ggplot(data = first_ten, aes(x = Country, y = Confirmed)) +
        geom_bar(stat = "identity", fill = "darkred" ,alpha = (c(10:1))/10) +
        labs(title = "ncov2019 Ten most affected countries", x = "Country", y = "Confirmed cases"))
dev.off()

##mortality rate over time
##no deaths / no confirmed cases

ncov_dates$Mortality = (ncov_dates$Deaths/ncov_dates$Confirmed)*100 
png(file = "MortalityRateOverTime.png")
print(ggplot() +
        geom_line(data=ncov_dates,aes(y= Mortality, x= Date ),size=2 )+
        labs(title = "ncov2019 Mortality Rate Over Time", x = "Date", y = "Mortality(%)"))
dev.off()


##a look inside China's provinces
china = ncov[which(ncov$Country == "China"),]
provinces = aggregate(cbind(Deaths, Recovered)~Province.State,data = china , FUN = max)
provinces = provinces[order(-provinces$Deaths),]
provinces = provinces[1:10,]
provinces = melt(provinces)

png(file = "ChinaProvinces.png")
print(ggplot(data = provinces, aes(x = factor(Province.State), y = log(value) ,fill = factor(variable))) +
        geom_bar(stat = "identity",position = position_dodge())+
        theme(axis.text.x = element_text(angle = -30, hjust = 1))+
        labs(title = "ncov2019 China's most affected provinces", x = "", y = ""))
dev.off()


##daily growth factor 
n = length(ncov_dates$DailyConfirmed)
ncov_dates$GrowthFactor = c(0,ncov_dates$DailyConfirmed[1:n-1]/ncov_dates$DailyConfirmed[2:n])

png(file = "GrowthFactor.png")
print(ggplot() + 
        geom_line(data=ncov_dates,aes(y= GrowthFactor, x= Date),colour = "cyan",size=2 )+
        theme(axis.text.x = element_text(angle = -30, hjust = 1))+
        labs(title = "Growth Factor", x = "Date", y = "Daily cases growth factor")
)
dev.off()

##Newly Infected vs. Newly Recovered

png(file = "NewlyInfectedvsNewlyRecovered.png")
print(ggplot() + 
        geom_line(data=ncov_dates,aes(y= DailyConfirmed, x= Date),colour = "yellow",size=2 )+
        geom_line(data=ncov_dates,aes(y= DailyRecovered, x= Date),colour = "green",size=2 )+
        theme(axis.text.x = element_text(angle = -30, hjust = 1))+
        labs(title = "Newly Infected vs. Newly Recovered", x = "", y = "No people")
)
dev.off()

