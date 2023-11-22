#!/bin/bash
# Usage: ./getFormsData.sh
#
# You can specify the files' name with:
#        SITES_URLS_FILE=sites_urls.txt \
#        SITES_PATHS_FILE=sites_paths.txt \
#        DATA_CSV_FILE=forms_data.csv \
#        ./getFormsData.sh
#
# Use `--clear` to remove all the previously generated files
#

# Default files names
SITES_URLS_FILE="${SITES_URLS_FILE:-sites_urls.txt}"
SITES_PATHS_FILE="${SITES_PATHS_FILE:-sites_paths.txt}"
DATA_CSV_FILE="${DATA_CSV_FILE:-forms_data.csv}"

if [ "$1" == '--clear' ]; then
  rm ${SITES_URLS_FILE} || true
  rm ${SITES_PATHS_FILE} || true
  rm ${DATA_CSV_FILE} || true
fi

# Retrieve the sites that have the WPForms category
if [ ! -f "$SITES_URLS_FILE" ]; then
  echo "Retrieving sites list from wp-veritas.epfl.ch"
  curl -s https://wp-veritas.epfl.ch/api/v1/categories/WPForms/sites | jq  '.[] | .url' > $SITES_URLS_FILE
fi

# Function that convert URL to site's path on the server
URLtoPath () {
  if [[ $1 =~ (www.epfl.ch/labs/) ]]; then
    lab_name=$(echo $1 | sed -n 's/https:\/\/www.epfl.ch\/labs\///gp' | tr -d '"')
    echo "/srv/labs/www.epfl.ch/htdocs/labs/${lab_name}"
  elif [[ $1 =~ (www.epfl.ch/research/) ]]; then
    research_name=$(echo $1 | sed -n 's/https:\/\/www.epfl.ch\/research\///gp' | tr -d '"')
    echo "/srv/www/www.epfl.ch/htdocs/research/domains/${research_name}"
  elif [[ $1 =~ (www.epfl.ch/schools/) ]]; then
    school_name=$(echo $1 | sed -n 's/https:\/\/www.epfl.ch\/schools\///gp' | tr -d '"')
    echo "/srv/www/www.epfl.ch/htdocs/schools/${school_name}"
  elif [[ $1 =~ (www.epfl.ch) ]]; then
    www_name=$(echo $1 | sed -n 's/https:\/\/www.epfl.ch\///gp' | tr -d '"')
    echo "/srv/www/www.epfl.ch/htdocs/${www_name}"
  elif [[ $1 =~ (inside.epfl.ch) ]]; then
    inside_name=$(echo $1 | sed -n 's/https:\/\/inside.epfl.ch\///gp' | tr -d '"')
    echo "/srv/inside/inside.epfl.ch/htdocs/${inside_name}"
  else
    subdomainlite_name=$(echo $1 | sed -n 's/https:\/\///gp' | sed -n 's/.epfl.ch\///gp' | tr -d '"')
    echo "/srv/subdomains-lite/${subdomainlite_name}.epfl.ch/htdocs/"
  fi
}

if [ ! -f "$SITES_PATHS_FILE" ]; then
  # Convert each URL to path and save them in $SITES_PATHS_FILE
  while IFS= read -r line; do 
    echo "Extracting path from $line";
    URLtoPath $line >> $SITES_PATHS_FILE;
  done < $SITES_URLS_FILE
fi

# Generate the $DATA_CSV_FILE CSV file based on each path of $SITES_PATHS_FILE
echo "path|formID|postTitle|hasUploadField|hasPayOnline|payOnlineID|payOnlineIDnumberOfEntries|numberOfEntries" > $DATA_CSV_FILE
while IFS= read -r path
do
  echo "Running wp cli for $path"
  formIDs=$(ssh -n wwp-prod -- "wp db query --path=$path 'SELECT ID FROM wp_posts wp WHERE wp.post_type='\''wpforms'\'' AND wp.post_status='\''publish'\'';' --skip-column-names;" 2>/dev/null)
  for formID in $formIDs; do 
    postTitle=$(ssh -n wwp-prod -- "wp db query --path=$path 'SELECT post_title FROM wp_posts wp WHERE wp.ID=$formID;' --skip-column-names;" 2>/dev/null)
    hasUploadField=$(ssh -n wwp-prod -- "wp db query --path=$path 'SELECT (SELECT CASE WHEN EXISTS (SELECT post_title FROM wp_posts wp WHERE wp.ID=$formID AND post_content LIKE '\''%type\":\"file-upload%'\'')	THEN 'TRUE' ELSE 'FALSE' END) as hasUploadField FROM wp_posts wp WHERE wp.ID=$formID;' --skip-column-names;" 2>/dev/null)
    hasPayOnline=$(ssh -n wwp-prod -- "wp db query --path=$path 'SELECT (SELECT CASE WHEN EXISTS (SELECT post_content FROM wp_posts wp WHERE wp.ID=$formID AND post_content LIKE '\''%enable\":\"1%'\'')	THEN 'TRUE' ELSE 'FALSE' END) as hasPayOnline FROM wp_posts wp WHERE wp.ID=$formID;' --skip-column-names;" 2>/dev/null)
    postContentJSON=$(ssh -n wwp-prod -- "wp db query --path=$path 'SELECT post_content FROM wp_posts wp WHERE wp.ID=$formID;' --skip-column-names;" | ggrep -oP '(?<="id_inst":)"([^"]*)' 2>/dev/null)
    numberOfEntries=$(ssh -n wwp-prod -- "wp db query --path=$path 'SELECT COUNT(*) as numberOfEntries FROM wp_wpforms_entries WHERE form_id=$formID;' --skip-column-names;" 2>/dev/null)
    echo "$path|$formID|$postTitle|$hasUploadField|$hasPayOnline|$hasPayOnline|$postContentJSON|$numberOfEntries|" >> $DATA_CSV_FILE
  done
done < "$SITES_PATHS_FILE"