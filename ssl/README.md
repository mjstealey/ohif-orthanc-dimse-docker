# SSL - certificates for development

A development SSL certificate pair is included in this repository.

- `ssl_dev.crt` - public certificate
- `ssl_dev.key` - private key

Since this certificate is not reckognized by any CA, do not use this for anything beyond local development (Never use in production)

The certificate pair was generated as follows:

```
openssl req -newkey rsa:4096 -days 3650 -nodes -x509 \
  -subj "/C=US/ST=North Carolina/L=Chapel Hill/O=Local/OU=Development/CN=local.dev/emailAddress=email@local.dev" \
  -keyout ssl_dev.key \
  -out ssl_dev.crt
```
