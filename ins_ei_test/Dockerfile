ARG BUILD_FROM
FROM ${BUILD_FROM}

ARG INS_EI_CORE_REF=8de47f54aec72527b23e2c3abe6c900b08ed6cb9
ARG INS_EI_CORE_BUILD=dev68-8de47f5

RUN apk add --no-cache python3 py3-pip git bash
WORKDIR /opt/ins-ei
RUN echo "Building INS-EI TEST Core ref=${INS_EI_CORE_REF} build=${INS_EI_CORE_BUILD}" \
    && echo "${INS_EI_CORE_BUILD}" > /tmp/ins-ei-build-key \
    && git clone https://github.com/Mangid/ins-ei-core.git /opt/ins-ei/core \
    && cd /opt/ins-ei/core \
    && git checkout "${INS_EI_CORE_REF}" \
    && python3 -m compileall -q src \
    && git rev-parse HEAD > /opt/ins-ei/core/.ins-ei-core-sha \
    && python3 -m pip install --break-system-packages --no-cache-dir /opt/ins-ei/core
COPY run.sh /run.sh
RUN chmod 755 /run.sh && bash -n /run.sh
CMD ["/run.sh"]
