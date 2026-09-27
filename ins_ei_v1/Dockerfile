ARG BUILD_FROM
FROM ${BUILD_FROM}

RUN apk add --no-cache python3 py3-pip git bash

WORKDIR /opt/ins-ei

RUN git clone --depth 1 https://github.com/Mangid/ins-ei-core.git /opt/ins-ei/core \
    && python3 -m pip install --break-system-packages --no-cache-dir /opt/ins-ei/core

COPY run.sh /run.sh
RUN chmod 755 /run.sh && bash -n /run.sh

CMD ["/run.sh"]
