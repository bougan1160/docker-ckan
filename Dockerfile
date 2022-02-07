ARG CKAN_USER=ckan


FROM python:3.8-slim as build-base

ARG CKAN_USER

RUN apt update
RUN apt install -y build-essential git libpq-dev

RUN useradd -m ${CKAN_USER}

USER ${CKAN_USER}

RUN pip install --user setuptools==45


FROM build-base as ckan
ARG CKAN_VERSION=2.9.4

RUN pip install --user "git+https://github.com/ckan/ckan.git@ckan-${CKAN_VERSION}#egg=ckan[requirements]"


FROM build-base as s3filestore
ARG S3_FILESTORE_VERSION=develop

RUN pip install --user -r "https://raw.githubusercontent.com/qld-gov-au/ckanext-s3filestore/${S3_FILESTORE_VERSION}/requirements.txt"
RUN pip install --user "git+https://github.com/qld-gov-au/ckanext-s3filestore.git@${S3_FILESTORE_VERSION}#egg=ckanext-s3filestore"


FROM python:3.8-slim

ARG CKAN_USER
ENV CKAN_CONFIG /etc/ckan/default/ckan.ini
ENV PATH /home/${CKAN_USER}/.local/bin:${PATH}

RUN apt update \
 && apt install -y \
        libpq-dev \
        libxml2-dev \
        libxslt-dev \
        libgeos-dev \
        libssl-dev \
        libffi-dev \
        libmagick-dev \
 && rm -rf /var/lib/apt/lists/*

RUN useradd -m ${CKAN_USER}

COPY --from=ckan --chown=${CKAN_USER}:${CKAN_USER} /home/ckan/.local /home/ckan/.local
COPY --from=s3filestore --chown=${CKAN_USER}:${CKAN_USER} /home/ckan/.local /home/ckan/.local

RUN mkdir -p /etc/ckan/default \
 && cp \
    /home/${CKAN_USER}/.local/lib/python3.8/site-packages/ckan/config/who.ini \
    /etc/ckan/default/who.ini \
 && chown -R ckan:ckan /etc/ckan/default

USER ${CKAN_USER}

RUN ckan generate config ${CKAN_CONFIG}

COPY --chown=${CKAN_USER}:${CKAN_USER} docker-entrypoint.sh /docker-entrypoint.sh

EXPOSE 5000

ENTRYPOINT [ "/docker-entrypoint.sh" ]

CMD ["ckan","-c","/etc/ckan/default/ckan.ini", "run", "--host", "0.0.0.0"]
