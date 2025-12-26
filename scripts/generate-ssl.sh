#!/bin/bash
# SSL Certificate Generation for PostgreSQL

set -e

SSL_DIR="./postgres/ssl"
mkdir -p "$SSL_DIR"

echo "Generating Root CA..."
openssl req -new -x509 -days 3650 -nodes -text -out "$SSL_DIR/root.crt" \
  -keyout "$SSL_DIR/root.key" -subj "/CN=PostgreSQL-CA"

echo "Generating Server Certificate..."
openssl req -new -nodes -text -out "$SSL_DIR/server.csr" \
  -keyout "$SSL_DIR/server.key" -subj "/CN=postgres"

openssl x509 -req -in "$SSL_DIR/server.csr" -text -days 3650 \
  -CA "$SSL_DIR/root.crt" -CAkey "$SSL_DIR/root.key" -CAcreateserial \
  -out "$SSL_DIR/server.crt"

echo "Setting permissions..."
# PostgreSQL requires specific permissions for the private key
chmod 600 "$SSL_DIR/server.key"
chmod 644 "$SSL_DIR/server.crt" "$SSL_DIR/root.crt"

# Clean up
rm "$SSL_DIR/server.csr"

echo "SSL certificates generated successfully in $SSL_DIR"
