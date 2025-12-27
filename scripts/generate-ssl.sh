#!/bin/bash
# SSL Certificate Generation for PostgreSQL

set -e

SSL_DIR="./postgres/ssl"
mkdir -p "$SSL_DIR"

echo "Generating Root CA..."
openssl req -new -x509 -days 3650 -nodes -text -out "$SSL_DIR/root.crt" \
  -keyout "$SSL_DIR/root.key" -subj "/CN=PostgreSQL-CA"

echo "Generating Server Certificate with X.509 v3 extensions..."
# Create temporary config for v3 extensions
cat > "$SSL_DIR/server.ext" << EOF
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
subjectAltName = @alt_names

[alt_names]
DNS.1 = postgres
DNS.2 = localhost
IP.1 = 127.0.0.1
EOF

openssl req -new -nodes -out "$SSL_DIR/server.csr" \
  -keyout "$SSL_DIR/server.key" -subj "/CN=postgres"

openssl x509 -req -in "$SSL_DIR/server.csr" -days 3650 \
  -CA "$SSL_DIR/root.crt" -CAkey "$SSL_DIR/root.key" -CAcreateserial \
  -extfile "$SSL_DIR/server.ext" \
  -out "$SSL_DIR/server.crt"

echo "Setting permissions..."
# PostgreSQL requires specific permissions for the private key
# The key must be owned by the database user (UID 999 in official image) or root
# and have 600 permissions.
# We use docker to set ownership to avoid sudo prompts in some environments.
docker run --rm -v "$(pwd)/$SSL_DIR:/ssl" alpine sh -c "chown 999:999 /ssl/server.key /ssl/root.key && chmod 600 /ssl/server.key /ssl/root.key"
chmod 644 "$SSL_DIR/server.crt" "$SSL_DIR/root.crt"

# Clean up
rm "$SSL_DIR/server.csr" "$SSL_DIR/server.ext"

echo "SSL certificates generated successfully in $SSL_DIR"
