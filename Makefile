TARGET ?= aws
TERRAFORM ?= terraform
API_DIR ?= byob-api
SPA_DIR ?= byob-spa

help:
	@echo "Usage:\n\tmake okta\n\tmake api\n\tmake spa"
	@echo "\tmake all"

TERRAFORM_VERSION := $(shell terraform --version 2>/dev/null)
SERVERLESS_VERSION := $(shell serverless -v 2>/dev/null)
AWSCLI_VERSION := $(shell aws --version 2>/dev/null)
VUECLI_VERSION := $(shell vue --version 2>/dev/null)

check:
ifdef TERRAFORM_VERSION
	@echo "Found $(TERRAFORM_VERSION)"
else
	@echo "`terraform` not found. Please see: https://docs.idp.rocks/setup/#install-terraform for details."
endif
ifdef SERVERLESS_VERSION
	@echo "Found Serverless: $(SERVERLESS_VERSION)"
else
	@echo "`serverless` not found. Please see: https://docs.idp.rocks/setup/#install-serverless for details."
endif
ifdef AWSCLI_VERSION
	@echo "Found $(AWSCLI_VERSION)"
else
	@echo "`aws` not found. Please see: https://docs.idp.rocks/setup/#install-aws-cli for details. "
endif
ifdef VUECLI_VERSION
	@echo "Found $(VUECLI_VERSION)"
else
	@echo "`vue` CLI not found. Please see: https://docs.idp.rocks/setup/#install-vue-cli for details. "
endif

TERRAFORM-exists: ; @which terraform > /dev/null
AWSCLI-exists: ; @which aws > /dev/null
SERVERLESS-exists: ; @which serverless > /dev/null

.DEFAULT_GOAL := all
all: check okta api spa

removeAll: check removeSpa removeApi destroyOkta

.PHONY: planOkta
planOkta: 
	@cd ${TERRAFORM} && \
	terraform init && \
	terraform plan -out=okta.setup.tfplan -lock=false

.PHONY: okta
okta: planOkta
	@cd ${TERRAFORM} && \
	terraform apply -auto-approve okta.setup.tfplan

.PHONY: destroyOktaPlan
destroyOktaPlan:
	@cd ${TERRAFORM} && \
	terraform init && \
	terraform plan -destroy -out=okta.delete.tfplan

.PHONY: destroyOkta
destroyOkta: destroyOktaPlan
	@cd ${TERRAFORM} && \
	terraform apply -auto-approve okta.delete.tfplan

.PHONY: createEnvJson
createEnvJson:
	@cd ${TERRAFORM} && \
  terraform output api_env_json | sed -e 's/<<EOT/{/g' | sed -e 's/EOT/}/g' > ../${API_DIR}/.env.json

.PHONY: setupApi
setupApi: createEnvJson
	@cd ${API_DIR} && \
	npm install

.PHONY: api
api: setupApi
	@cd ${API_DIR} && \
	serverless deploy -v

.PHONY: removeApi
removeApi: 
	@cd ${API_DIR} && \
	serverless remove -v

.PHONY: createEnvLocal
createEnvLocal: 
	@cd ${TERRAFORM} && \
	terraform output vue_env_dev > ../${SPA_DIR}/.env.development.local

.PHONY: createVueEnv
createVueEnv: createEnvLocal
	@cd ${API_DIR} && \
	printf %s "VUE_APP_API=" >> ../${SPA_DIR}/.env.development.local && \
	serverless info --verbose | grep ServiceEndpoint | grep -o 'http.*' >> ../${SPA_DIR}/.env.development.local

.PHONY: setupSpa
setupSpa: createVueEnv
	@cd ${SPA_DIR} && \
	npm install

.PHONY: spa
spa: setupSpa
	@echo "Run 'npm run serve' to run Single Page App locally. " && \
	echo "\tThen go to http://localhost:8081/ in your browser."

# ========================================================================
# TODO: Make deploy SPA. 
# ========================================================================
#   Experimental - for CloudFront, S3, Route53 setup in AWS for the SPA
#	@cd ${SPA_DIR} && \
#	serverless deploy -v

.PHONY: removeSpa
removeSpa: 
	@cd ${SPA_DIR} && \
	serverless remove -v && \
	rm -rf node_modules dist


.PHONY: byobOkta
byobOkta: okta
	@echo "1. Terraform Okta Complete"
	@echo "2. Env variables for API written to AWS Systems Manager"

.PHONY: byobApi
byobApi: byobOkta
	@echo "Now Deploying Serverless..."

.PHONY: all
all: byobApi
	@echo "Make complete."

