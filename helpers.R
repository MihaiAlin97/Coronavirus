get_stats = function(dataframe,x){
  
  local_data =  data.frame(matrix(ncol = 4, nrow = 0))
  to_find = deparse(substitute(x))
  colnames(local_data) = c(to_find,"Confirmed","Deaths","Recovered")
  
  variables = unique(dataframe[,to_find])
  
  
  for(variable in variables){
    ##get dataframe for each unicue to_find
    data = dataframe[which(dataframe[,to_find] == variable),]
    
    ##get the max for the three values for each province in our variable
    stats_per_province = aggregate(cbind(Confirmed, Deaths ,Recovered)~Province.State,data = data , FUN = max)
    
    ##get the sum of confirmed, deaths, recovered per country
    confirmed = sum(stats_per_province$Confirmed)
    deaths = sum(stats_per_province$Deaths)
    recovered = sum(stats_per_province$Recovered)
    
    local_data[nrow(local_data) + 1,] = c(variable,as.numeric(confirmed),as.numeric(deaths),as.numeric(recovered))
  }
  local_data[,to_find] = as.factor(local_data[,to_find])
  local_data$Confirmed = as.numeric(local_data$Confirmed )
  local_data$Deaths    = as.numeric(local_data$Deaths )
  local_data$Recovered  = as.numeric(local_data$Recovered )
  return(local_data)
}