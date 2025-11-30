#!/bin/bash

set -e

echo "=== Applying Network Policies and Running Comprehensive Tests ==="

# Удаляем существующие политики
echo "Cleaning up existing network policies..."
kubectl delete networkpolicy --all 2>/dev/null || true

# Применяем сетевые политики
echo "Applying network policies..."

# non-admin-api-allow.yaml
kubectl apply -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: non-admin-api-allow
  namespace: default
spec:
  podSelector:
    matchLabels:
      role: back-end-api
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          role: front-end
    ports:
    - protocol: TCP
      port: 80
EOF

# admin-api-allow.yaml
kubectl apply -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: admin-api-allow
  namespace: default
spec:
  podSelector:
    matchLabels:
      role: admin-back-end-api
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          role: admin-front-end
    ports:
    - protocol: TCP
      port: 80
EOF

# front-end-egress.yaml
kubectl apply -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: front-end-egress
  namespace: default
spec:
  podSelector:
    matchLabels:
      role: front-end
  policyTypes:
  - Egress
  egress:
  - to:
    - podSelector:
        matchLabels:
          role: back-end-api
    ports:
    - protocol: TCP
      port: 80
EOF

# admin-front-end-egress.yaml
kubectl apply -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: admin-front-end-egress
  namespace: default
spec:
  podSelector:
    matchLabels:
      role: admin-front-end
  policyTypes:
  - Egress
  egress:
  - to:
    - podSelector:
        matchLabels:
          role: admin-back-end-api
    ports:
    - protocol: TCP
      port: 80
EOF

echo "Network policies applied:"
kubectl get networkpolicies

# Ждем немного для применения политик
sleep 10

echo ""
echo "=== Running Comprehensive Network Policy Tests ==="

# Функция для тестирования соединения
test_connection() {
    local source=$1
    local target=$2
    local expected=$3
    local description=$4
    
    echo -n "TEST: $description ... "
    
    if kubectl run test-$(date +%s) --rm -i --image=alpine/curl --restart=Never -- curl -s --connect-timeout 5 http://$target >/dev/null 2>&1; then
        if [ "$expected" == "ALLOW" ]; then
            echo "✓ PASS (Connection allowed as expected)"
            return 0
        else
            echo "✗ FAIL (Connection allowed but should be blocked)"
            return 1
        fi
    else
        if [ "$expected" == "BLOCK" ]; then
            echo "✓ PASS (Connection blocked as expected)"
            return 0
        else
            echo "✗ FAIL (Connection blocked but should be allowed)"
            return 1
        fi
    fi
}

# Функция для тестирования изнутри пода
test_from_pod() {
    local source_pod=$1
    local target_service=$2
    local expected=$3
    local description=$4
    
    echo -n "TEST: $description ... "
    
    if kubectl exec $source_pod -- curl -s --connect-timeout 5 http://$target_service >/dev/null 2>&1; then
        if [ "$expected" == "ALLOW" ]; then
            echo "✓ PASS (Connection allowed as expected)"
            return 0
        else
            echo "✗ FAIL (Connection allowed but should be blocked)"
            return 1
        fi
    else
        if [ "$expected" == "BLOCK" ]; then
            echo "✓ PASS (Connection blocked as expected)"
            return 0
        else
            echo "✗ FAIL (Connection blocked but should be allowed)"
            return 1
        fi
    fi
}

# Получаем имена подов
FRONT_POD=$(kubectl get pods -l role=front-end -o jsonpath='{.items[0].metadata.name}')
ADMIN_FRONT_POD=$(kubectl get pods -l role=admin-front-end -o jsonpath='{.items[0].metadata.name}')

echo ""
echo "--- Testing ALLOWED Connections ---"

# Разрешенные соединения
test_from_pod "$FRONT_POD" "back-end-api-app" "ALLOW" "front-end → back-end-api (should be ALLOWED)"
test_from_pod "$ADMIN_FRONT_POD" "admin-back-end-api-app" "ALLOW" "admin-front-end → admin-back-end-api (should be ALLOWED)"

echo ""
echo "--- Testing BLOCKED Connections ---"

# Заблокированные соединения (кросс-доступ)
test_from_pod "$FRONT_POD" "admin-back-end-api-app" "BLOCK" "front-end → admin-back-end-api (should be BLOCKED)"
test_from_pod "$ADMIN_FRONT_POD" "back-end-api-app" "BLOCK" "admin-front-end → back-end-api (should be BLOCKED)"

# Заблокированные соединения (внешний доступ)
test_connection "external" "back-end-api-app" "BLOCK" "external → back-end-api (should be BLOCKED)"
test_connection "external" "admin-back-end-api-app" "BLOCK" "external → admin-back-end-api (should be BLOCKED)"

echo ""
echo "--- Testing DNS Resolution ---"

# Проверка DNS
echo -n "TEST: DNS resolution for back-end-api-app ... "
if kubectl run dns-test-$(date +%s) --rm -i --image=busybox --restart=Never -- nslookup back-end-api-app >/dev/null 2>&1; then
    echo "✓ PASS"
else
    echo "✗ FAIL"
fi

echo ""
echo "=== Test Summary ==="
echo "Network Policies Applied:"
kubectl get networkpolicies -o custom-columns=NAME:.metadata.name,POD-SELECTOR:.spec.podSelector.matchLabels.role,INGRESS:.spec.ingress[0].from[0].podSelector.matchLabels.role

echo ""
echo "Current Pods and Services:"
kubectl get pods -o custom-columns=NAME:.metadata.name,ROLE:.metadata.labels.role,STATUS:.status.phase
kubectl get services -o custom-columns=NAME:.metadata.name,SELECTOR:.spec.selector.role

echo ""
echo "=== Network Policy Test Complete ==="