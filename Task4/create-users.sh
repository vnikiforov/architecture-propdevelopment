#!/bin/bash

# Создание пользователей
kubectl create serviceaccount dba-admin1
kubectl create serviceaccount dom-admin1  
kubectl create serviceaccount sys-rdr1
kubectl create serviceaccount sys-cfgr1

# Создание групп через аннотации
kubectl annotate serviceaccount dba-admin1 rbac.groups/dba-admins=true
kubectl annotate serviceaccount dom-admin1 rbac.groups/domain-admins=true
kubectl annotate serviceaccount sys-rdr1 rbac.groups/system-readers=true
kubectl annotate serviceaccount sys-cfgr1 rbac.groups/dba-admins=true
kubectl annotate serviceaccount sys-cfgr1 rbac.groups/domain-admins=true

echo "Пользователи созданы успешно"