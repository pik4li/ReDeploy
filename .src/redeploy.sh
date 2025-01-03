#!/bin/sh -e

#                                     ╭───────────────╮
#                                     │ env functions │
#                                     ╰───────────────╯
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

# ──────────────────────< Check if the given command exists silently >──────────────────────
command_exists() {
  command -v "$@" >/dev/null 2>&1
}

#                          ╭────────────────────────────────────╮
#                          │ insert your scripts/functions here │
#                          ╰────────────────────────────────────╯

_env() {
  if [ -z "$REPO" ]; then
    echo_error "Please provide a repository url > export REPO='repo/url' <script>"
    return 1
  fi
  # Set default branch if not specified, using POSIX compliant syntax
  : "${BRANCH:=main}"
  # Create a persistent temp directory
  _TEMPDIR="/root/setup/tempdir"
  mkdir -p "$_TEMPDIR"
}

# Get the IP address of the host
get_ip() {
  ip a | grep 'inet ' | grep -v '127.0.0.1' | awk '{print $2}' | cut -d/ -f1 | head -n 1
}

# Check for required dependencies
_deps() {
  dependencies="
  git
  hugo
  npm
  go
  "
  for _DEPS in $dependencies; do
    if ! command_exists "$_DEPS"; then
      echo_error "$_DEPS was not found! Please install to continue!"
      return 1
    fi
  done

  echo_info "Dependency check was successful."
}

# Clone the repository
_clone() {
  _env
  cd "$_TEMPDIR" || echo_error "$_TEMPDIR is not a valid directory!"

  # Check if app directory already exists
  if [ -d "app" ]; then
    echo_note "Repository already cloned in $_TEMPDIR/app"
    cd "${_TEMPDIR}/app" || echo_error "${_TEMPDIR}/app is not a valid path!"
    return 0
  fi

  # Clean up the REPO URL to prevent double https://
  CLEANED_REPO=$(echo "$REPO" | sed 's|^https://||')

  # Construct the clone URL based on whether GIT_TOKEN is provided
  if [ -n "$GIT_TOKEN" ]; then
    CLONE_URL="https://${GIT_TOKEN}@${CLEANED_REPO}"
  else
    CLONE_URL="https://${CLEANED_REPO}"
  fi

  # Clone specific branch
  git clone --depth=1 --recursive -b "$BRANCH" "$CLONE_URL" "app" &&
    echo_note "Cloned $CLONE_URL (branch: $BRANCH) to $_TEMPDIR/app"
  cd "${_TEMPDIR}/app" || echo_error "${_TEMPDIR}/app is not a valid path!"
  echo_info "Running go mod tidy..."
  go mod tidy || echo_error "Failed to run go mod tidy"
}

# Deploy the Hugo server
_deploy() {
  hugo server -D --noHTTPCache --disableFastRender --bind "$(get_ip)" || echo_error "Hugo couldn't deploy the site"
}

# Function to validate the URL
validate_url() {
  if [ -n "$URL" ]; then
    if ! echo "$URL" | grep -qE '^https?://'; then
      echo_error "Invalid URL: $URL. It must start with http:// or https://"
      exit 1
    fi
  fi
}


# Modify Hugo commands to bind to all interfaces and set baseURL
modify_hugo_command() {
  cmd="$1"
  # Check if it's a Hugo command and doesn't already have --bind
  if echo "$cmd" | grep -q "hugo server"; then
    if ! echo "$cmd" | grep -q -- "--bind"; then
      cmd="$cmd --bind $(get_ip)"
    fi
    if [ -n "$PORT" ]; then
      cmd="$cmd --port $PORT"
    fi
    # Add --baseURL if URL is set
    if [ -n "$URL" ]; then
      cmd="$cmd --baseURL $URL"
    fi
  fi
  echo "$cmd"
}

# Function to modify npm commands to bind to all interfaces
modify_npm_command() {
  cmd="$1"
  # Check if it's an npm command that needs host binding
  if echo "$cmd" | grep -q "npm run dev\|npm start"; then
    # Wrap the command with env to set the HOST variable
    cmd="$cmd -- --bind $(get_ip)"
  fi
  echo "$cmd"
}

# Execute build command if provided
execute_build_command() {
  if [ -n "$BUILD" ]; then
    echo_info "Executing build command: $BUILD"
    
    # Split multiple commands and process each one
    echo "$BUILD" | tr '&&' '\n' | while read -r cmd; do
      cmd=$(echo "$cmd" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
      
      echo_info "Running build step: $cmd"
      eval "${cmd}" || {
        echo_error "Failed to execute build step: |${cmd}|"
        exit 1
      }
    done
    echo_info "Build completed successfully"
  fi
}

# Execute custom commands
execute_custom_command() {
  # Execute build command first if it exists
  execute_build_command
  
  if [ -n "$COMMAND" ]; then
    echo_info "Executing custom command: $COMMAND"

    # Split multiple commands and process each one
    echo "$COMMAND" | tr '&&' '\n' | while read -r cmd; do
      cmd=$(echo "$cmd" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')

      # Modify command based on type
      if echo "$cmd" | grep -q "hugo"; then
        echo_info "Found hugo command"
        cmd=$(modify_hugo_command "$cmd")
      fi
      if echo "$cmd" | grep -q "npm"; then
        echo_info "Found npm command"
        cmd=$(modify_npm_command "$cmd")
      fi

      echo_info "Running: $cmd"
      eval "${cmd}" || {
        echo_error "Failed to execute: |${cmd}|"
        exit 1
      }
    done
  else
    echo_info "No custom command provided. Starting with the default hugo command..."
    COMMAND="hugo server -D --noHTTPCache --disableFastRender --bind $(get_ip)"
    execute_custom_command
  fi
  echo_info "Command to run: $COMMAND"
}

# Function to write environment variables to a .env file
write_env_file() {
  token=$GIT_TOKEN

  if [ -n "$GIT_TOKEN_FILE" ]; then
    echo_info "GIT_TOKEN_FILE variable found - token will be read from $GIT_TOKEN_FILE"
    if [ -e $GIT_TOKEN_FILE ]; then
      token=$(cat $GIT_TOKEN_FILE)
    else
      echo_error "Could not read from file"
    fi
  fi

_TEMPDIR=${_TEMPDIR}
GIT_TOKEN=${token}
REPO=${REPO}
BRANCH=${BRANCH:-main}
COMMAND=${COMMAND}
CHECK_INTERVAL=${CHECK_INTERVAL:-300}
EOF
  echo_info "Environment variables written to /root/setup/.env"
}

# Main function to execute
_main() {
  validate_url  # Validate the URL before proceeding
  if _deps; then
    sleep 1
    _clone
    sleep 1
    write_env_file # Write the environment variables to the .env file
    execute_custom_command || echo_error "Failed to execute custom command!"
  fi
}

# Handle script flag
_flag_script() {
  if [ -z "$2" ]; then
    echo_error "You did not provide a repository URL!"
    return 1
  fi
  REPO="$2"

  # Set branch from argument or default to main
  if [ -n "$3" ]; then
    BRANCH="$3"
  else
    BRANCH="main"
  fi

  # Handle custom command (now 4th argument)
  if [ -n "$4" ]; then
    echo_note "Custom command will be used"
    COMMAND="$4"
  else
    echo_info "Default command will be executed"
    # When using script flag, use localhost instead of get_ip for binding
    COMMAND="hugo server -D --noHTTPCache --disableFastRender --bind localhost"
  fi

  _main
}

# Main function to execute
main() {
  if [ "$1" = '--script' ]; then
    echo_note "--script was detected."
    echo_info "REPO: $2"
    if [ -n "$3" ]; then
      echo_info "BRANCH: $3"
    else
      echo_info "BRANCH: main (default)"
    fi
    _flag_script "$@"
  else
    _main
  fi
}

main "$@"
