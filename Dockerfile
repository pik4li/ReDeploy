FROM alpine:latest

# Grab the dependencies for the project
RUN apk update && apk upgrade && apk add hugo git curl npm go

WORKDIR /root/setup

# Copy the script
COPY ./.src/hugo-website.sh .

# Make the script executable
RUN chmod +x hugo-website.sh

# Copy the update script
COPY ./.src/check-updates.sh .

# Make the update script executable
RUN chmod +x check-updates.sh

# Set the script as the entry point
# ENTRYPOINT ["/bin/sh", "-c", "/root/setup/hugo-website.sh --script \"$REPO\" \"$BRANCH\" \"$COMMAND\" & /root/setup/check-updates.sh"]
ENTRYPOINT ["/bin/sh", "-c", "/root/setup/hugo-website.sh & /root/setup/check-updates.sh"]

# Add these lines if they don't exist
ENV GIT_TOKEN=""
ENV REPO=""
ENV BRANCH="main"
ENV COMMAND=""
ENV CHECK_INTERVAL="300"
