FROM ghcr.io/home-assistant/amd64-base-python:3.11-alpine

# Install dependencies
RUN apk add --no-cache \
    git \
    nodejs \
    npm

# Copy app
WORKDIR /app
COPY . .

# Install Python dependencies
RUN pip3 install -r requirements.txt

# Make scripts executable
RUN chmod a+x *.sh

# Expose port for web UI
EXPOSE 8099

# Start
CMD [ "./run.sh" ]