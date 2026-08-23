#!/bin/bash

# Check if the CSV file exists
PERIODICALS_INDEX_DB_CSV="periodicals_index_db.csv"
if [ ! -f $PERIODICALS_INDEX_DB_CSV ]; then
    echo "Error: $PERIODICALS_INDEX_DB_CSV not found."
    exit 1
fi

# Read the CSV line by line
tail -n +2 $PERIODICALS_INDEX_DB_CSV | tr -d '\r' | while IFS=',' read -r index name acronym || [ -n "$index" ]; do
    
    # Skip empty lines
    [ -z "$index" ] && continue
    
    # Call your CLI using the 3 arguments
    dev-cli/link-scraper-cli.sh $index $name $acronym

done