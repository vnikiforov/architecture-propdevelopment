#!/bin/bash

set -e

echo "=== Deploying 4-service system for network policy testing ==="

# Удаляем существующие ресурсы если есть
echo "Cleaning up existing resources..."
kubectl delete deployment,service,networkpolicy -l app=network-policy-test 2>/dev/null || true
kubectl delete pod,service,networkpolicy -l role 2>/dev/null || true

# Создаем Deployment'ы с метками
echo "Creating deployments..."
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: front-end-app
  labels:
    app: network-policy-test
spec:
  replicas: 1
  selector:
    matchLabels:
      app: front-end-app
      role: front-end
  template:
    metadata:
      labels:
        app: front-end-app
        role: front-end
    spec:
      containers:
      - name: nginx
        image: nginx:alpine
        ports:
        - containerPort: 80
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: back-end-api-app
  labels:
    app: network-policy-test
spec:
  replicas: 1
  selector:
    matchLabels:
      app: back-end-api-app
      role: back-end-api
  template:
    metadata:
      labels:
        app: back-end-api-app
        role: back-end-api
    spec:
      containers:
      - name: nginx
        image: nginx:alpine
        ports:
        - containerPort: 80
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: admin-front-end-app
  labels:
    app: network-policy-test
spec:
  replicas: 1
  selector:
    matchLabels:
      app: admin-front-end-app
      role: admin-front-end
  template:
    metadata:
      labels:
        app: admin-front-end-app
        role: admin-front-end
    spec:
      containers:
      - name: nginx
        image: nginx:alpine
        ports:
        - containerPort: 80
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: admin-back-end-api-app
  labels:
    app: network-policy-test
spec:
  replicas: 1
  selector:
    matchLabels:
      app: admin-back-end-api-app
      role: admin-back-end-api
  template:
    metadata:
      labels:
        app: admin-back-end-api-app
        role: admin-back-end-api
    spec:
      containers:
      - name: nginx
        image: nginx:alpine
        ports:
        - containerPort: 80
EOF

# Создаем сервисы
echo "Creating services..."
kubectl apply -f - <<EOF
apiVersion: v1
kind: Service
metadata:
  name: front-end-app
  labels:
    app: network-policy-test
spec:
  selector:
    app: front-end-app
  ports:
  - port: 80
    targetPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: back-end-api-app
  labels:
    app: network-policy-test
spec:
  selector:
    app: back-end-api-app
  ports:
  - port: 80
    targetPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: admin-front-end-app
  labels:
    app: network-policy-test
spec:
  selector:
    app: admin-front-end-app
  ports:
  - port: 80
    targetPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: admin-back-end-api-app
  labels:
    app: network-policy-test
spec:
  selector:
    app: admin-back-end-api-app
  ports:
  - port: 80
    targetPort: 80
EOF

# Ждем готовности подов
echo "Waiting for pods to be ready..."
kubectl wait --for=condition=ready pod -l role=front-end --timeout=60s
kubectl wait --for=condition=ready pod -l role=back-end-api --timeout=60s
kubectl wait --for=condition=ready pod -l role=admin-front-end --timeout=60s
kubectl wait --for=condition=ready pod -l role=admin-back-end-api --timeout=60s

# Базовая проверка связности
echo "Performing basic connectivity test..."
kubectl run basic-test --rm -i --image=alpine/curl --restart=Never -- curl -s --connect-timeout 5 http://back-end-api-app >/dev/null && echo "✓ Basic connectivity: OK" || echo "✗ Basic connectivity: FAILED"

echo "=== System deployed successfully ==="
echo "Pods:"
kubectl get pods -l app=network-policy-test -o wide
echo ""
echo "Services:"
kubectl get services -l app=network-policy-test