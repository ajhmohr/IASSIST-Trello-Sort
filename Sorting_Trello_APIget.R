# Get current Trello board status
######################################################

#required libraries
library(pacman)
p_load("rjson", "dplyr", "jsonlite", "httr", "readxl", "tidyr", "reshape2")

#source Alicia's token information (defines key, token and oath)
#To run this, you will need to get this information from https://trello.com/app-key 
#I save this information in an R script that I source below to read in each of these values
source('~/UnsyncedDocuments/API_reference/trello_token.R', chdir = TRUE)



###########################
# Pull down board  ########
###########################

name <- "IASSIST_2019_Sorting"

#first retrieve ID of new board for reference
params <- list() 
params$token <- paste0('token=',token) 
params$key <- paste0('key=', key)

boardnames <- fromJSON(paste0("https://api.trello.com/1/members/me/boards", "?", paste(unlist(params), collapse='&')))
boardnames <- flatten(boardnames)

#Get new board ID
boardid <- boardnames$id[which(boardnames$name==name)]

#Get list names
listnames <- fromJSON(paste0("https://api.trello.com/1/boards/", boardid, "/lists/", "?", paste(unlist(params), collapse='&')))

#Pull down current cards and organization
url_base <- 'https://api.trello.com/1/boards/' 
params$cards <- paste0('cards=', "all")
params$token <- paste0('token=',token) 
params$key <- paste0('key=', key)

#compiles the parameters into a URL for API pull
pull <- paste0(url_base,"/", boardid, "?",paste(unlist(params),collapse='&')) 

#pulls the data
board <- fromJSON(pull)

#flattens the json data into a dataframe (use this for multi-level nesting)
#ignore warnings - has to do with character vs factor encoding
data <- flatten(board$cards)

names(data)

#replace list ids with list names
data <- as.data.frame(data)
data$listname <- ""

for (i in 1:nrow(data)) {
  data$listname[i] <- as.character(listnames$name[which(listnames$id == data$idList[i])])
}

data$SubID <- gsub(":.*", "", data$name)
data$name <- gsub("[[:digit:]]{2,3}: ", "", data$name)

#Include column with labels
#collect label reference
labels <- do.call(rbind,data$labels)

#unlist label IDs
data$labels <- unlist(lapply(data$idLabels, paste, collapse="; "))

##replace label ids with names
for (i in 1:nrow(labels)) {
  data$labels <- gsub(unlist(labels$id)[i], unlist(labels$name)[i], unlist(data$labels))
}

#remove GIS and REVIEW label
#data$labels <- gsub("REVIEW|GIS|; ", "", data$labels)


data1 <- subset(data, select=c("listname", "SubID","labels", "name", "desc"))
write.csv(data1, file=paste0("board_backup/Pulled_Trello_State", gsub("-", "", Sys.Date()), ".csv"), row.names=FALSE)

###############################
# check that they are all here
###############################
head(data1)

#read in submissions
submissions <- read_excel("Sorting Sheet with Abstracts.xlsx")

summary(submissions$`SUBMISSION ID` %in% data1$SubID)
summary(data1$SubID %in% submissions$`SUBMISSION ID`)

submissions$`SUBMISSION ID`[which(submissions$`SUBMISSION ID` %in% data1$SubID==FALSE)]
data1$SubID[which(data1$SubID %in% submissions$`SUBMISSION ID`==FALSE)]

#############################
#check for author overlap
############################

#remove cards in POSTER 
data1 <- filter(data1, listname != "MOVE TO POSTER")

#read in presenters by submission tab
presenters <- read_excel("IASSIST & CARTO 2018 AG 122617 .xlsx", sheet=4)

summary(presenters$`Sub ID` %in% data1$SubID)
presenters[which(presenters$`Sub ID` %in% data1$SubID==FALSE),]

datap <- merge(presenters,data1, by.y="SubID", by.x="Sub ID", all.y=T)
	#presenters data table had 6 more presentations than in our sort (190, 70, 142, 74, 194, plus 37) - I assume the rest were rejected? 
	
#reshape so presenter names are in one column
datap1 <- melt(datap, id.vars = c("Sub ID", "listname", "name", "desc", "PRESENTATION TYPE"), value.name="Presenter", na.rm=T)

counts <- datap1 %>% 
  group_by(Presenter) %>% 
  summarize(Npres=n()) %>% 
  arrange(desc(Npres))

bypres <- datap1 %>% 
  group_by(Presenter, `Sub ID`) %>% 
  summarize(count=n()) %>% 
  arrange(Presenter)

countrows <- function(x) {1:nrow(x)}

bypres$PresNum <- paste("Pres", unlist(by(bypres, bypres$Presenter, countrows)), sep="_")

bypresw <- dcast(bypres, Presenter ~ PresNum, value.var = "Sub ID")

prescount <- merge(counts, bypresw, by="Presenter")
prescount <- arrange(prescount, desc(Npres))

write.csv(filter(prescount, Npres > 1), file="Presenters_with_multiple.csv", row.names=FALSE)
