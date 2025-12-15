#!/usr/bin/env bash
set -e
echo "Stopping any existing containers of this image..."
echo "Deploying Container..."
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml
