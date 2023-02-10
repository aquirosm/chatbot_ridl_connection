
# Load libraries

library(ridl)
library(tidyverse)
library(httr)
library(jsonlite)
library(readxl)
library(writexl)
library(lubridate)
library(zoo)
library(tidytext)
library(stopwords)



# Extract info from turn server. Set link server and turn token


link <- "https://whatsapp.unhcr.cloud.turn.io/v1/data/messages/cursor"

turn_token <- "XXXXXX"

# Create filter by date and set request parameters

start_date <- "2023-01-01 00:00"
end_date <- "2023-01-31 23:59"


request_body <- paste0('{
"order_by": "asc",
"page_size": "100",
"from": "',start_date,'",
"until": "',end_date,'"
}')  



# Create cursor request (POST)

request <- POST(url = link,
                body = request_body,
                content_type_json(),
                accept("application/vnd.v1+json"),
                add_headers(.headers= c(Authorization = paste0("Bearer ",turn_token))))


# Identify cursor

cursor <- fromJSON(content(request, "text"))$cursor


# Create data request (GET). Loop to get data from all cursor pages 
# First page = server...cursor, Second page = server...cursor_response$paging$`next` ,...

paging <- cursor

messages <- data.frame()

while (is.null(paging)==FALSE)
{
  cursor_response <- GET(url= paste0(link,"/",paging),
                         content_type_json(),
                         accept("application/vnd.v1+json"),
                         add_headers(.headers= c(Authorization = paste0("Bearer ",turn_token))))
  
  
  messages <- bind_rows(messages,fromJSON(content(cursor_response, "text"))$data)
  
  paging <- fromJSON(content(cursor_response, "text"))$paging$`next`  
  
}

# extract automator messages

automated <- data.frame(author_type = messages$"_vnd"$v1$author$type,
                        owner = messages$"_vnd"$v1$chat$owner,
                        type = messages$type,
                        state_reason = messages$"_vnd"$v1$chat$state_reason,
                        unread_count = messages$"_vnd"$v1$chat$unread_count,
                        text_body = messages$text$body,
                        timestamp = messages$"_vnd"$v1$inserted_at) %>% 
  filter(is.na(author_type)==FALSE)

# extract owner (users) messages


users_messages <- data.frame()

for (i in messages$messages) {
  
  row <- as.data.frame(i)
  
  users_messages <- bind_rows(users_messages,row) 
  
}

users <- data.frame(author_type = users_messages$"_vnd"$v1$author$type,
                    owner = users_messages$"_vnd"$v1$chat$owner,
                    type = users_messages$type,
                    state_reason = users_messages$"_vnd"$v1$chat$state_reason,
                    unread_count = users_messages$"_vnd"$v1$chat$unread_count,
                    text_body = users_messages$text$body,
                    timestamp = users_messages$"_vnd"$v1$inserted_at)

# create df containing all messages (including text, interactive, document, video...). Filters applied in further step.


new_data <- bind_rows(automated,users)  


# Config RIDL (production or UAT)

ridl_config_setup(site = "test",
                  token = "XXXXXXXX")


# Find the dataset in RIDL to extract/upload files. Assign "ds"
# dataset identifier (name): "chatbot_cr"

ds <- ridl_dataset_show("chatbot_cr")


# Find the existing resource with the consolidated data. Assign "consolidated_rs"
# resource identifier (id): "df767a92-2f1c-42a4-9f15-8ab841458bc0"


consolidated_rs <- ridl_resource_show("df767a92-2f1c-42a4-9f15-8ab841458bc0")


# Read the consolidated data in the file and convert to data frame

consolidated_df <- ridl_resource_read(consolidated_rs) %>% 
  as.data.frame()


# Bind consolidated data with new data


final_df <- rbind(consolidated_df,new_data)


# Write xlsx as consolidated data

write_xlsx(final_df,"./data-raw/data_test_consolidated.xlsx")


# Upload to RIDL the new consolidated file 

ridl_resource_file_to_upload_set(consolidated_rs, file_to_upload="./data-raw/data_test_consolidated.xlsx")


ridl_resource_create(consolidated_rs,ds)

