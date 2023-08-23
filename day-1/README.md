### Terraform

Basic Terraform commands

```
export $(grep -v '^#' .env | xargs)
export $(grep -v '^#' .envrc | xargs)
cd day-1
terraform init -backend-config="bucket=ct-platform-terraform"
terraform plan -out=tfplan
terraform apply tfplan

terraform output -json postgres_ca_cert | jq -r '.[0]' > postgres-staging-ca.pem
terraform output -json postgres_client_cert | jq -r '.[]' > postgres-staging-client-cert.pem
terraform output -json postgres_client_cert_key | jq -r '.[]' > postgres-staging-client-key.pem
chmod 400 postgres-*.pem

terraform output -json postgres_password_postgres | jq -r '.[0]' | jq -r '.staging'
terraform output -json postgres_password_ctdapp | jq -r '.[0]' | jq -r '.staging'
```