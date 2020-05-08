TARGET ?= aws
TERRAFORM ?= terraform
API_DIR ?= byob-api
SPA_DIR ?= byob-spa

all:
	@echo "Usage:\nmake okta\nor\nmake api\nornmake spa"

.PHONY: planOkta
planOkta: 
	@cd ${TERRAFORM} && \
	terraform init && \
	terraform plan -out=okta.setup.tfplan -lock=false

.PHONY: okta
okta: planOkta
	@cd ${TERRAFORM} && \
	terraform apply -auto-approve okta.setup.tfplan && \
	terraform output

.PHONY: destroyOktaPlan
destroyOktaPlan:
	@cd ${TERRAFORM} && \
	terraform init && \
	terraform plan -destroy -out=okta.delete.tfplan

.PHONY: destroyOkta
destroyOkta: destroyOktaPlan
	@cd ${TERRAFORM} && \
	terraform apply -auto-approve okta.delete.tfplan

.PHONY: setupApi
setupApi: 
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

.PHONY: setupSpa
setupSpa: 
	@cd ${SPA_DIR} && \
	npm install

.PHONY: spa
spa: setupSpa
	@cd ${SPA_DIR} && \
	serverless deploy -v
