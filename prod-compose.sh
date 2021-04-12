#!/bin/bash -e
RANCHER_STACK_NAME=${RANCHER_STACK_NAME:-portus}

if [ ! -f rancher_cli.env ]; then
	echo "Create rancher_cli.env file from rancher_cli.env.template"
	exit 1
fi

if [ ! -f shared_vars.env ]; then
	echo "Create shared_vars.env file from shared_vars.env.template"
	exit 1
fi

source rancher_cli.env

# load and export all defined variables
set -o allexport
source shared_vars.env
set +o allexport

cleanup () {
	rm -f .env.rancher
	rm -rf secrets
}

trap cleanup EXIT

# set variables used in docker-compose file
envsubst < env.rancher.tmpl > .env.rancher

source .env.rancher

# check variables used in docker-compose files
test $PORTUS_FQDN
test $REGISTRY_FQDN
test $LETSENCRYPT_EMAIL
test $PORTUS_USERNAME
test $EMAIL_FROM
test $EMAIL_REPLY_TO
test $EMAIL_SMTP_ADDRESS
test $EMAIL_SMTP_PORT
test $EMAIL_SMTP_DOMAIN
test $EMAIL_SMTP_SSL_TLS
test $EMAIL_SMTP_USER_NAME

create_secrets_files () {(
	# subshell without printing executed commands
	set +x
	test $SECRET_KEY_BASE
	test $PORTUS_PASSWORD
	test $MYSQL_ROOT_PASSWORD
	test $MYSQL_PASSWORD
	test $EMAIL_SMTP_PASSWORD

	# the contents of the specified files will be used to create the secrets
	# before creating the stack and starting the services
	mkdir -p secrets
	echo $SECRET_KEY_BASE > secrets/secret-key-base.txt
	echo $PORTUS_PASSWORD > secrets/portus-password.txt
	echo $MYSQL_ROOT_PASSWORD > secrets/mysql-root-password.txt
	echo $MYSQL_PASSWORD > secrets/mysql-password.txt
	echo $EMAIL_SMTP_PASSWORD > secrets/email-smtp-password.txt
)}

create_secrets_files

rancher_cli () {
	rancher --file docker-compose.yml --file docker-compose.rancher.yml \
		--rancher-file rancher-compose.yml "$@"
}

disable_https () {
	sed -i -e "/certs:/,+1d" -e "/default_cert:/d" -e "/frontend 80/,+2d" -e "/protocol: https/,+4d" rancher-compose.yml
}

enable_https () {
	# revert any changes
	git checkout rancher-compose.yml
}

rancher ps $RANCHER_STACK_NAME/lb || (disable_https && DISABLED_HTTPS=1)

rancher_cli up -d --stack $RANCHER_STACK_NAME --env-file .env.rancher --pull \
	--upgrade --confirm-upgrade --description "Portus authorization service with the Docker Registry"

if [ "$DISABLED_HTTPS" = 1 ]; then
	echo "Waiting for the SSL certificate. Please deploy load-balancer once again when it is ready"
    enable_https
fi
