# A phony target is one that is not really the name of a file
.PHONY: createfs createrole ping setup-all setup-services-reset setup-services
# targets with arguments
ARGTARGETS := createrole
USEVAULT=0

# If the first argument is a target with arguments
ifneq ($(filter $(firstword $(MAKECMDGOALS)),$(ARGTARGETS)),)
  # use the rest as arguments
  RUN_ARGS := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
  # ...and turn them into do-nothing targets
  $(eval $(RUN_ARGS):;@:)
endif

ANSIBLE_EXTRA_ARGS ?=
ifeq ($(USEVAULT),1)
ANSIBLE_EXTRA_ARGS += --ask-vault-pass
endif

setup-all:
	ansible-playbook $(ANSIBLE_EXTRA_ARGS) -i hosts playbook.yml

setup-services-reset:
	ansible-playbook $(ANSIBLE_EXTRA_ARGS) -i hosts playbook.yml --start-at-task='Install python3-jsondiff'

setup-services:
	ansible-playbook $(ANSIBLE_EXTRA_ARGS) -i hosts playbook.yml --start-at-task='Create data directories'

createfs:
	test -d group_vars || mkdir group_vars
	test -d host_vars || mkdir host_vars
	test -d roles || mkdir roles
	touch requirements.txt
	touch requirements.yml
	touch playbook.yml
	touch hosts

createrole:
ifndef RUN_ARGS
	$(error Specify the role name)
endif
	ansible-galaxy role init roles/$(RUN_ARGS)

requirements:
	ansible-galaxy collection install -r requirements.yml 

ping:
	ansible -i hosts -m ping all
