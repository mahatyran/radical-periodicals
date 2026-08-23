#!/bin/bash

# ---------------------------
# Change the below three variables based on what you're downloading
# ---------------------------
PERIODICAL_NAME="black-panther"
PERIODICAL_ACRONYM="bpp"
INDEX="https://www.marxists.org/history/usa/pubs/black-panther/"

# ---------------------------
# Don't touch anything below!
# ---------------------------

LINKS_OUTPUT_FILE="./csv-output/${PERIODICAL_ACRONYM}_links"
ANCHORS_OUTPUT_FILE="./csv-output/${PERIODICAL_ACRONYM}_anchors"
CSV_OUTPUT_FILE="./csv-output/${PERIODICAL_ACRONYM}_issues_links_covers.csv"
echo "vol_iss_date", "pdf_link", "cover_loc", "iss_loc" > "$CSV_OUTPUT_FILE"
ISSUES_DIR="./periodicals/${PERIODICAL_NAME}/${PERIODICAL_ACRONYM}-issues/"
COVERS_DIR="./periodicals/${PERIODICAL_NAME}/${PERIODICAL_ACRONYM}-covers/"

echo "Scraping links from ${INDEX}"

curl -s $INDEX | grep -Po '(?<=href=")[^"]*' > $LINKS_OUTPUT_FILE
echo "Scraped links and saved to ${LINKS_OUTPUT_FILE}"

curl -s $INDEX | perl -0777 -ne 'while (/<a\b[^>]*>(.*?)<\/a>/gis) { print "$1\n" }' > $ANCHORS_OUTPUT_FILE
echo "Scraped anchor text and saved to ${ANCHORS_OUTPUT_FILE}"

paste $LINKS_OUTPUT_FILE $ANCHORS_OUTPUT_FILE | while IFS=$'\t' read -r link anchor; do
  if [[ "$link" == *.pdf ]]; then
    echo "$link $anchor"

    encoded_tmp="${link// /%20}"
    download_link="${INDEX}${encoded_tmp}"
    issue_output_file="${ISSUES_DIR}${encoded_tmp}"
    cover_output_file="${COVERS_DIR}${encoded_tmp:0:-4}_cover.pdf"

    # if file doesn't exist or is empty
    if [ ! -s "$issue_output_file" ]; then
      curl -L -o "$issue_output_file" "$download_link"
    else
      echo "$issue_output_file already exists."
    fi
    
    if [ ! -s "$cover_output_file" ]; then
      qpdf "$issue_output_file" --pages "$issue_output_file" 1 -- "$cover_output_file"
    else
      echo "$cover_output_file already exists."
    fi

    echo "\"$anchor\", $download_link, $cover_output_file, $issue_output_file" >> $CSV_OUTPUT_FILE
  fi
done

echo "All issues, covers downloaded!"
echo "See information in ${CSV_OUTPUT_FILE}"