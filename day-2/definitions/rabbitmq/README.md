# RabbitMQ App


Access to the server
````
kubectl exec -it -n rabbitmq rabbitmq-ha-cluster-server-0 -- /bin/bash
````

Access Management UI https://rabbitmq.ctapp.net
````
kubectl get secret -n rabbitmq rabbitmq-credentials-admin -o jsonpath="{.data.username}" | base64 --decode
echo ""
kubectl get secret -n rabbitmq rabbitmq-credentials-admin -o jsonpath="{.data.password}" | base64 --decode
````

### Create Admin User
````
export RABBITMQ_HOST=rabbitmq-ha-cluster.rabbitmq.svc
export RABBITMQ_PORT=5672
export RABBITMQ_PROVIDER=rabbitmq
export RABBITMQ_TYPE=rabbitmq
export RABBITMQ_USERNAME=admin
export RABBITMQ_PASSWORD=<Bitwarden "RabbitMQ CTApp - stage">
export RABBITMQ_CONF=<Bitwarden "RabbitMQ CTApp - stage">
kubectl create secret generic rabbitmq-credentials-admin --namespace rabbitmq --dry-run=client --from-literal=host=${RABBITMQ_HOST} --from-literal=port=${RABBITMQ_PORT} --from-literal=provider=${RABBITMQ_PROVIDER}  --from-literal=type=${RABBITMQ_TYPE}  --from-literal=username=${RABBITMQ_USERNAME}  --from-literal=password=${RABBITMQ_PASSWORD}  --from-literal=default_user.conf=${RABBITMQ_CONF} -o yaml | kubeseal --controller-name=sealed-secrets --controller-namespace=sealed-secrets --format yaml > /tmp/sealed-secret-rabbitmq.yaml

export RABBITMQ_ADMIN_HOST_ENCRYPTED=$(yq ".spec.encryptedData.host" /tmp/sealed-secret-rabbitmq.yaml)
export RABBITMQ_ADMIN_PORT_ENCRYPTED=$(yq ".spec.encryptedData.port" /tmp/sealed-secret-rabbitmq.yaml)
export RABBITMQ_ADMIN_PROVIDER_ENCRYPTED=$(yq ".spec.encryptedData.provider" /tmp/sealed-secret-rabbitmq.yaml)
export RABBITMQ_ADMIN_TYPE_ENCRYPTED=$(yq ".spec.encryptedData.type" /tmp/sealed-secret-rabbitmq.yaml)
export RABBITMQ_ADMIN_USERNAME_ENCRYPTED=$(yq ".spec.encryptedData.username" /tmp/sealed-secret-rabbitmq.yaml)
export RABBITMQ_ADMIN_PASSWORD_ENCRYPTED=$(yq ".spec.encryptedData.password" /tmp/sealed-secret-rabbitmq.yaml)
export RABBITMQ_ADMIN_CONF_ENCRYPTED=$(yq ".spec.encryptedData.\"default_user.conf\"" /tmp/sealed-secret-rabbitmq.yaml)

yq -i e ".sealedSecrets.admin.host |= \"${RABBITMQ_ADMIN_HOST_ENCRYPTED}\"" day-2/definitions/rabbitmq/values.yaml
yq -i e ".sealedSecrets.admin.port |= \"${RABBITMQ_ADMIN_PORT_ENCRYPTED}\"" day-2/definitions/rabbitmq/values.yaml
yq -i e ".sealedSecrets.admin.provider |= \"${RABBITMQ_ADMIN_PROVIDER_ENCRYPTED}\"" day-2/definitions/rabbitmq/values.yaml
yq -i e ".sealedSecrets.admin.type |= \"${RABBITMQ_ADMIN_TYPE_ENCRYPTED}\"" day-2/definitions/rabbitmq/values.yaml
yq -i e ".sealedSecrets.admin.username |= \"${RABBITMQ_ADMIN_USERNAME_ENCRYPTED}\"" day-2/definitions/rabbitmq/values.yaml
yq -i e ".sealedSecrets.admin.password |= \"${RABBITMQ_ADMIN_PASSWORD_ENCRYPTED}\"" day-2/definitions/rabbitmq/values.yaml
yq -i e ".sealedSecrets.admin.conf |= \"${RABBITMQ_ADMIN_CONF_ENCRYPTED}\"" day-2/definitions/rabbitmq/values.yaml
````

