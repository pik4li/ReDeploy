#!/bin/sh

# ───────────────────────────────────< ANSI color codes >───────────────────────────────────
RED='\033[0;31m'
CYAN='\033[0;36m'
YELLOW='\033[0;33m'
LIGHT_GREEN='\033[0;92m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Add timestamp to log messages with colored date
timestamp() {
  printf "${BOLD}${YELLOW}$(date +"%d-%m-%Y")${NC} ${RED}$(date +"%H:%M:%S")${NC}"
}

echo_error() {
  printf "$(timestamp) -- ${BOLD}${RED}ERROR: ${NC}${RED}%s${NC}\n" "$1" >&2
}

echo_info() {
  printf "$(timestamp) -- ${BOLD}${CYAN}INFO: ${NC}${CYAN}%s${NC}\n" "$1"
}

echo_warning() {
  printf "$(timestamp) -- ${BOLD}${YELLOW}WARNING: ${NC}${YELLOW}%s${NC}\n" "$1"
}

echo_note() {
  printf "$(timestamp) -- ${BOLD}${LIGHT_GREEN}NOTE: ${NC}${LIGHT_GREEN}%s${NC}\n" "$1"
}

# Load environment variables
while [ ! -f /root/setup/.env ]; do
  echo_warning "Waiting for .env file to be created..."
  sleep 5
done

. /root/setup/.env

# Function to check for updates and pull latest changes
check_for_updates() {
  echo_note "Checking for updates..."
  while true; do
    cd "${_TEMPDIR}/app" || { echo_error "Invalid path: ${_TEMPDIR}/app"; exit 1; }
    
    # Fetch the latest changes
    git fetch origin "$BRANCH" > /dev/null 2>&1
    
    # Check if there are new commits
    LOCAL=$(git rev-parse "$BRANCH")
    REMOTE=$(git rev-parse "origin/$BRANCH")
    
    if [ "$LOCAL" != "$REMOTE" ]; then
      echo_info "New updates found. Pulling changes..."
      git pull origin "$BRANCH" > /dev/null 2>&1
      echo_info "Restarting Hugo server..."
      pkill -f "hugo server"  # Kill the existing Hugo server
      /root/setup/hugo-website.sh & /root/setup/check-updates.sh # Restart the Hugo server and check for updates again
    fi
    
    sleep "$CHECK_INTERVAL"  # Wait for the specified interval before checking again
  done
}

check_for_updates 