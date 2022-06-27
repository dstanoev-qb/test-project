# Change this to bump up the version of pre-commit
PRE_COMMIT_VERSION = 2.17.0
PYTHON_VERSION = 3.9.10
PROJECT_VENV = venv1

# Those are generated based on the PRE_COMMIT_VERSION, so you don't need to touch them
PRE_COMMIT_LINK = https://github.com/pre-commit/pre-commit/releases/download/v$(PRE_COMMIT_VERSION)/pre-commit-$(PRE_COMMIT_VERSION).pyz
PRE_COMMIT = pre-commit-$(PRE_COMMIT_VERSION).pyz

# Deployment procedure variables
GCLOUD_RUNTIME = python39
PROJECT_NUMBER = $(shell gcloud projects describe $(APPLICATION_ID) --format="value(projectNumber)")


.PHONY: install-sys-mac
install-sys-mac:
	brew update && brew reinstall pyenv

.PHONY: install-python
install-python:
	# install the needed Python version in pyenv
	pyenv versions | grep "^[*| ] $(PYTHON_VERSION)" || pyenv install $(PYTHON_VERSION)

.python-version:
	# If you use this as a dependency, Make will always run all targets after it, as this is a phony target
	$(MAKE) install-python
	# Create virtual environment if not already installed
	pyenv virtualenvs | grep $(PROJECT_VENV) || pyenv virtualenv $(PYTHON_VERSION) $(PROJECT_VENV)
	# Set the correct python locally
	pyenv local $(PROJECT_VENV)
	pip install -U pip pip-tools

requirements/requirements.txt: .python-version
	# When hashes are used, pip insists that all packages are pinned, so we need to pin setuptools,
	# which is considered unsafe. --allow-unsafe is used for that and will be the default behaviour
	# in the future versions of pip-tools.
	cd requirements && pip-compile --generate-hashes --reuse-hashes --allow-unsafe requirements.in

test_cookie_cutter_template_project/requirements.txt: requirements/requirements.txt
	# Google cloud functions expects to have a requirements.txt file on the same level as main.py
	cd requirements && cp requirements.txt ../test_cookie_cutter_template_project/requirements.txt

requirements/dev-requirements.txt: .python-version
	cd requirements && pip-compile --generate-hashes --reuse-hashes dev-requirements.in

.PHONY: compile-deps
compile-deps: requirements/dev-requirements.txt test_cookie_cutter_template_project/requirements.txt

.venv-ready: requirements/dev-requirements.txt test_cookie_cutter_template_project/requirements.txt
	cd requirements && pip-sync --pip-args=--no-deps requirements.txt dev-requirements.txt
	touch .venv-ready

.PHONY: venv
venv: .venv-ready

$(PRE_COMMIT): .venv-ready
	test -f $(PRE_COMMIT) ||  wget --no-use-server-timestamps $(PRE_COMMIT_LINK)

.git/hooks/pre-commit: $(PRE_COMMIT)
	python3 $(PRE_COMMIT) install

.PHONY: install
install: .git/hooks/pre-commit

.PHONY: pre-commit
pre-commit: .git/hooks/pre-commit
	python3 $(PRE_COMMIT) run --all-files

.PHONY: pre-commit-ci
pre-commit-ci: .git/hooks/pre-commit
	python3 $(PRE_COMMIT) run --all-files --hook-stage push

.PHONY: run
run: .venv-ready
	cd test_cookie_cutter_template_project/ && \
	functions_framework --target=func1 --port=8090 --signature-type=http --debug

.PHONY: unit-test
unit-test: .venv-ready
	python -m pytest -x -rsxX -q -n auto --dist loadscope --cov=. tests/unit

.PHONY: integration-tests
integration-test: .venv-ready
	python -m pytest -x -rsxX -q -n auto --dist loadscope --cov=. tests/integration

.PHONY: set-roles-for-project
set-roles-for-project:
	# Gives the project access to the secrets. Useful for almost any service.
	if [ "$(shell gcloud projects get-iam-policy $(APPLICATION_ID) \
			--filter="bindings.role:roles/secretmanager.secretAccessor AND \
				bindings.members:serviceAccount:$(APPLICATION_ID)@appspot.gserviceaccount.com" \
			--format="value(etag)")" = "" ]; then \
			gcloud projects add-iam-policy-binding $(APPLICATION_ID) \
				--member='serviceAccount:$(APPLICATION_ID)@appspot.gserviceaccount.com' \
				--role='roles/secretmanager.secretAccessor'; \
	fi

	# Enable Subscriptions to create JWT for authentication
	if [ "$(shell gcloud projects get-iam-policy $(APPLICATION_ID) \
			--filter="bindings.role:roles/iam.serviceAccountTokenCreator AND \
				bindings.members:serviceAccount:service-$(PROJECT_NUMBER)@gcp-sa-pubsub.iam.gserviceaccount.com" \
			--format="value(etag)")" = "" ]; then \
			gcloud projects add-iam-policy-binding $(APPLICATION_ID) \
				--member='serviceAccount:service-$(PROJECT_NUMBER)@gcp-sa-pubsub.iam.gserviceaccount.com' \
				--role='roles/iam.serviceAccountTokenCreator'; \
	fi

.PHONY: set-project
set-project: set-roles-for-project
	gcloud config set project $(APPLICATION_ID)

.PHONY: deploy-cloud-function
deploy-cloud-function: set-project
gcloud functions deploy func1 \
		--runtime $(GCLOUD_RUNTIME) \
		--trigger-http \
		--no-allow-unauthenticated \
		--source ./test_cookie_cutter_template_project \
		--region $(REGION) \
		--set-build-env-vars PIP_NO_DEPS=true

.PHONY: deploy
deploy: deploy-cloud-function

clean:
	# Clean Python virtual environment
	pyenv uninstall -f $(PROJECT_VENV)
	rm -fv .venv-ready .python-version

	# Clean pre-commit
	if [ -f $(PRE_COMMIT) ]; then \
		python3 $(PRE_COMMIT) clean; \
		python3 $(PRE_COMMIT) gc; \
		python3 $(PRE_COMMIT) uninstall; \
	fi
	rm -fv pre-commit*.pyz

clean-deps:
	rm -fv requirements/*.txt
	rm -fv test_cookie_cutter_template_project/requirements.txt
