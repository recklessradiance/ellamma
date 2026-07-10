#!/bin/bash
# Deployment script for iPhone 4S

IP=$1
PORT=${2:-22}
USER="root"

if [ -z "$IP" ]; then
    echo "Usage: ./deploy.sh <iphone-ip-address> [ssh-port]"
    echo "Example: ./deploy.sh 192.168.1.100"
    exit 1
fi

echo "=== Deploying to iPhone 4S ($IP:$PORT) ==="

# Create directory on phone
echo "Creating directory /var/root/tinystories on the phone..."
ssh -p "$PORT" "$USER@$IP" "mkdir -p /var/root/tinystories"

# Transfer Hello World
if [ -f "deploy/hello" ]; then
    echo "Copying hello world test binary..."
    scp -P "$PORT" deploy/hello "$USER@$IP:/var/root/tinystories/hello"
    ssh -p "$PORT" "$USER@$IP" "chmod +x /var/root/tinystories/hello"
fi

# Transfer TinyStories binary
if [ -f "deploy/tinystories" ]; then
    echo "Copying TinyStories binary..."
    scp -P "$PORT" deploy/tinystories "$USER@$IP:/var/root/tinystories/tinystories"
    ssh -p "$PORT" "$USER@$IP" "chmod +x /var/root/tinystories/tinystories"
fi

# Transfer Model weights and tokenizer
if [ -f "models/stories15M.bin" ]; then
    echo "Copying TinyStories 15M model weights..."
    scp -P "$PORT" models/stories15M.bin "$USER@$IP:/var/root/tinystories/model.bin"
fi

if [ -f "models/tokenizer.bin" ]; then
    echo "Copying tokenizer..."
    scp -P "$PORT" models/tokenizer.bin "$USER@$IP:/var/root/tinystories/tokenizer.bin"
fi

echo "=== Deployment Complete! ==="
echo "You can now SSH into your iPhone and run:"
echo "  ssh root@$IP"
echo "  cd /var/root/tinystories"
echo "  ./hello"
echo "  ./tinystories model.bin -z tokenizer.bin -i \"Once upon a time\""
