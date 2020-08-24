#!/bin/bash

echo "Cluster Setup"

# minikube status -p pr93458
# minikube delete -p pr93458 
# sleep 10

minikube start -p pr93458 --kubernetes-version=v1.18.8 --nodes=3 --cpus=2 --memory=4096
minikube status -p pr93458

echo "Preload images for PR"

minikube -p pr93458 ssh -n pr93458 -- docker pull k8s.gcr.io/e2e-test-images/agnhost:2.20
minikube -p pr93458 ssh -n pr93458-m02 -- docker pull k8s.gcr.io/e2e-test-images/agnhost:2.20
minikube -p pr93458 ssh -n pr93458-m03 -- docker pull k8s.gcr.io/e2e-test-images/agnhost:2.20

minikube -p pr93458 ssh -n pr93458 -- docker pull httpd:2.4.38-alpine
minikube -p pr93458 ssh -n pr93458-m02 -- docker pull httpd:2.4.38-alpine
minikube -p pr93458 ssh -n pr93458-m03 -- docker pull httpd:2.4.38-alpine

echo "Stress testing PR93458..."
sleep 20
./runs.sh
