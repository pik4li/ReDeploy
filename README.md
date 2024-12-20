# ReDeploy Docker Application

A lightweight, self-hosted Docker tool to deploy Git-hosted sites locally. Clone, build, and deploy Hugo, Go, or Node.js sites with custom commands, branch selection, and private repo access. Detect changes and auto-redeploy — a flexible alternative to SaaS tools like Cloudflare Pages or GitHub Pages.

## Features

- 🚀 Easy deployment of Hugo sites in Docker containers
- 🔒 Support for both public and private Git repositories
- 🛠 Custom build commands (npm, Hugo, etc.)
- 🌐 Automatic network binding for container access
- 🔄 Flexible command execution with proper error handling
- 🔄 Automatic pulling of the latest changes from the repository

## Prerequisites

- Docker
- Docker Compose
- Git (for building from source)

## Quick Start

### Using Docker Compose

1. Clone the repository:

```bash
git clone https://github.com/pik4li/redeploy
```

2. Create/Edit the `.env` file (**[available variables](README.md#environment-variables)**):

```bash
# required
REPO=https://github.com/your/hugo/repo # leading https:// is not required!

# optional
BRANCH=main # Optional: for branch selection
GIT_TOKEN=your_github_token # Optional: for private repositories
COMMAND=npm install && npm run dev # Optional: custom build command
CHECK_INTERVAL=300 # Optional: interval in seconds to check for updates
```

3. Run the container:

```bash
docker compose up
```

4. Access the site at `http://localhost:1313` or `http://localhost:8080` (if you have a different port)

5. If you have a reverseproxy already running, you can point it to the container's port to have a local cloudflare pages like experience with automatic redeployment.

### Using the Script Directly

```bash
# script variables
./redeploy.sh --script <REPO> <BRANCH> <COMMAND>

# Basic usage with public repository
./redeploy.sh --script "https://github.com/your/hugo/repo"

# With custom build command
./redeploy.sh --script "https://github.com/your/hugo/repo" "main" "npm install && npm run dev"

# With private repository (using GIT_TOKEN)
GIT_TOKEN=your_token ./hugo-website.sh --script "https://github.com/your/hugo/repo"
```

## Environment Variables

| Variable       | Required | Description                                   | Example                        | Default value                                    |
| -------------- | -------- | --------------------------------------------- | ------------------------------ | ------------------------------------------------ |
| REPO           | Yes      | URL of the Git repository                     | `https://github.com/user/repo` | -                                                |
| BRANCH         | No       | The branch to use for cloning the site        | `main`                         | main                                             |
| GIT_TOKEN      | No       | Authentication token for private repositories | `ghp_xxxxxxxxxxxx`             | -                                                |
| COMMAND        | No       | Custom build/run command                      | `npm install && npm run dev`   | hugo server -D --noHTTPCache --disableFastRender |
| CHECK_INTERVAL | No       | Interval in seconds to check for updates      | `300`                          | 300                                              |

## Custom Commands

The application supports various custom commands that will automatically be configured for proper network binding:

### Command Examples

- `npm install && npm run dev`
- `hugo server -D`
- `hugo server`
- `hugo server -D`

## Docker Compose Example without .env file

```yaml
services:
  redeploy:
    build:
      dockerfile: ./Dockerfile
    ports:
      - "1313:1313" # Map container port 1313 to host port 8080
    environment:
      - REPO=${REPO}
      - GIT_TOKEN=${GIT_TOKEN}
      - COMMAND=${COMMAND}
      - CHECK_INTERVAL=${CHECK_INTERVAL}
```

## Docker Compose Example with .env file

```yaml
services:
  redeploy:
    build:
      dockerfile: ./Dockerfile
    ports:
      - "1313:1313" # Map container port 1313 to host port 8080
    env_file:
      - .env
```

## Building from Source

1. Clone this repository:

```bash
git clone
```

2. Build the Docker image:

```bash
make build
```

3. Edit the `.env` file:

```bash
nvim .env
```

4. Run the Docker container:

```bash
docker compose up -d
```
