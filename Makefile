TARGET ?= aws

all:
	@echo "Usage:\nmake upload\nor\nmake config"

.PHONY: checkUpload
checkUpload:
	@test -s ./Okta-Access-Gateway.ova || { echo "Okta-Access-Gateway.ova does not exist! Downloading..."; wget -O oag.ova https://download.oag.okta.com/ga/oag.ova; mv oag.ova Okta-Access-Gateway.ova;}

.PHONY: uploadCreate
uploadCreate: checkUpload
	@cd ${TARGET}/oag-upload && \
	terraform init && \
	terraform plan -out=oag.upload.create.tfplan -lock=false

.PHONY: upload
upload: uploadCreate
	@cd ${TARGET}/oag-upload && \
	terraform apply -auto-approve oag.upload.create.tfplan && \
	terraform output

.PHONY: uploadDelete
uploadDelete:
	@cd ${TARGET}/oag-upload && \
	terraform init && \
	terraform plan -destroy -out=oag.upload.delete.tfplan

.PHONY: removeUpload
removeUpload: uploadDelete
	@cd ${TARGET}/oag-upload && \
	terraform apply -auto-approve oag.upload.delete.tfplan

.PHONY: checkConfig
checkConfig:
	@test -s ~/.ssh/oagkey.pub || { echo "oagkey.pub does not exist! Creating..."; mkdir -p ~/.ssh; ssh-keygen -t rsa -N "" -f ~/.ssh/oagkey; }

.PHONY: configCreate
configCreate: checkConfig
	@cd ${TARGET}/oag-config && \
	terraform init && \
	terraform plan -out=oag.config.create.tfplan -lock=false


.PHONY: config
config: configCreate
	@cd ${TARGET}/oag-config && \
	terraform apply -auto-approve oag.config.create.tfplan && \
	terraform output

.PHONY: configDelete
configDelete:
	@cd ${TARGET}/oag-config && \
	terraform init && \
	terraform plan -destroy -out=oag.config.delete.tfplan

.PHONY: removeConfig
removeConfig: configDelete
	@cd ${TARGET}/oag-config && \
	terraform apply -auto-approve oag.config.delete.tfplan
	
.PHONY:test
test:
	@echo ${TARGET}
