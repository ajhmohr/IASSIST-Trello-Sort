# IASSIST-Trello-Sort
Scripts to create Trello board from sorting from IASSIST OpenConf data

## Create Trello Board from OpenConf data

`Sorting_Trello_APIpost.r` takes in raw data (.csv format) pulled from the OpenConf website (one file with reviewer information; one file with abstract/author information).  It creates a new Trello board with all of the submissions as cards, and the first author topic as the current list. Cards include abstract, authors, topics, and reviewer total score. All POST sections are commented out and will need to be uncommented to run. 

* Requires Trello API key, token, and auth (currently read in from outside script)
* To generate API key, log into https://trello.com/app-key


## Backing up Trello Board state

`Sorting_Trello_APIget.R` backs up a Trello board into a .csv file with the current list each card is on. Code at the bottom is included to check whether all submissions are in the Trello board (against the initial abstract/author file), and the extent of author overlap on presentations. Also requires a Trello API key/token/auth. 

