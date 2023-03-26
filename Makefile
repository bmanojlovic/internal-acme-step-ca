STEP_NS ?= step
STEP_URL ?= step-certificates.$(STEP_NS).svc.cluster.local
STEP_NAME ?= Smallstep
STEP_ADMIN ?= boris@steki.net
STEP_VERSION ?= 0.23.4
STEP_ARCHIVE := https://dl.step.sm/gh-release/cli/gh-release-header/v$(STEP_VERSION)/step_linux_$(STEP_VERSION)_amd64.tar.gz

all: step_bin step_password helm_values
	helm repo add smallstep  https://smallstep.github.io/helm-charts
	helm repo update
	@echo "############################################"
	@echo "#####    NOT RUNNING - do it yourself  #####" 
	@echo "############################################"
	@echo
	@echo "read HOWTO.txt... (a bit redudant :)"
	@echo
	@echo
	@echo
	@echo helm install --create-namespace --namespace $(STEP_NS) step-certificates smallstep/step-certificates \
		--values values.yaml \
		--set ca.db.storageClass="nfs-client" \
		--set inject.enabled='"true"' \
		--set inject.secrets.ca_password=`cat password.txt|base64 -w 0` \
		--set inject.secrets.provisioner_password=`cat password.txt|base64 -w 0` \
		--set 'inject.config.files.ca\\.json.authority.claims.maxTLSCertDuration="2160h"' \
		--set 'inject.config.files.ca\\.json.authority.claims.defaultTLSCertDuration="2160h"' \
		--set 'inject.config.files.ca\\.json.authority.claims.defaultTLSCertDuration="2160h"'
	@echo
	@echo
	@echo

checks:
	


step_bin:
	@test -f ~/bin/step || wget -O step_linux.tar.gz $(STEP_ARCHIVE) \
		&& tar zxf step_linux.tar.gz \
		&& mkdir -p ~/bin/ && cp step_*/bin/step ~/bin/

helm_values:
	test -f values.yaml || step ca init --helm \
		--name="$(STEP_NAME)" \
		--issuer='https://step-certificates.$(STEP_NS).svc.cluster.local' \
		--remote-management \
		--acme --provisioner=step-ca \
		--deployment-type=standalone \
		--dns='step-certificates.$(STEP_NS).svc.cluster.local' \
		--address=':9000' \
		--password-file password.txt \
		--provisioner '$(STEP_ADMIN)' \
		--provisioner-password-file password.txt | tee values.yaml


step_password:
	test -f password.txt ||  openssl rand -out password.txt -hex 50

clean: 
	rm -rf values.yaml password.txt step_* ~/bin/step *~
