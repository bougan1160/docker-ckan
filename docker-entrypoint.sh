#!/bin/sh
set -e

: ${CKAN_STORAGE_PATH:="/tmp"}
CONFIG=${CKAN_CONFIG}

abort () {
  echo "$@" >&2
  exit 1
}

set_environment () {
  export CKAN_SITE_ID=${CKAN_SITE_ID}
  export CKAN_SITE_URL=${CKAN_SITE_URL}
  export CKAN_SQLALCHEMY_URL="postgresql://${POSTGRES_USER}:${POSTGRES_PASSWORD}@${POSTGRES_WRITE_HOST}/${POSTGRES_DB}"
  export CKAN_SOLR_URL=${CKAN_SOLR_URL}
  export CKAN_REDIS_URL=${CKAN_REDIS_URL}
  export CKAN_STORAGE_PATH=${CKAN_STORAGE_PATH}
  export CKAN_DATASTORE_WRITE_URL="postgresql://${POSTGRES_USER}:${POSTGRES_PASSWORD}@${POSTGRES_WRITE_HOST}/${POSTGRES_DATASTORE_DB}"
  export CKAN_DATASTORE_READ_URL="postgresql://${POSTGRES_USER}:${POSTGRES_PASSWORD}@${POSTGRES_READ_HOST}/${POSTGRES_DATASTORE_DB}"
  export CKAN_SMTP_SERVER=${CKAN_SMTP_SERVER}
  export CKAN_SMTP_STARTTLS=${CKAN_SMTP_STARTTLS}
  export CKAN_SMTP_USER=${CKAN_SMTP_USER}
  export CKAN_SMTP_PASSWORD=${CKAN_SMTP_PASSWORD}
  export CKAN_SMTP_MAIL_FROM=${CKAN_SMTP_MAIL_FROM}
  export CKAN_MAX_UPLOAD_SIZE_MB=${CKAN_MAX_UPLOAD_SIZE_MB}
}

update_config () {
  ckan config-tool ${CONFIG} ckan.plugins='stats text_view image_view recline_view datastore datapusher s3filestore'
  ckan config-tool ${CONFIG} sqlalchemy.url=${CKAN_SQLALCHEMY_URL} > /dev/null 
  ckan config-tool ${CONFIG} ckan.datastore.write_url=${CKAN_DATASTORE_WRITE_URL} > /dev/null 
  ckan config-tool ${CONFIG} ckan.datastore.read_url=${CKAN_DATASTORE_READ_URL} > /dev/null 
  ckan config-tool ${CONFIG} ckan.datapusher.callback_url_base=${DATAPUSHER_CALLBACK_URL}
  ckan config-tool ${CONFIG} ckanext.s3filestore.aws_bucket_name=${S3_BUCKET_NAME}
  ckan config-tool ${CONFIG} ckanext.s3filestore.region_name=${S3_REGION}
  ckan config-tool ${CONFIG} ckanext.s3filestore.signature_version=s3v4
  if [ ! -z ${CKAN_LOCALE_DEFAULT} ]; then
    ckan config-tool ${CONFIG} ckan.locale_default=${CKAN_LOCALE_DEFAULT}
  fi
  if [ ! -z ${S3_ACCESS_KEY_ID} ]; then
    ckan config-tool ${CONFIG} ckanext.s3filestore.aws_access_key_id=${S3_ACCESS_KEY_ID}
  fi
  if [ ! -z ${S3_SECRET_ACCESS_KEY} ]; then
    ckan config-tool ${CONFIG} ckanext.s3filestore.aws_secret_access_key=${S3_SECRET_ACCESS_KEY}
  fi
  if [ ! -z ${S3_USE_AMI_ROLE} ]; then
    ckan config-tool ${CONFIG} ckanext.s3filestore.aws_use_ami_role=true
  fi
  if [ ! -z ${MINIO_PATH} ]; then
    ckan config-tool ${CONFIG} ckanext.s3filestore.host_name=${MINIO_PATH}
  fi
  if [ ! -z ${CKANEXT_S3FILESTORE_ACL} ]; then
    ckan config-tool ${CONFIG} ckanext.s3filestore.acl=${CKANEXT_S3FILESTORE_ACL}
  fi
}

if [ -z "$POSTGRES_READ_HOST" ]; then
  abort "ERROR: POSTGRES_READ_HOST is not specified"
fi

if [ -z "$POSTGRES_WRITE_HOST" ]; then
  abort "ERROR: POSTGRES_WRITE_HOST is not specified"
fi

if [ -z "$POSTGRES_USER" ]; then
  abort "ERROR: POSTGRES_USER is not specified"
fi

if [ -z "$POSTGRES_PASSWORD" ]; then
  abort "ERROR: POSTGRES_PASSWORD is not specified"
fi

if [ -z "$POSTGRES_DB" ]; then
  abort "ERROR: POSTGRES_DB is not specified"
fi

if [ -z "$POSTGRES_DATASTORE_DB" ]; then
  abort "ERROR: POSTGRES_DATASTORE_DB is not specified"
fi

if [ -z "$CKAN_SOLR_URL" ]; then
  abort "ERROR: CKAN_SOLR_URL is not specified"
fi

if [ -z "$CKAN_REDIS_URL" ]; then
  abort "ERROR: CKAN_REDIS_URL is not specified"
fi

if [ -z "$S3_BUCKET_NAME" ]; then
  abort "ERROR: S3_BUCKET_NAME is not specified"
fi

if [ -z "$S3_REGION" ]; then
  abort "ERROR: S3_REGION is not specified"
fi

if [ -z "$S3_USE_AMI_ROLE" -a -z "$S3_ACCESS_KEY_ID" -a -z "$S3_SECRET_ACCESS_KEY" ]; then
  abort "ERROR: You have to specify S3_USE_AMI_ROLE or secrets for S3"
fi

set_environment

update_config

if [ ! -z "$RUN_INIT_DB" ]; then
  ckan --config "$CONFIG" db init
fi

exec "$@"
