# Push presentations to Trello for sorting
######################################################
#Start with the raw data pulled from the OpenConf website (ones reviews file and one submissions files)
#This script creates a new board, lists for each sorting topic, and places the cards into the board under the appropriate list/session. The description contains the first author and abstract. 
#Each section that calls the API with a POST command is commented out so that if the script is run it does not create duplicate cards/boards/lists. Uncomment these sections when creating boards/cards for the first time
#####################################################

#clear workspace
rm(list=ls())

#required libraries
library(pacman)
p_load("rjson", "dplyr", "jsonlite", "httr", "tidyr")

#source Alicia's token information (defines key, token and oath)
source('~/UnsyncedDocuments/API_reference/trello_token.R', chdir = TRUE)


# Read in list of presentations (raw spreadsheets are in data/year folder)
abstracts <- read.csv(file="data/2019/openconf-IASSIST2019-submissions-all-201812072148.csv", stringsAsFactors = FALSE)
reviews <- read.csv(file="data/2019/openconf-IASSIST2019-reviews-201812072149.csv", stringsAsFactors = FALSE)

#remove "&" and "?" from abstracts
abstracts$ABSTRACT <- gsub("&", "and", abstracts$ABSTRACT)
abstracts$ABSTRACT <- gsub("\\?", ".", abstracts$ABSTRACT)

#Remove reviews without a score (workshops/posters)
abstracts <- subset(abstracts, !is.na(abstracts$SCORE))

summary(reviews$SUBMISSION.ID %in% abstracts$SUBMISSION.ID) 
summary(abstracts$SUBMISSION.ID %in% reviews$SUBMISSION.ID)

#merge files by submisison id- keep long format for now
allsubs <- merge(reviews, abstracts, by="SUBMISSION.ID", all=T)

###########################
# CREATE NEW BOARD ########
###########################

name <- "IASSIST_2019_Sorting"
params <- list() 
url_base <- 'https://api.trello.com/1/boards' 
params$name <- paste0('name=', name)
params$token <- paste0('token=',token) 
params$key <- paste0('key=', key)
params$defaultlists <- paste0('defaultLists=', 'false')

#compiles request (only have to do this 1 time - uncomment and run)
# newboard <- POST(paste0(url_base, "?", paste(unlist(params), collapse='&')))
# stop_for_status(newboard)

###########################
# CREATE LISTS     ########
###########################
#If initial sorting has not happened, use topic selected by the author

#create variable with topics for initial list placement
allsubs$InitialList <- unlist(lapply(strsplit(allsubs$TOPICS, ","), function(x){x[1]}))

#Remove "&" from list topics
allsubs$InitialList <- gsub("&", "and", allsubs$InitialList)


#first retrieve ID of new board for reference
params <- list() 
params$token <- paste0('token=',token) 
params$key <- paste0('key=', key)

boardnames <- fromJSON(paste0("https://api.trello.com/1/members/me/boards", "?", paste(unlist(params), collapse='&')))
boardnames <- flatten(boardnames)

#Get new board ID
boardid <- boardnames$id[which(boardnames$name==name)]

#Create lists for each group
params <- list() 
url_base <- 'https://api.trello.com/1/lists/' 
params$token <- paste0('token=',token) 
params$key <- paste0('key=', key)
params$idBoard <- paste0('idBoard=', boardid)

# for (i in rev(levels(factor(allsubs$InitialList)))) {
#   params$name <- paste0('name=', gsub(" ", "%20", i))
#   stop_for_status(POST(paste0(url_base, "?", paste(unlist(params), collapse='&'))))
# }

###########################
# CREATE LABELS     ########
###########################
# Create a label for sessions submitted as a panel

name <- "Panel"
color <- "orange"

#Create lists for each group
params <- list() 
url_base <- 'https://api.trello.com/1/labels' 
params$token <- paste0('token=',token) 
params$key <- paste0('key=', key)
params$idBoard <- paste0('idBoard=', boardid)
params$name <- paste0('name=', name)
params$color <- paste0('color=', color)

