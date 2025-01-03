FROM alpine:latest

# Grab the dependencies for the project
RUN apk update && apk add --no-cache hugo git npm go

WORKDIR /root/setup

# Copy the script
COPY ./.src/redeploy.sh .

# Make the script executable
RUN chmod +x redeploy.sh

# Copy the update script
COPY ./.src/check-updates.sh .

# Make the update script executable
RUN chmod +x check-updates.sh

# Set the script as the entry point
ENTRYPOINT ["/bin/sh", "-c", "/root/setup/redeploy.sh & /root/setup/check-updates.sh"]

# Add these lines if they don't exist
ENV CHECK_INTERVAL="300"
ENV PORT="${PORT:-1313}"
ENV BRANCH="${BRANCH:-main}"
