![](header.png)

[![Minio Version](https://img.shields.io/badge/Minio-latest-blue.svg)]() [![Dokku Version](https://img.shields.io/badge/Dokku-v0.11.2-blue.svg)]()

# Run Minio on Dokku

## Perquisites

### What is Minio?

Minio is an object storage server, and API compatible with Amazon S3 cloud
storage service. Read more at the [minio.io](https://www.minio.io/) website.

### What is Dokku?

[Dokku](http://dokku.viewdocs.io/dokku/) is the smallest PaaS implementation
you've ever seen - _Docker powered mini-Heroku_.

### Requirements

* A working [Dokku host](http://dokku.viewdocs.io/dokku/getting-started/installation/)

# Setup

We are going to use the domain `minio.example.com` and Dokku app `minio` for
demonstration purposes. Make sure to replace it.

## Create the app

Log onto your Dokku Host to create the Minio app:

```bash
dokku apps:create minio
```

## Configuration

### Setting environment variables

Minio uses two access keys (`ACCESS_KEY` and `SECRET_KEY`) for authentication
and object management. The following commands sets a random strings for each
access key.

```bash
dokku config:set --no-restart minio MINIO_ROOT_USER=$(echo `openssl rand -base64 45` | tr -d \=+ | cut -c 1-20)
dokku config:set --no-restart minio MINIO_ROOT_PASSWORD=$(echo `openssl rand -base64 45` | tr -d \=+ | cut -c 1-32)
```

To login in the browser or via API, you will need to supply both the
`ACCESS_KEY` and `SECRET_KEY`. You can retrieve these at any time while logged
in on your host running dokku via `dokku config minio`.

> **Note:** if you do not set these keys, Minio will generate them during
> startup and output them to the log (check if via `dokku logs minio`). You
> will still need to set them manually.

You'll also need to set other two configuration variables:

- [nginx's `client-max-body-size`](https://dokku.com/docs/configuration/nginx/#specifying-a-custom-client_max_body_size): used to allow uploads up to 15MB to the HTTP server (if the file size is greater
  than 15MB, `s3cmd` will split in 15MB parts).
- An app [environment variable](https://dokku.com/docs/configuration/environment-variables/#environment-variables) `MINIO_DOMAIN`: used to tell Minio the domain name being used by the server.

```bash
dokku nginx:set minio client-max-body-size 15m
dokku config:set --no-restart minio MINIO_DOMAIN=minio.example.com
```

> **Note**: if you're using [s4cmd](https://github.com/bloomreach/s4cmd/)
> instead, be sure to pass the following parameters:
> `--multipart-split-size=15728640 --max-singlepart-upload-size=15728640`.


## Persistent storage

To persists uploaded data between restarts, we create a folder on the host
machine, add write permissions to the user defined in `Dockerfile` and tell
Dokku to mount it to the app container.

```bash
dokku storage:ensure-directory minio --chown false
sudo chown 1000:1000 /var/lib/dokku/data/storage/minio
dokku storage:mount minio /var/lib/dokku/data/storage/minio:/data
```

## Domain setup

To get the domain working, we need to apply a few settings. The wildcard domain must be setup in DNS for vhost style paths.
First we set the domain.

```bash
dokku domains:set minio minio.example.com *.minio.example.com
```

This Dockerfile exposes port `9000` for bucket requests and `9001` for web console.

## Push Minio to Dokku

### Grabbing the repository

First clone this repository onto your machine.

```bash
git clone https://github.com/rjocoleman/minio-dokku
```

### Set up git remote

Now you need to set up your Dokku server as a remote.

```bash
git remote add dokku dokku@example.com:minio
```

### Push Minio

Now we can push Minio to Dokku (_before_ moving on to the [next
part](#domain-and-ssl-certificate)).

```bash
git push dokku master
```

## SSL certificate

Last but not least, we can go an grab the SSL certificate from [Let's
Encrypt](https://letsencrypt.org/).

```bash
dokku config:set --no-restart minio DOKKU_LETSENCRYPT_EMAIL=you@example.com
dokku letsencrypt minio
dokku proxy:ports-set minio https:443:9000
```

> **Note**: you must execute these steps *after* pushing the app to Dokku
> host.

## Wrapping up

Your Minio instance should now be available on
[minio.example.com](https://minio.example.com).
