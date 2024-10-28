# Use Nginx to serve the frontend in the final stage
FROM nginx:stable-alpine

# Install certbot, cron, and at
RUN apk add --no-cache certbot certbot-nginx busybox-suid at

# Copy the custom nginx configuration file
COPY ./nginx.conf.template /etc/nginx/templates/default.conf.template

# Copy the entrypoint script and cron job
COPY ./entrypoint-certbot.sh /docker-entrypoint.d/50-certbot.sh
COPY ./cron-certbot.sh /usr/local/bin/cron-certbot.sh
COPY ./random-sleep.sh /usr/local/bin/random-sleep.sh
RUN touch /etc/nginx/certbot-hook.sh

# Ensure the entrypoint script and cron-certbot.sh are executable
RUN chmod +x /docker-entrypoint.d/50-certbot.sh /usr/local/bin/cron-certbot.sh /usr/local/bin/random-sleep.sh /etc/nginx/certbot-hook.sh

# Expose HTTP and HTTPS ports
EXPOSE 80
EXPOSE 443

