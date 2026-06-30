_: plan

init:
	terraform init -backend-config="backend.tfvars"

plan:
	terraform plan -var-file="instances.tfvars"

validate:
	terraform validate

provision:
	terraform apply -var-file="instances.tfvars"