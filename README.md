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

1. Create a `docker-compose.yml` file:

```yaml
services:
  redeploy:
    image: ghcr.io/pik4li/redeploy:latest
    ports:
      - "1313:1313"
    env_file:
      - .env
```

2. Create/Edit the `.env` file (**[available variables](#environment-variables)**):

```bash
# required
REPO=https://github.com/your/hugo/repo # leading https:// is not required!
PROTOCOL=https # or http

# optional
BRANCH=main # Optional: for branch selection
GIT_TOKEN="your_github_token" # Optional: for private repositories
COMMAND="npm install && npm run dev" # Optional: custom build command
CHECK_INTERVAL=300 # Optional: interval in seconds to check for updates
```

3. Run the container:

```bash
docker compose up
```

4. Access the site at `http://localhost:1313` or `http://localhost:8080` (if you have a different port)

5. If you have a reverseproxy already running, you can point it to the container's port to have a local cloudflare pages like experience with automatic redeployment.


## Environment Variables

| Variable       | Required | Description                                   | Example                        | Default value                                    |
| -------------- | -------- | --------------------------------------------- | ------------------------------ | ------------------------------------------------ |
| REPO           | Yes      | URL of the Git repository                     | `https://github.com/user/repo` | -                                                |
| BRANCH         | No       | The branch to use for cloning the site        | `main`                         | main                                             |
| PROTOCOL         | No       | Specify if using plain http        | `http`                         | https                                             |
| GIT_TOKEN      | No       | Authentication token for private repositories | `ghp_xxxxxxxxxxxx`             | -                                                |
| GIT_TOKEN_FILE | No       | File to read GIT_TOKEN from                   | `/run/secrets/github_token`    | -                                                |
| COMMAND        | No       | Custom build/run command                      | `npm install && npm run dev`   | `hugo server -D --noHTTPCache --disableFastRender` |
| CHECK_INTERVAL | No       | Interval in seconds to check for updates      | `300`                          | 300                                              |

## Custom Commands

The application supports various custom commands that will automatically be configured for proper network binding:

### Command Examples

- `npm install && npm run dev`
- `hugo server -D`
- `hugo server`
- `hugo server -D`

## Docker Compose Examples

### Basic Example with .env file

```yaml
services:
  redeploy:
    image: ghcr.io/pik4li/redeploy:latest
    ports:
      - "1313:1313"
    env_file:
      - .env
```

> [!IMPORTANT]
> The `.env` file is required for the container to work.
> You can find the proper variables in the [Environment Variables](#environment-variables) section.

---

### Example without .env file

```yaml
services:
  redeploy:
    image: ghcr.io/pik4li/redeploy:latest
    ports:
      - "1313:1313"
    environment:
      - REPO="https://github.com/your/hugo/repo"
      - GIT_TOKEN="your_github_token"
      - COMMAND="npm install && npm run dev"
      - CHECK_INTERVAL="10"
```
