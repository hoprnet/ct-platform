### Terraform

Basic Terraform commands

```
export $(grep -v '^#' .env | xargs)
export $(grep -v '^#' .envrc | xargs)
cd day-0
terraform init -backend-config="bucket=ct-platform-terraform"
terraform plan -out=tfplan
terraform apply tfplan

terraform output -json postgres_staging_ca_cert > postgres-staging-ca.pem
terraform output -raw postgres_staging_client_cert > postgres-staging-client-cert.pem
terraform output -raw postgres_staging_client_cert_key > postgres-staging-client-key.pem
chmod 400 postgres-*.pem
```