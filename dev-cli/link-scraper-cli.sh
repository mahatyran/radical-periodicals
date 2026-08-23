#!/bin/bash

# ---------------------------
# Change the below three variables based on what you're downloading
# ---------------------------
URL_REGEX="^(https?):\/\/([a-zA-Z0-9.-]+(:[0-9]+)?)\/?([^ ]*)$"
PERIODICAL_NAME_REGEX="^[[:lower:]-]+$"
PERIODICAL_ACRONYM_REGEX="^[[:lower:]]+$"

INDEX=$1
PERIODICAL_NAME=$2
PERIODICAL_ACRONYM=$3

VALID=true
INVALID_INPUTS=""

if [ "$#" -ne 3 ]; then
  VALID=false
fi

if [[ ! $INDEX =~ $URL_REGEX ]]; then
  VALID=false
  INVALID_INPUTS+="$INDEX "
fi

if [[ ! $PERIODICAL_NAME =~ $PERIODICAL_NAME_REGEX ]]; then
  VALID=false
  INVALID_INPUTS+="$PERIODICAL_NAME "
fi

if [[ ! $PERIODICAL_ACRONYM =~ $PERIODICAL_ACRONYM_REGEX ]]; then
  VALID=false
  INVALID_INPUTS+="$PERIODICAL_ACRONYM "
fi

if [ "$VALID" = false ]; then
  echo ""
  echo "Inputs provided: $INDEX $PERIODICAL_NAME $PERIODICAL_ACRONYM"
  echo "Invalid inputs: $INVALID_INPUTS"
  echo "Three arguments required."
  echo ""
  echo "Usage: $0 <index url> <periodical name> <periodical acronym>"
  echo "Example usage: $0 https://www.marxists.org/history/usa/pubs/black-panther/ black-panther bpp"
  echo ""
  echo "<index url> should link to a valid webpage containing links to pdfs of the periodical you want to scrape. It must start with https:// or http://."
  echo "<periodical name> should be the name of the periodical, only with lowercase alphabetic characters and dashes."
  echo "<periodical acronym> should be a short acronym for the periodical, only with lowercase alphabetic characters."
  exit 1
fi

# ---------------------------
# Don't touch anything below!
# ---------------------------

LINKS_OUTPUT_FILE="./csv-output/${PERIODICAL_ACRONYM}_links"
ANCHORS_OUTPUT_FILE="./csv-output/${PERIODICAL_ACRONYM}_anchors"
CSV_OUTPUT_FILE="./csv-output/${PERIODICAL_ACRONYM}_issues_links_covers.csv"
echo "vol_iss_date", "pdf_link", "cover_loc", "iss_loc" > "$CSV_OUTPUT_FILE"
ISSUES_DIR="./periodicals/${PERIODICAL_NAME}/${PERIODICAL_ACRONYM}-issues/"
COVERS_DIR="./periodicals/${PERIODICAL_NAME}/${PERIODICAL_ACRONYM}-covers/"
mkdir -p $ISSUES_DIR
mkdir -p $COVERS_DIR

echo "Scraping links from ${INDEX}"

curl -s $INDEX | grep -Po '(?<=<a href=")[^"]*' > $LINKS_OUTPUT_FILE
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