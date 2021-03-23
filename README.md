**Forked from:**
https://github.com/jsecchiero/letsencrypt-portus

Portus Rancher stack deployment added with Let's Encrypt support.

# Portus and Docker Registry with Rancher 1.6 support

[![License](https://img.shields.io/github/license/mgbi/compose-portus.svg?maxAge=8600)]()

Deploy portus with auto-generated ssl certificate with letsencrypt.  
Using the idea of https://github.com/thpham/portus-registry-tls-compose

Official bootstrap for running your own [Portus](http://port.us.org/) with [Docker Registry](https://docs.docker.com/registry/)
on [Rancher v1.6](https://rancher.com/docs/rancher/v1.6/en/).

# Install

Run these command in the host where you need portus

*PORTUS_FQDN and REGISTRY_FQDN must be reachable domain from internet to work*

```
git clone https://github.com/jsecchiero/letsencrypt-portus
cd letsencrypt-portus
export PORTUS_FQDN=portus.example.com          # modify this
export REGISTRY_FQDN=registry.example.com      # modify this
export LETSENCRYPT_EMAIL=sysadmins@test.com    # modify this
export SECRET_KEY_BASE=$(pwgen -n 130 -c 1)
export PORTUS_PASSWORD=$(pwgen -n 32 -c 1)
export DATABASE_PASSWORD=$(pwgen -n 32 -c 1)
envsubst < .env.tmpl > .env
docker-compose up -d
```

Go to https://portus.example.com and login with `portus` and `PORTUS_PASSWORD`:

Create registry connection:
- edit _Name_ with `registry`
- edit _Hostname_ with `registry:5000`
- click on _show advanced button_
- edit _External Registry Name_ with `registry.example.com`
- click on _Create admin_ button

![alt text](https://raw.githubusercontent.com/jsecchiero/letsencrypt-portus/master/doc/registry.png)

# Test

Insert username and password
```
docker login registry.ll.tips
```

Download an example image and push to the registry
```
docker pull memcached
docker tag memcached registry.example.com/memcached
docker push registry.example.com/memcached
```

# LDAP integration (optional)
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
