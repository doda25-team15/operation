# Management and Troubleshooting

## Helm Management Commands

Upgrade:

```bash
helm upgrade sms-checker .
```

Rollback:

```bash
helm rollback sms-checker
```

Uninstall:

```bash
helm uninstall sms-checker
```

## Kubectl Management and Troubleshooting

Check all resources:

```bash
kubectl get all
```

Check pods:

```bash
kubectl get pods
```

Tail logs:

```bash
kubectl logs -l app=sms-checker
```

Verify ConfigMap is mounted:

```bash
kubectl exec deploy/app-deployment -- env | grep MODEL_HOST
```

Verify Ingress:

```bash
kubectl describe ingress
```

## Examples

### Customise Helm Deployment

Change number of replicas:

```
helm install sms-checker . --set replicaCount.app=5
```

Change Ingress hostname:

```
helm install sms-checker . --set ingress.host=myapp.local
```

Inject SMTP Credentials:

```
helm install sms-checker . \
  --set secret.smtpUser="abc@mail" \
  --set secret.smtpPass="secret"
```

Disable Ingress:

```
helm install sms-checker . --set ingress.enabled=false
```

**Verify changes:**

```
# Check replica count
kubectl get pods -l component=app
# Check hostname
kubectl get ingress app-ingress -o jsonpath='{.spec.rules[0].host}'
```
