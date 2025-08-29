FROM alpine:latest

COPY base/ /

RUN apk add --no-cache runit tzdata sudo gnupg perl-socket6 bash bind-tools make perl-db_file razor dcc dcc-dccifd dcc-extras perl-net-libidn perl-mail-spf perl-dbi perl-dbd-sqlite perl-archive-zip perl-net-ssleay perl-io-socket-ssl perl-libwww && \
    # cpanm GeoIP2::Database::Reader && \
    # cpanm Encode::Detect::Detector Net::Patricia Net::CIDR::Lite Email::Address::XS Mail::DMARC Devel::Cycle Text::Diff && \
    find /etc/service/ -type f -name run -exec chmod 754 {} \; && \
    find /etc/periodic/ -type f -exec chmod 774 {} \; && \
    chmod 700 /init.sh

EXPOSE 783

# Create the labels
ARG DATE
ARG DESCRIPTION
ARG LICENSE="GPL-3.0-or-later"
ARG MAINTAINER
ARG NAME
ARG TITLE
ARG VERSION
ARG VENDOR="${MAINTAINER}"
ARG WEBSITE

LABEL maintainer="${MAINTAINER}"
LABEL org.opencontainers.image.created="${DATE}"
LABEL org.opencontainers.image.description="${DESCRIPTION}"
LABEL org.opencontainers.image.licenses="${LICENSE}"
LABEL org.opencontainers.image.name="${NAME}"
LABEL org.opencontainers.image.source="${WEBSITE}"
LABEL org.opencontainers.image.title="${TITLE}"
LABEL org.opencontainers.image.url="${WEBSITE}"
LABEL org.opencontainers.image.vendor="${VENDOR}"
LABEL org.opencontainers.image.version="${VERSION}"

VOLUME  /var/lib/spamassassin

ENV DNS_CHECKS=1
ENV INTERNAL_NETWORKS=""
ENV TRUSTED_NETWORKS=""

RUN adduser -D spamassassin

HEALTHCHECK --interval=5s --start-period=15s --timeout=1s --start-interval=1s \
    CMD netstat -ltn | grep -c 783

CMD ["/init.sh"]
