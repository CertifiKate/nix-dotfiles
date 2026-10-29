_: plan

# Incus S3 bucket holding terraform state
# Buckets on a local pool only exist on one member, so talk to that member directly rather than the cluster VIP
s3_host ?= incus-03.srv
pool    ?= host-pool-01
bucket  ?= terraform
key     ?= terraform.tfstate
s3_creds = incus storage bucket key show cluster:$(pool) $(bucket) $(key)

init: backend-config
	terraform init -backend-config="backend.tfvars"

backend-config:
	@creds=$$($(s3_creds)) && \
	printf 'endpoints  = { s3 = "https://%s:8334" }\naccess_key = "%s"\nsecret_key = "%s"\n' "$(s3_host)" \
		"$$(echo "$$creds" | awk '/^access-key:/{print $$2}')" \
		"$$(echo "$$creds" | awk '/^secret-key:/{print $$2}')" > backend.tfvars && \
	echo "Wrote backend.tfvars (https://$(s3_host):8334)"

plan:
	terraform plan -var-file="instances.tfvars"

validate:
	terraform validate

provision:
	terraform apply -var-file="instances.tfvars"
	$(MAKE) state-backup

# Local copy of the remote state in case the host or the bucket is unavailable
state-backup:
	terraform state pull > terraform.tfstate.remote-backup.tmp && \
	mv terraform.tfstate.remote-backup.tmp terraform.tfstate.remote-backup && \
	echo "Saved terraform.tfstate.remote-backup"

# Set up an alias for the S3 bucket dynamically
mc-setup:
	@creds=$$($(s3_creds)) && \
	mc alias set incus "https://$(s3_host):8334" \
		"$$(echo "$$creds" | awk '/^access-key:/{print $$2}')" \
		"$$(echo "$$creds" | awk '/^secret-key:/{print $$2}')" --insecure