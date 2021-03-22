#!/bin/bash -e
RANCHER_STACK_NAME=${RANCHER_STACK_NAME:-letsencrypt-portus}

if [ ! -f rancher_cli.env ]; then
	echo "Create rancher_cli.env file from rancher_cli.env.template"
	exit 1
fi

if [ ! -f shared_vars.env ]; then
	echo "Create shared_vars.env file from shared_vars.env.template"
	exit 1
fi

source rancher_cli.env

source shared_vars.env

cleanup () {
	rm -f .env.rancher
	rm -rf secrets
}

trap cleanup EXIT

# set variables used in docker-compose files
test $PUBLIC_VARIABLE

echo PUBLIC_VARIABLE=$PUBLIC_VARIABLE > .env.rancher

create_secrets_files () {(
	# subshell without printing executed commands
	set +x
	test $SECRET_VARIABLE

	# the contents of the specified files will be used to create the secrets
	# before creating the stack and starting the services
	mkdir -p secrets
	echo $SECRET_VARIABLE > secrets/secret-variable.txt
)}

create_secrets_files

rancher_cli () {
	rancher --file docker-compose.yml --file docker-compose.rancher.yml \
		--rancher-file rancher-compose.yml "$@"
}

rancher_cli up -d --stack $RANCHER_STACK_NAME --env-file .env --pull \
	--upgrade --confirm-upgrade --description "A simple Rancher stack example"
