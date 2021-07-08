ARG FROM=webdevops/php-nginx:7.4

FROM golang:1.11-alpine AS golang

RUN apk add --update git && rm /var/cache/apk/*
RUN go get -u github.com/fogleman/primitive

FROM alpine as dependencies

RUN apk add --update wget tar git xz && rm /var/cache/apk/*

RUN wget -q https://github.com/imagemin/zopflipng-bin/raw/main/vendor/linux/zopflipng -O /usr/local/bin/zopflipng \
    && chmod 0755 /usr/local/bin/zopflipng \
    && wget -q https://github.com/imagemin/pngcrush-bin/raw/main/vendor/linux/pngcrush -O /usr/local/bin/pngcrush \
    && chmod 0755 /usr/local/bin/pngcrush \
    && wget -q https://github.com/imagemin/jpegoptim-bin/raw/main/vendor/linux/jpegoptim -O /usr/local/bin/jpegoptim \
    && chmod 0755 /usr/local/bin/jpegoptim \
    && wget -q https://github.com/imagemin/pngout-bin/raw/main/vendor/linux/x64/pngout -O /usr/local/bin/pngout \
    && chmod 0755 /usr/local/bin/pngout \
    && wget -q https://github.com/imagemin/advpng-bin/raw/main/vendor/linux/advpng -O /usr/local/bin/advpng \
    && chmod 0755 /usr/local/bin/advpng \
    && wget -q https://github.com/imagemin/mozjpeg-bin/raw/main/vendor/linux/cjpeg -O /usr/local/bin/cjpeg \
    && chmod 0755 /usr/local/bin/cjpeg

RUN cd /tmp && wget https://github.com/wkhtmltopdf/wkhtmltopdf/releases/download/0.12.4/wkhtmltox-0.12.4_linux-generic-amd64.tar.xz \
            && tar xvf wkhtmltox-0.12.4_linux-generic-amd64.tar.xz \
            && mv wkhtmltox/bin/wkhtmlto* /usr/bin/ \
            && chmod 0755 /usr/bin/wkhtmltopdf \
            && chmod 0755 /usr/bin/wkhtmltoimage \
            && rm -rf wkhtmltox

FROM $FROM as php

COPY --from=golang /go/bin/primitive /usr/local/bin/primitive
COPY --from=dependencies /usr/local/bin/zopflipng /usr/local/bin/zopflipng
COPY --from=dependencies /usr/local/bin/pngcrush /usr/local/bin/pngcrush
COPY --from=dependencies /usr/local/bin/pngout /usr/local/bin/pngout
COPY --from=dependencies /usr/local/bin/advpng /usr/local/bin/advpng
COPY --from=dependencies /usr/local/bin/cjpeg /usr/local/bin/cjpeg
COPY --from=dependencies /usr/bin/wkhtmltopdf /usr/bin/wkhtmltopdf
COPY --from=dependencies /usr/bin/wkhtmltoimage /usr/bin/wkhtmltoimage

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    poppler-utils \
    libimage-exiftool-perl \
    webp \
    inkscape \
    ghostscript \
    ffmpeg \
    graphviz \
    librsvg2-bin \
    libreoffice \
    opencv-data \
    jpegoptim \
    libjpeg-dev \
    libjpeg62-turbo-dev \
    lsb-release \
    && rm -rf /var/lib/apt/lists/*

RUN cd /tmp \
        && mkdir install-nginx \
        && cd install-nginx \
        && echo "deb http://nginx.org/packages/mainline/debian `lsb_release -cs` nginx" >> /etc/apt/sources.list.d/nginx.list \
        && echo "deb-src http://nginx.org/packages/mainline/debian `lsb_release -cs` nginx" >> /etc/apt/sources.list.d/nginx.list \
        && curl -fsSL https://nginx.org/keys/nginx_signing.key | apt-key add - \
        && apt-key fingerprint ABF5BD827BD9BF62 \
        && apt-get update && apt-get remove -y nginx nginx-full && DEBIAN_FRONTEND=noninteractive apt-get install -q -y -o Dpkg::Options::=--force-confdef nginx \
        && apt source nginx \
        && git clone https://github.com/google/ngx_brotli.git \
        && cd ngx_brotli \
        && git submodule update --init \
        && cd .. \
        && apt-get build-dep -y nginx \
        && apt-get install -y libperl-dev python3-pip \
        && cd nginx-1.* \
        && ./configure \
                --with-http_ssl_module \
                --with-http_realip_module \
                --with-http_addition_module \
                --with-http_sub_module \
                --with-http_dav_module \
                --with-http_flv_module \
                --with-http_mp4_module \
                --with-http_gunzip_module \
                --with-http_gzip_static_module \
                --with-http_random_index_module \
                --with-http_secure_link_module \
                --with-http_stub_status_module \
                --with-http_auth_request_module \
                --with-http_perl_module=dynamic \
                --with-threads \
                --with-stream \
                --with-stream_ssl_module \
                --with-stream_ssl_preread_module \
                --with-stream_realip_module \
                --with-http_slice_module \
                --with-mail \
                --with-mail_ssl_module \
                --with-compat \
                --with-file-aio \
                --with-http_v2_module \
                --with-compat \
                --add-dynamic-module=../ngx_brotli \
        && make modules \
        && cp objs/*.so /usr/lib/nginx/modules \
        && ln -s /usr/lib/nginx/modules /etc/nginx/modules \
        && echo "load_module modules/ngx_http_brotli_filter_module.so;" >> /etc/nginx/modules-enabled/brotli.conf \
        && echo "load_module modules/ngx_http_brotli_static_module.so;" >> /etc/nginx/modules-enabled/brotli.conf \
        && rm -rf /var/lib/apt/lists/* \
        && rm -rf /tmp/install-nginx

# RUN cd /tmp && git clone https://gitlab.com/wavexx/facedetect.git \
#            && pip3 install numpy opencv-python \
#            && cd facedetect \
#            && cp facedetect /usr/local/bin \
#            && cd .. \
#            && rm -rf facedetect

RUN docker-service enable postfix

# https://stackoverflow.com/questions/52998331/imagemagick-security-policy-pdf-blocking-conversion#comment110879511_59193253
RUN sed -i '/disable ghostscript format types/,+6d' /etc/ImageMagick-6/policy.xml

COPY nginx.conf /opt/docker/etc/nginx/vhost.common.d/00-pimcore.conf_deactivated

WORKDIR /app/
