ARG BUILD_FROM
FROM ${BUILD_FROM}

RUN apk add --no-cache \
    wireguard-tools \
    iproute2 \
    iptables \
    bash

COPY run.sh /run.sh

RUN chmod 755 /run.sh \
    && bash -n /run.sh

CMD ["/run.sh"]