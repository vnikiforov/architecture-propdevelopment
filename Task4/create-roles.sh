#!/bin/bash

# Роль для администраторов БД
kubectl apply -f - <<EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: dba-admins-role
rules:
- apiGroups: ["apps"]
  resources: ["statefulsets"]
  verbs: ["*"]
- apiGroups: [""]
  resources: ["persistentvolumeclaims", "configmaps", "secrets"]
  verbs: ["*"]
- apiGroups: [""]
  resources: ["pods", "services"]
  verbs: ["get", "list", "watch"]
- apiGroups: ["monitoring.coreos.com"]
  resources: ["servicemonitors"]
  verbs: ["*"]
EOF

# Роль для администраторов доменов
kubectl apply -f - <<EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: domain-admins-role
rules:
- apiGroups: ["networking.k8s.io"]
  resources: ["ingresses"]
  verbs: ["*"]
- apiGroups: [""]
  resources: ["services"]
  verbs: ["*"]
- apiGroups: ["networking.k8s.io"]
  resources: ["networkpolicies"]
  verbs: ["*"]
- apiGroups: ["externaldns.k8s.io"]
  resources: ["dnsendpoints"]
  verbs: ["*"]
EOF

# Роль для системных читателей
kubectl apply -f - <<EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: system-readers-role
rules:
- apiGroups: ["*"]
  resources: ["*"]
  verbs: ["get", "list", "watch"]
- nonResourceURLs: ["/metrics", "/healthz"]
  verbs: ["get"]
EOF

# Роль для системных конфигураторов
kubectl apply -f - <<EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: system-configurators-role
rules:
- apiGroups: [""]
  resources: ["nodes", "namespaces"]
  verbs: ["*"]
- apiGroups: ["storage.k8s.io"]
  resources: ["storageclasses"]
  verbs: ["*"]
- apiGroups: ["rbac.authorization.k8s.io"]
  resources: ["clusterroles", "clusterrolebindings"]
  verbs: ["*"]
EOF

# Роль для кросс-функциональных администраторов
kubectl apply -f - <<EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: cross-functional-admin-role
rules:
- apiGroups: ["apps"]
  resources: ["statefulsets"]
  verbs: ["*"]
- apiGroups: [""]
  resources: ["persistentvolumeclaims", "configmaps", "secrets"]
  verbs: ["*"]
- apiGroups: ["networking.k8s.io"]
  resources: ["ingresses"]
  verbs: ["*"]
- apiGroups: [""]
  resources: ["services"]
  verbs: ["*"]
EOF

echo "Роли созданы успешно"