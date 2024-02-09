#!/bin/bash

touch loadFile.log

DATABASE_NAME=""
TABLE_NAME=""

for file in *.csv
do
        mysql -e "USE $DATABASE_NAME; \
        LOAD DATA LOCAL INFILE '"$file"' \
        INTO TABLE $TABLE_NAME \
        FIELDS TERMINATED BY ',' \
        ENCLOSED BY '\"' \
        LINES TERMINATED BY '\r\n' \
        IGNORE 1 LINES \
        (col1, col2, col3);" \
        --local-infile=1 -u root --password=1234

        timestamp=$(date +"%Y-%m-%d %H:%M:%S")
        echo "'"$file"' has been loaded - '"$timestamp"'" >> loadFile.log
done