**Forked from:**
https://github.com/jsecchiero/letsencrypt-portus

Rancher stack configuration for Portus deployment added with Let's Encrypt support.

# Portus and Docker Registry with Rancher 1.6 support

[![License](https://img.shields.io/github/license/mgbi/rancher-portus.svg?maxAge=8600)]()

Deploy Portus with auto-generated SSL certificate with Let's Encrypt.
Using the idea of https://github.com/thpham/portus-registry-tls-compose

Unofficial bootstrap for running your own [Portus](http://port.us.org/) with [Docker Registry](https://docs.docker.com/registry/)
on [Rancher v1.6](https://rancher.com/docs/rancher/v1.6/en/).

## Portus and Docker Registry Rancher stack setup

### Configuration structure
```
.
├── .env.rancher.tmpl               # template for .env.rancher file with all public environment variables
├── docker-compose.rancher.yml      # production-like configuration only
├── docker-compose.yml              # common configuration
├── prod-compose.sh                 # Rancher stack deployment script
├── rancher_cli.env                 # Rancher API keys
└── shared_vars.env                 # the values of all public and secret environment variables
```

### Environment variables setup
```
// create and fill shared_vars.env file (ignored by git)
// *PORTUS_FQDN and REGISTRY_FQDN must be reachable domain from internet to work*
// export SECRET_KEY_BASE=$(pwgen -n 130 -c 1)
// export PORTUS_PASSWORD=$(pwgen -n 32 -c 1)
// export DATABASE_PASSWORD=$(pwgen -n 32 -c 1)
cp shared_vars.env.template shared_vars.env
edit shared_vars.env

// Add templates for the public variables
edit .env.rancher.tmpl
// And create secret files in `create_secrets_files` function
edit prod-compose.sh
```
As you can see, prod-compose.sh manages the environment variables:
* Public environment variables will be saved in `.env.rancher` file.
* Secret environment variables will be saved in separate files in `secrets` directory.

### Containers deployment on Rancher
(after Environment variables setup)

Remember to start Rancher Secrets from Catalog before the deployment!

To deploy use your Rancher Account API Key (it can be shared between projects
in different environments as well) or create a new one:

Open the Rancher GUI and click in the top panel `API` → `Keys` and then click
`Add Account API Keys`.
```
// create and fill rancher_cli.env file (ignored by git)
cp rancher_cli.env.template rancher_cli.env
edit rancher_cli.env

./prod-compose.sh
```

### Registry connection
Go to `https://${PORTUS_FQDN}` and login with `portus` and `${PORTUS_PASSWORD}`:

Create registry connection:
- edit _Name_ with `registry`
- edit _Hostname_ with `${REGISTRY_FQDN}:5000`
- click on _show advanced button_
- click on _Use SSL_
- click on _Create admin_ button

![Registry creation](./doc/registry.png)

### Test
Insert username and password
```
docker login ${REGISTRY_FQDN}:5000
```

Download an example image and push to the registry
```
docker pull memcached
docker tag memcached ${REGISTRY_FQDN}:5000/memcached
docker push ${REGISTRY_FQDN}:5000/memcached
```

### LDAP integration (optional)
The system can be authenticated with your LDAP server (local authentication will be disabled)
Adding this parameters into docker-compose.yml

```
environment:
  # ldap
  PORTUS_LDAP_ENABLED: 'true'
  PORTUS_LDAP_HOSTNAME: '<ldap server address or ip>'
  PORTUS_LDAP_PORT: '389'
  PORTUS_LDAP_BASE: 'dc=department,dc=example,dc=com'
  PORTUS_LDAP_AUTHENTICATON_ENABLED: 'true'
  PORTUS_LDAP_AUTHENTICATON_BIND_DN: 'cn=<ldap user query>,ou=People,dc=department,dc=example,dc=com'
  PORTUS_LDAP_AUTHENTICATON_PASSWORD: '<ldap cn user password>'
```