### Create CTApp User

````
export ENVIRONMENT_NAME=staging
export RABBITMQ_CTAPP_USERNAME=ctapp-${ENVIRONMENT_NAME}
export RABBITMQ_CTAPP_PASSWORD=$(pwgen -s 64 1)
export RABBITMQ_CTAPP_URL="amqp://${RABBITMQ_CTAPP_USERNAME}:${RABBITMQ_CTAPP_PASSWORD}@rabbitmq-ha-cluster.rabbitmq.svc/${RABBITMQ_CTAPP_USERNAME}"
kubectl create secret generic ctapp-rabbitmq-${ENVIRONMENT_NAME} --namespace rabbitmq --dry-run=client --from-literal=CELERY_BROKER_URL=${RABBITMQ_CTAPP_URL} --from-literal=username=${RABBITMQ_CTAPP_USERNAME} --from-literal=password=${RABBITMQ_CTAPP_PASSWORD} -o yaml | kubeseal --controller-name=sealed-secrets --controller-namespace=sealed-secrets --format yaml > /tmp/sealed-secret-rabbitmq.yaml
export RABBITMQ_CTAPP_USERNAME_ENCRYPTED=$(yq ".spec.encryptedData.username" /tmp/sealed-secret-rabbitmq.yaml)
export RABBITMQ_CTAPP_PASSWORD_ENCRYPTED=$(yq ".spec.encryptedData.password" /tmp/sealed-secret-rabbitmq.yaml)
export RABBITMQ_CTAPP_URL_ENCRYPTED=$(yq ".spec.encryptedData.CELERY_BROKER_URL" /tmp/sealed-secret-rabbitmq.yaml)
yq -i e ".sealedSecrets.ctapp-${ENVIRONMENT_NAME}.username |= \"${RABBITMQ_CTAPP_USERNAME_ENCRYPTED}\"" day-2/definitions/rabbitmq/values.yaml
yq -i e ".sealedSecrets.ctapp-${ENVIRONMENT_NAME}.password |= \"${RABBITMQ_CTAPP_PASSWORD_ENCRYPTED}\"" day-2/definitions/rabbitmq/values.yaml
yq -i e ".sealedSecrets.ctapp-${ENVIRONMENT_NAME}.url |= \"${RABBITMQ_CTAPP_URL_ENCRYPTED}\"" day-2/definitions/rabbitmq/values.yaml
````



Test sending messages

````
export ENVIRONMENT_NAME=staging
export RABBITMQ_HOST=rabbitmq-ha-cluster.rabbitmq.svc
export RABBITMQ_CTAPP_USERNAME=$(kubectl get secret -n ${ENVIRONMENT_NAME} ctapp-rabbitmq-${ENVIRONMENT_NAME} -o jsonpath="{.data.username}" | base64 --decode)
export RABBITMQ_CTAPP_PASSWORD=$(kubectl get secret -n ${ENVIRONMENT_NAME} ctapp-rabbitmq-${ENVIRONMENT_NAME} -o jsonpath="{.data.password}" | base64 --decode)
export RABBITMQ_CTAPP_URL="amqp://${RABBITMQ_CTAPP_USERNAME}:${RABBITMQ_CTAPP_PASSWORD}@${RABBITMQ_HOST}/${RABBITMQ_CTAPP_USERNAME}"

kubectl run perf-test -n ${ENVIRONMENT_NAME} --image=pivotalrabbitmq/perf-test -- --uri "${RABBITMQ_CTAPP_URL}"
kubectl logs -f -n ${ENVIRONMENT_NAME} perf-test
kubectl delete pod -n ${ENVIRONMENT_NAME} perf-test
````