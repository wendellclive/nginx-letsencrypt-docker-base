#!/bin/sh

CURRENT_TTY=$(tty)

# Schedule Certbot script to run once shortly after the container starts
if [ -n "$CERTBOT_EMAIL" ]; then
  echo "Schedule certbot script to run in 1 minute"

  # Start the 'at' daemon in the background
  atd &

  # Schedule the certbot script to run in 1 minute using 'at'
  echo "/bin/sh /usr/local/bin/cron-certbot.sh > /var/log/cron-certbot.log 2>&1" | at now + 1 minute

  # Add a cron job to run the certbot script twice a day (every 12 hours) with the 'renew' argument
  echo "0 0,12 * * * bin/sh /usr/local/bin/random-sleep.sh 3600; /bin/sh /usr/local/bin/cron-certbot.sh renew > /var/log/cron-certbot.log 2>&1" > /etc/crontabs/root

  # Start the cron daemon in the background
  crond &
fi