# newlabel <- POST(paste0(url_base, "?", paste(unlist(params), collapse='&')))
# stop_for_status(newlabel)

###########################
# CREATE CARDS     ########
###########################
#pull ids of created lists
params <- list() 
url_base <- 'https://api.trello.com/1/boards/' 
params$token <- paste0('token=',token) 
params$key <- paste0('key=', key)

boarddata <- fromJSON(paste0(url_base, boardid, "/lists/", "?", paste(unlist(params), collapse='&')))
listdata <- as.data.frame(do.call(cbind, boarddata))

labeldata <- fromJSON(paste0(url_base, boardid, "/labels/", "?", paste(unlist(params), collapse='&')))

#Add cards to each list
params <- list() 
url_base <- 'https://api.trello.com/1/cards/' 
params$token <- paste0('token=',token) 
params$key <- paste0('key=', key)
params$idBoard <- paste0('idBoard=', boardid)


## Include all authors in card description
## Add the scores to the descriptions
## Include reviewer comments
## Add certain labels? such as panel
## Add notes from reviewers that were recommended to move to poster
## Numer the columns to match word document
# for (i in levels(factor(allsubs$SUBMISSION.ID))) {
#   #create temp subset of data for that submission ID
#   temp <- subset(allsubs, allsubs$SUBMISSION.ID==i)
#   
#   #Determine card's list based on initial topic
#   params$list <- paste0('idList=', listdata$id[which(listdata$name == temp$InitialList[1])])
#   #Name the card based on session number and title
#   params$name <- paste0('name=', paste(temp$SUBMISSION.ID[1], URLencode(temp$TITLE[1], reserved = TRUE), sep=":%20"))
#   
#   #Add description - all authors and abstract; reveiwer ratings and comments
#   authors <- temp[1,grep("AUTHOR.[[:digit:]].LAST.NAME", names(temp))]
#   authorlist <- paste(authors[,which(authors!="")], collapse=";")
#   
#   #average rating
#   rating <- temp$SCORE[1]
#   
#   #text of reviewer comments
#   reviews <- subset(temp, temp$REVIEW.COMPLETED..TRUE.FALSE.=="TRUE")
#   reviewercomments <- paste(reviews$PC.COMMENTS[which(reviews$PC.COMMENTS!="")], collapse="; ")
#   
#   #reviewer suggested topics
#   revieweralltopics <- reviews[,grep("ADDITIONAL.SESSION.TOPIC", names(reviews))]
#   reviewertopics <- paste(unique(revieweralltopics[revieweralltopics!=""]), collapse="; ")
#   
#   #review suggested sessions
#   reviewersession <- unique(gsub("\n", "", unlist(strsplit(reviews$APPROPRIATE.SESSION, "\n    - "))))
#   
#   #add Panel label if submitted as such
#   label <- ifelse("Panel" %in% temp$SUBMISSION.TYPE, labeldata$id[which(labeldata$name=="Panel")], "")
#   
#   params$desc <- paste0('desc=', "Rating:%20", "%0A%0A", URLencode(as.character(rating)), "Authors:%20", URLencode(authorlist), "%0A%0A", URLencode(temp$ABSTRACT[1], reserved = TRUE),"%0A%0A", "Reviewer%20Comments:%20", URLencode(reviewercomments), "%0A%0A", "Reviewer%20Topics:%20", URLencode(reviewertopics), "%0A%0A", "Reviewer%20Session:%20", URLencode(reviewersession))
#   
#   params$label <- paste0('label=', label)
#   
#   if (label == "") {
#     params[[which(names(params)=="label")]] <- NULL
#   }
#   
#     stop_for_status(POST(paste0(url_base, "?", paste(unlist(params), collapse='&'))))
# }





