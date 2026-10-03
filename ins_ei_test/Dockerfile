ARG BUILD_FROM
FROM ${BUILD_FROM}

ARG INS_EI_CORE_REF=a5f8ba372b67b28cfe9366cbc0c08f9571f0d821
ARG INS_EI_CORE_BUILD=dev50-a5f8ba3

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
