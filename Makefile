help: ## Prints help (only for targets with comments)
	@grep -E '^[a-zA-Z._-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

SHELL=bash -o pipefail

validate-packer: ## Validate packer files
	packer validate postgres.pkr.hcl
	packer validate frontend.pkr.hcl
	packer validate backend.pkr.hcl

validate-terraform: ## Validate tf files
	terraform -chdir=terraform validate

validate: validate-packer validate-terraform ## Validate all tf/pkr files

pack-postgres: ## Pack postgres image
	packer init postgres.pkr.hcl
	packer build postgres.pkr.hcl

pack-backend: ## Pack backend image
	packer init backend.pkr.hcl
	packer build backend.pkr.hcl

pack-frontend: ## Pack frontend image
	packer init frontend.pkr.hcl
	packer build frontend.pkr.hcl

pack: pack-backend pack-frontend pack-postgres ## Pack all the images

stack-setup: ## Setup Stack using terraform
	terraform -chdir=terraform init

stack-plan: ## Plan stack
	terraform -chdir=terraform plan

stack-apply: ## Apply stack
	terraform -chdir=terraform apply

stack-all: stack-setup stack-apply ## Create stack in one go (with approval step)

stack-all-auto-approve: stack-setup ## Create stack in one go
	terraform -chdir=terraform apply -auto-approve

fmt-checker: ## Check the fmt for all tf/pkr files
	packer fmt -recursive -diff -check .
	terraform fmt -recursive -diff -check .

push-checker: fmt-checker validate ## Run all checks locally
	$(info )
	$(info ************ Ready to push ************)

push: push-checker ## Run push-checher and push on success
	git push