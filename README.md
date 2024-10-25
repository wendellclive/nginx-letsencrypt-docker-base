# nginx-letsencrypt Docker Image

This repository contains a Docker image based on the official `nginx` image, configured to automatically obtain and renew SSL/TLS certificates using Certbot and Let's Encrypt. This image makes it easy to deploy a secure Nginx server with automated HTTPS management for your domain.

## Environment Variables
The image relies on the following environment variables for configuration:

- **`CERTBOT_EMAIL`**: The email address for Let’s Encrypt to send important notifications regarding the certificates. This email will also be used for expiration warnings and other important updates. Make sure to provide a valid email address.
- **`DOMAIN_NAME`**: The domain for which SSL/TLS certificates will be generated. This domain must point to the server where the container is running, as Let's Encrypt uses domain validation.

If `CERTBOT_EMAIL` is not set, the container will serve HTTP traffic on port 80.

## Configuration

Follow the guide of the [official Nginx docker image](https://hub.docker.com/_/nginx).

If you need to customize the nginx.conf file, overwrite `/etc/nginx/templates/default.conf.template` rather than `/etc/nginx/conf.d/default.conf`.

Certbot is able to modify simple nginx configurations to serve HTTPS instead of HTTP. For complex configurations you'll need to replace the configuration manually. The script `/etc/nginx/certbot-hook.sh` is run after a certificate is installed or renewed.

## Running the Container
You can run the container using the following command:

```sh
docker run -d \
  -e CERTBOT_EMAIL=your_email@example.com \
  -e DOMAIN_NAME=example.com \
  -p 80:80 -p 443:443 \
  jasny/nginx-letsencrypt
```

This command runs the container, exposing both HTTP (port 80) and HTTPS (port 443) for the server.

## SSL Certificate
The container will request an SSL certificate, a minute after it's started. This gives nginx enough time to boot. It's recommended that you have DNS properly set up before starting the container.

### Auto retry
If certbot is unable to get a certificate it will try again after 5 minutes. Each attempt it increases to wait time with 5 minutes up to 30 minutes between tries to prevent hitting the rate limit of letsencrypt.

### Automatic Certificate Renewal
Certificates are renewed every 12 hours using the `renew` command. If a new certificate is issued, Nginx will automatically use the new certificate without requiring a restart.

## Log Files
The Certbot script logs output to `/var/log/cron-certbot.log`. You can mount a volume to `/var/log` to access these logs from the host.

## Contributions
Feel free to [open issues](https://github.com/jasny/nginx-letsencrypt-docker/issues) or pull requests if you would like to contribute to this project.

## Author
- [Arnold Daniels](https://jasny.net)

