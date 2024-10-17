#!/bin/bash

# Prerequisites:
# DSpace solr statistics (.csv files) have been exported using the
# "[dspace]/bin/dspace solr-export-statistics" command, and are stored in folders by year.

# Configure variables :
STATS_YEAR="<STATS_YEAR>" # e.g. 2010
SOURCE_FOLDER="<SOLR_STATISTICS_DIRECTORY>/${STATS_YEAR}" # e.g. "/mnt/solr-statistics/${STATS_YEAR}"
SOLR_EXPORT_FOLDER="/dspace/solr-export" # e.g. This is DSpace's default solr export folder.
IMPORT_FINISHED_FOLDER="<IMPORTED_SOLR_STATISTICS>/${STATS_YEAR}" # e.g. "/mnt/imported-solr-statistics/${STATS_YEAR}"
LOG_FILE="${STATS_YEAR}.log"

# NOTE: the year folders in the SOURCE_FOLDER and IMPORT_FINISHED_FOLDER folders will need to be created ahead of time, 
# using command: "mkdir {starting_year..ending_year}" , e.g. mkdir {2010..2024}

# write_log() function :
write_log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> ${LOG_FILE}
}

# Create log file :
rm -f ${LOG_FILE}
touch ${LOG_FILE}


# Begin importing statistics :
write_log "Begin importing statistics for ${STATS_YEAR} ... "
echo >> ${LOG_FILE}

# run solr import job on one csv file at a time :
for file in "${SOURCE_FOLDER}"/*.csv; do
    if [ -f "${file}" ]; then

        write_log "Starting to import \"${file}\" ... "

        mv "${file}" "${SOLR_EXPORT_FOLDER}"
        FILENAME=$(basename "${file}")

        write_log "Moved \"${FILENAME}\" from \"${SOURCE_FOLDER}\" to \"${SOLR_EXPORT_FOLDER}\" ."
        write_log "Importing \"${FILENAME}\" ... "
        
        /dspace/bin/dspace solr-import-statistics -i statistics

        write_log "Finished importing \"${FILENAME}\" ... "
        
        mv "${SOLR_EXPORT_FOLDER}/${FILENAME}" "${IMPORT_FINISHED_FOLDER}"

        write_log "Moved \"${FILENAME}\" to \"${IMPORT_FINISHED_FOLDER}\" ."

        write_log "Completed solr import of \"${FILENAME}\" ."

        echo >> ${LOG_FILE}

        sleep 2
    else
        write_log "No CSV files found in \"${SOURCE_FOLDER}\" ."
    fi
done

echo >> ${LOG_FILE}
write_log "Completed importing statistics for ${STATS_YEAR} ... "
