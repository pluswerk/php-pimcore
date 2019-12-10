ARG FROM=pluswerk/php-dev:nginx-7.3
FROM $FROM

ENV NODE_VERSION 11.12.0
RUN buildDeps='xz-utils' \
    && ARCH= && dpkgArch="$(dpkg --print-architecture)" \
    && case "${dpkgArch##*-}" in \
      amd64) ARCH='x64';; \
      ppc64el) ARCH='ppc64le';; \
      s390x) ARCH='s390x';; \
      arm64) ARCH='arm64';; \
      armhf) ARCH='armv7l';; \
      i386) ARCH='x86';; \
      *) echo "unsupported architecture"; exit 1 ;; \
    esac \
    && set -ex && mkdir -p /usr/share/man/man1 \
    && apt-get update && apt-get install -y ca-certificates \
        default-jre \
        default-jdk \
        curl \
        wget \
        gnupg \
        dirmngr \
        $buildDeps --no-install-recommends \
    && \
    for key in \
      94AE36675C464D64BAFA68DD7434390BDBE9B9C5 \
      FD3A5288F042B6850C66B31F09FE44734EB7990E \
      71DCFD284A79C3B38668286BC97EC7A07EDE3FC1 \
      DD8F2338BAE7501E3DD5AC78C273792F7D83545D \
      C4F0DFFF4E8C1A8236409D08E73BC641CC11F4C8 \
      B9AE9905FFD7803F25714661B63B535A4C206CA9 \
      77984A986EBC2AA786BC0F66B01FBB92821C587A \
      8FCCA13FEF1D0C2E91008E09770F7A9A5AE15600 \
      4ED778F539E3634C779C87C6D7062848A1AB005C \
      A48C2BEE680E841632CD4E44F07496B3EB3C1762 \
      B9E2F5981AA6E0CD28160D9FF13993A75599653C \
    ; do \
      gpg --batch --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys "$key" || \
      gpg --batch --keyserver hkp://ipv4.pool.sks-keyservers.net --recv-keys "$key" || \
      gpg --batch --keyserver hkp://pgp.mit.edu:80 --recv-keys "$key" ; \
    done \
    && curl -fsSLO --compressed "https://nodejs.org/dist/v$NODE_VERSION/node-v$NODE_VERSION-linux-$ARCH.tar.xz" \
    && curl -fsSLO --compressed "https://nodejs.org/dist/v$NODE_VERSION/SHASUMS256.txt.asc" \
    && gpg --batch --decrypt --output SHASUMS256.txt SHASUMS256.txt.asc \
    && grep " node-v$NODE_VERSION-linux-$ARCH.tar.xz\$" SHASUMS256.txt | sha256sum -c - \
    && tar -xJf "node-v$NODE_VERSION-linux-$ARCH.tar.xz" -C /usr/local --strip-components=1 --no-same-owner \
    && rm "node-v$NODE_VERSION-linux-$ARCH.tar.xz" SHASUMS256.txt.asc SHASUMS256.txt \
    && apt-get purge -y --auto-remove $buildDeps \
    && ln -s /usr/local/bin/node /usr/local/bin/nodejs

RUN DEBIAN_FRONTEND=noninteractive apt-get install -y \
    ffmpeg \
    libreoffice \
    libreoffice-math \
    xfonts-75dpi \
    poppler-utils \
    inkscape \
    libxrender1 \
    libfontconfig1 \
    ghostscript \
    librsvg2-dev \
    libimage-exiftool-perl

RUN wget https://github.com/imagemin/zopflipng-bin/raw/master/vendor/linux/zopflipng -O /usr/local/bin/zopflipng \
    && chmod 0755 /usr/local/bin/zopflipng \
    && wget https://github.com/imagemin/pngcrush-bin/raw/master/vendor/linux/pngcrush -O /usr/local/bin/pngcrush \
    && chmod 0755 /usr/local/bin/pngcrush \
    && wget https://github.com/imagemin/jpegoptim-bin/raw/master/vendor/linux/jpegoptim -O /usr/local/bin/jpegoptim \
    && chmod 0755 /usr/local/bin/jpegoptim \
    && wget https://github.com/imagemin/pngout-bin/raw/master/vendor/linux/x64/pngout -O /usr/local/bin/pngout \
    && chmod 0755 /usr/local/bin/pngout \
    && wget https://github.com/imagemin/advpng-bin/raw/master/vendor/linux/advpng -O /usr/local/bin/advpng \
    && chmod 0755 /usr/local/bin/advpng \
    && wget https://github.com/imagemin/mozjpeg-bin/raw/master/vendor/linux/cjpeg -O /usr/local/bin/cjpeg \
    && chmod 0755 /usr/local/bin/cjpeg \
    && npm install -g sqip

WORKDIR /opt

ENV GOLANG_VERSION 1.12.6
RUN wget https://dl.google.com/go/go$GOLANG_VERSION.linux-amd64.tar.gz && tar -xf go$GOLANG_VERSION.linux-amd64.tar.gz \
    && rm go$GOLANG_VERSION.linux-amd64.tar.gz  \
    && mkdir gopath
ENV GOPATH=/opt/gopath
ENV GOROOT=/opt/go
ENV PATH=$PATH:$GOPATH/bin:$GOROOT/bin

RUN go get -u github.com/fogleman/primitive \
    && cd /usr/local/bin \
    && ln -s /usr/lib/go/bin/primitive \
    && DEBIAN_FRONTEND=noninteractive apt-get clean

RUN apt install -y librsvg2-bin
WORKDIR /app/
