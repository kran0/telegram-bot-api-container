FROM alpine:edge AS builder

# d091a73: v6.4.1
ARG BRANCH=master  # used as argument to: git clone --branch "${BRANCH}"
ARG COMMIT         # used as argument to: git checkout "${COMMIT}"

RUN apk add --update --no-cache alpine-sdk linux-headers git zlib-dev openssl-dev gperf cmake git

WORKDIR /source
RUN git clone --branch "${BRANCH}" --recursive https://github.com/tdlib/telegram-bot-api.git .\
 && git checkout --recurse-submodules ${COMMIT}

RUN rm -rf build\
 && mkdir -vp build\
 && cd build\
 && cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX:PATH=.. ..\
 && cmake --build . --target install -j $(nproc)

RUN strip /source/bin/telegram-bot-api

FROM alpine:edge AS apkextractor

ADD https://raw.githubusercontent.com/kran0/tinyimages/master/apkextractor.sh /
RUN sh /apkextractor.sh openssl zlib libstdc++

FROM scratch
COPY --from=apkextractor /target /
COPY --from=builder /source/bin/telegram-bot-api /usr/local/bin/telegram-bot-api

EXPOSE 8081
ENTRYPOINT [ "/usr/local/bin/telegram-bot-api" ]
CMD        [ "--help" ]
