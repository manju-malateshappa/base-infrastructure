SHELL := /usr/bin/env bash

.PHONY: tf-plan
tf-plan: 
	cd terraform/${env} && \
	terraform init \
	-backend-config="bucket=${bucket}" \
	-backend-config="region=${region}" \
	-backend-config="key=${key}" \
	-backend-config="dynamodb_table=${table}" \
	-backend-config="encrypt=true" \
	-reconfigure && \
	terraform validate && \
	terraform plan \
	-var preprod_account_number=${preprod} \
	-var prod_account_number=${prod} \
	-var region=${region} \
	-var pat_github=${pat_github} \
	-var-file ../account_config/${env}/terraform.tfvars 
.PHONY: tf-apply
tf-apply:
	cd terraform/${env} && \
	terraform init \
	-backend-config="bucket=${bucket}" \
	-backend-config="region=${region}" \
	-backend-config="key=${key}" \
	-backend-config="dynamodb_table=${table}" \
	-backend-config="encrypt=true" \
	-reconfigure && \
	terraform validate && \
	terraform apply \
	-var preprod_account_number=${preprod} \
	-var prod_account_number=${prod} \
	-var region=${region} \
	-var pat_github=${pat_github} \
	-var-file ../account_config/${env}/terraform.tfvars -auto-approve
.PHONY: tf-destroy
tf-destroy:
	cd terraform/${env} && \
	terraform init \
	-backend-config="bucket=${bucket}" \
	-backend-config="region=${region}" \
	-backend-config="key=${key}" \
	-backend-config="dynamodb_table=${table}" \
	-backend-config="encrypt=true" \
	-reconfigure && \
	(terraform destroy \
	-var preprod_account_number=${preprod} \
	-var prod_account_number=${prod} \
	-var region=${region} \
	-var pat_github=${pat_github} \
	-var-file ../account_config/${env}/terraform.tfvars \
	-auto-approve || \
	(echo "Destroy failed, checking for locks..." && \
	LOCK_ID=$$(terraform plan -lock=false 2>&1 | grep "ID:" | awk '{print $$2}') && \
	if [ ! -z "$$LOCK_ID" ]; then \
		echo "Found lock with ID: $$LOCK_ID. Attempting to force-unlock..." && \
		terraform force-unlock -force "$$LOCK_ID" && \
		echo "Lock removed. Retrying destroy..." && \
		terraform destroy \
		-var preprod_account_number=${preprod} \
		-var prod_account_number=${prod} \
		-var region=${region} \
		-var pat_github=${pat_github} \
		-var-file ../account_config/${env}/terraform.tfvars \
		-auto-approve; \
	else \
		echo "Failed but couldn't identify lock ID"; \
		exit 1; \
	fi))

