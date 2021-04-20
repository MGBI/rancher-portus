#!/bin/bash -ex
RANCHER_STACK_NAME=${RANCHER_STACK_NAME:-portus}

if [ ! -f rancher_cli.env ]; then
	echo "Create rancher_cli.env file from rancher_cli.env.template"
	exit 1
fi

if [ ! -f shared_vars.env ]; then
	echo "Create shared_vars.env file from shared_vars.env.template"
	exit 1
fi

# load and export all defined variables
set -o allexport
source shared_vars.env
set +o allexport

cleanup () {
	rm -rf secrets
}

check_compose_variables () {
	# check variables used in docker-compose files
	test $PORTUS_FQDN
	test $REGISTRY_FQDN
	test $LETSENCRYPT_EMAIL
	test $EMAIL_FROM
	test $EMAIL_REPLY_TO
	test $EMAIL_SMTP_ADDRESS
	test $EMAIL_SMTP_PORT
	test $EMAIL_SMTP_SSL_TLS
	test $EMAIL_SMTP_USER_NAME
}

create_secrets_files () {
	# create files with secrets values
	test $SECRET_KEY_BASE
	test $PORTUS_PASSWORD
	test $MYSQL_ROOT_PASSWORD
	test $MYSQL_PASSWORD
	test $EMAIL_SMTP_PASSWORD

	# the contents of the specified files will be used to create the secrets
	# before creating the stack and starting the services
	mkdir -p secrets
	echo $SECRET_KEY_BASE > secrets/secret-key-base.txt
	unset SECRET_KEY_BASE
	echo $PORTUS_PASSWORD > secrets/portus-password.txt
	unset PORTUS_PASSWORD
	echo $MYSQL_ROOT_PASSWORD > secrets/mysql-root-password.txt
	unset MYSQL_ROOT_PASSWORD
	echo $MYSQL_PASSWORD > secrets/mysql-password.txt
	unset MYSQL_PASSWORD
	echo $EMAIL_SMTP_PASSWORD > secrets/email-smtp-password.txt
	unset EMAIL_SMTP_PASSWORD
}

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

trap cleanup EXIT

check_compose_variables

create_secrets_files

source rancher_cli.env

# load Rancher access data
test $RANCHER_URL
test $RANCHER_ACCESS_KEY
test $RANCHER_SECRET_KEY

rancher ps $RANCHER_STACK_NAME/lb || (disable_https && DISABLED_HTTPS=1)

rancher_cli up -d --stack $RANCHER_STACK_NAME --pull \
	--upgrade --confirm-upgrade --description "Portus authorization service with the Docker Registry"

if [ "$DISABLED_HTTPS" = 1 ]; then
	echo "Waiting for the SSL certificate. Please deploy load-balancer once again when it is ready"
    enable_https
fi
