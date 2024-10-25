#!/bin/bash

# Place the handles in file "handles.txt" in the following format:
# 1234.5/123456
INPUT_FILE="handles.txt"
LOG_FILE="rdfizer.log"

# write_log() function :
write_log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> ${LOG_FILE}      
}

# Create log file :
rm -f ${LOG_FILE}
touch ${LOG_FILE}

# Generate RDF docs :
write_log "Begin generating rdf documents ... "
echo >> ${LOG_FILE}

while IFS= read -r handle; do
        write_log "Generating handle for ${handle} ... "
        /dspace/bin/dspace rdfizer -i ${handle}
        write_log "Finished generating handle for ${handle} ... "
        echo >> ${LOG_FILE}
done < "${INPUT_FILE}"

echo >> ${LOG_FILE}
write_log "Completed generating rdf documents ... "
