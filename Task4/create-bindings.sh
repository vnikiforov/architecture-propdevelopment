#!/bin/bash

# Привязка для администраторов БД
kubectl apply -f - <<EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: dba-admins-binding
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: dba-admins-role
subjects:
- kind: ServiceAccount
  name: dba-admin1
  namespace: default
EOF

# Привязка для администраторов доменов
kubectl apply -f - <<EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: domain-admins-binding
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: domain-admins-role
subjects:
- kind: ServiceAccount
  name: dom-admin1
  namespace: default
EOF

# Привязка для системных читателей
kubectl apply -f - <<EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: system-readers-binding
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: system-readers-role
subjects:
- kind: ServiceAccount
  name: sys-rdr1
  namespace: default
EOF

# Привязка для системных конфигураторов
kubectl apply -f - <<EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: system-configurators-binding
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: system-configurators-role
subjects:
- kind: ServiceAccount
  name: sys-cfgr1
  namespace: default
EOF

# Дополнительная привязка для кросс-функционального администратора
kubectl apply -f - <<EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: cross-functional-admin-binding
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cross-functional-admin-role
subjects:
- kind: ServiceAccount
  name: sys-cfgr1
  namespace: default
EOF

echo "Привязки ролей созданы успешно"