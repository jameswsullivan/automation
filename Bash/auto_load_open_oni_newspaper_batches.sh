# Start loading sample batches:

echo "creating log file:"
log_file="/opt/openoni/load_batch_log_$(date +%Y%m%d%H%M%S).log"
touch $log_file
echo "log file: $log_file created." 2>&1 | tee -a $log_file

# Loading batches:
list_of_batches="/opt/openoni/batch_names.txt"

if [ ! -f "$list_of_batches"]; then
    echo "Batch Name File Not Found!"
    exit 1
fi

echo "Begin loading batches:" 2>&1 | tee -a $log_file
source ENV/bin/activate

while IFS= read -r batch_name || [ -n "$batch_name" ]; do
    if [ -n "$batch_name" ]; then
        command="./manage.py load_batch /opt/openoni/data/batches/${batch_name}"
        echo "Loading batch: $command" 2>&1 | tee -a "$log_file"
        eval "$command" 2>&1 | tee -a "$log_file"
    fi
done < "$list_of_batches"

echo "Done loading batches." 2>&1 | tee -a $log_file

# Change django cache permission.
echo "Changing django_cache permission." 2>&1 | tee -a $log_file
chmod -R 777 /var/tmp/django_cache
echo "django_cache changed to 777" 2>&1 | tee -a $log_file

echo "Finished loading sample batches." 2>&1 | tee -a $log_file