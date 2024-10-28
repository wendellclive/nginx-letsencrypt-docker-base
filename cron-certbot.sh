#!/bin/sh

if [ -z "$CERTBOT_EMAIL" ]; then
  echo "CERTBOT_EMAIL not defined. Exiting."
  exit 0
fi

if [ -z "$DOMAIN_NAME" ]; then
  echo "DOMAIN_NAME environment variable not set" >&2
  exit 1
fi

PIDFILE="/var/run/cron-certbot.pid"

# Check if the PID file exists and if the process is still running
if [ -f "$PIDFILE" ] && kill -0 "$(cat "$PIDFILE")" 2>/dev/null; then
  echo "Script is already running with PID $(cat "$PIDFILE"). Exiting."
  exit 1
fi

# Create or update the PID file with the current process ID
echo $$ > "$PIDFILE"

# Ensure the PID file is removed when the script exits
trap "rm -f '$PIDFILE'" EXIT

# Initialize the sleep interval
SLEEP_INTERVAL=5

# Determine if we need to add 'certonly' for dry run
if ! echo "$@" | grep -qE 'certonly|renew'; then
  DRYRUN_ARGS="certonly"
fi

# If we're not renewing the certificate reinstall nginx
if ( ! echo "$@" | grep -q 'renew' ) && test -e /etc/letsencrypt/live/"$DOMAIN_NAME"; then
  certbot install --nginx --cert-name "$DOMAIN_NAME" -n
fi

while :; do
  echo "Running certbot with --dry-run to simulate the certificate issuance..."
  certbot --nginx -d "$DOMAIN_NAME" --email "$CERTBOT_EMAIL" --agree-tos --non-interactive --keep-until-expiring $DRYRUN_ARGS "$@" --dry-run
  DRYRUN_EXIT_CODE=$?

  if [ $DRYRUN_EXIT_CODE -eq 0 ]; then
    echo "Dry run succeeded. Proceeding with actual certificate issuance..."
    certbot --nginx -d "$DOMAIN_NAME" --email "$CERTBOT_EMAIL" --agree-tos --non-interactive --keep-until-expiring "$@"
    ACTUAL_EXIT_CODE=$?

    if [ $ACTUAL_EXIT_CODE -eq 0 ]; then
      echo "Certificate issued successfully."
      
      # Run the hook script
      if /etc/nginx/certbot-hook.sh; then
        echo "Hook ran successfully."
      else
        echo "Hook script failed. Exiting."
        exit 1
      fi
      
      exit 0	
    else
      echo "Certbot failed on actual certificate issuance. Retrying in $SLEEP_INTERVAL minutes."
    fi
  else
    echo "Certbot dry run failed. Retrying in $SLEEP_INTERVAL minutes."
  fi

  sleep ${SLEEP_INTERVAL}m &
  wait $!

  # Increase the sleep interval with a max of 30 minutes
  if [ $SLEEP_INTERVAL -lt 30 ]; then
    SLEEP_INTERVAL=$((SLEEP_INTERVAL + 5))
  fi
done

