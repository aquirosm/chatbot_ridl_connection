
# Load libraries

library(ridl)
library(tidyverse)
library(httr)
library(jsonlite)
library(readxl)
library(writexl)


# Config RIDL (production or UAT)

# ridl_config_setup(site = "prod/test",
#                  key = "XXXXXXXXXX")


# Find the dataset in RIDL to extract/upload files. Assign "ds"
# dataset identifier (name): "chatbot_cr"

ds <- ridl_dataset_show("chatbot_cr")


# Find the existing resource with the consolidated data. Assign "consolidated_rs"
# resource identifier (id): "45fb1370-70fb-4f73-8c88-f8e43fde856b"


consolidated_rs <- ridl_resource_show("45fb1370-70fb-4f73-8c88-f8e43fde856b")


# Read the consolidated data in the file and convert to data frame

consolidated_df <- ridl_resource_read(consolidated_rs) %>% 
  as.data.frame()


# Extract daily data from turn server (only day before)
###### This is where we make the API call from the turn.io server (script in Python provided by Sofia)


# Read the new data and bind to the consolidated data

new_df <- read_excel("./data-raw/data_test_new.xlsx") %>% 
  as.data.frame()

final_df <- rbind(consolidated_df,new_df)


# Write xlsx as consolidated data

write_xlsx(final_df,"./data-raw/data_test_consolidated.xlsx")


# Upload to RIDL the new consolidated file ()

ridl_resource_file_to_upload_set(consolidated_rs, file_to_upload="./data-raw/data_test_consolidated.xlsx")

ridl_resource_create(consolidated_rs,ds)

