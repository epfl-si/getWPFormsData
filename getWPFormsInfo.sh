#!/bin/bash
# Usage: ./getWPFormsInfo.sh

# Default files names
SITES_URLS_FILE="${SITES_URLS_FILE:-sites_urls.txt}"
RED='\033[0;31m'   # Red
GREEN='\033[0;32m' # Green
NC='\033[0m'       # No Color

if [ ! -f "$SITES_URLS_FILE" ]; then
  echo "File $SITES_URLS_FILE not found. Please run ./getFormsData.sh"
  exit 1
fi

# Function that convert URL to site's path on the server
URLtoPath () {
  if [[ $1 =~ (www.epfl.ch/labs/) ]]; then
    lab_name=$(echo $1 | sed -n 's/https:\/\/www.epfl.ch\/labs\///gp' | tr -d '"')
    echo "/srv/labs/www.epfl.ch/htdocs/labs/${lab_name}"
  elif [[ $1 =~ (www.epfl.ch/research/) ]]; then
    research_name=$(echo $1 | sed -n 's/https:\/\/www.epfl.ch\/research\///gp' | tr -d '"')
    echo "/srv/www/www.epfl.ch/htdocs/research/${research_name}"
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

# Generate the $DATA_CSV_FILE CSV file based on each URL
while IFS= read -r url
do
  path=$(URLtoPath $url)
  echo "Running wp cli for $path ($url)"
  pluginsList="$(ssh -n wwp-prod -- "wp plugin list --format=json --path=$path" 2>/dev/null)"
  payonlineVersion="$(echo "$pluginsList" | jq -r '.[] | select (.name == "wpforms-epfl-payonline") | .version')"
  WPFormsVersion="$(echo "$pluginsList" | jq -r '.[] | select (.name == "wpforms") | .version')"

  pluginsPath="$path/wp-content/plugins"
  symlinkedWPForms=$(ssh -n wwp-prod -- "readlink $pluginsPath/wpforms")
  symlinkedPayonline=$(ssh -n wwp-prod -- "readlink $pluginsPath/wpforms-epfl-payonline")

  symlinkedWPFormsText="${RED}✗✗✗${NC}"
  if [ -z $symlinkedWPForms ]; then
    symlinkedWPFormsText="${GREEN}✔${NC} WPForms is NOT symlinked";
  else
    symlinkedWPFormsText="${RED}✗${NC} WPForms is symlinked";
  fi
  symlinkedPayonlineText="${RED}✗✗✗${NC}"
  if [ -z $symlinkedPayonline ]; then
    symlinkedPayonlineText="${RED}✗${NC} Payonline is NOT symlinked";
  else
    symlinkedPayonlineText="${GREEN}✔${NC} Payonline is symlinked";
  fi
  echo -e " ↳ $symlinkedWPFormsText ($WPFormsVersion) / $symlinkedPayonlineText ($payonlineVersion)"
done < $SITES_URLS_FILE 
