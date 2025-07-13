@echo off
echo Generating SSL certificates for development...

REM Generate private key
openssl genrsa -out key.pem 2048

REM Generate certificate signing request
openssl req -new -key key.pem -out cert.csr -subj "/C=US/ST=State/L=City/O=Organization/CN=localhost"

REM Generate self-signed certificate
openssl x509 -req -days 365 -in cert.csr -signkey key.pem -out cert.pem

REM Clean up
del cert.csr

echo SSL certificates generated successfully!
echo cert.pem - Certificate file
echo key.pem - Private key file