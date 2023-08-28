FROM ubuntu
# multiarch/crossbuild

ARG ZLIB_VERSION=1.3

RUN apt-get update && \
    export DEBIAN_FRONTEND=noninteractive && \
    apt-get install -yq \
        ca-certificates \
        automake \
        build-essential \
        cmake \
        curl \
        file \
        g++ \
        git \
        libtool \
        linux-libc-dev \
        musl-dev \
        musl-tools \
        pkgconf \
        unzip \
        xutils-dev \
        && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Static linking for C/C++ code using musl-libc
RUN ln -s "/usr/bin/g++" "/usr/bin/musl-g++"
ENV CC=musl-gcc C_INCLUDE_PATH=/usr/local/musl/include/

RUN echo "Building zlib" \
    && cd /tmp \
    && curl -k -fLO "http://zlib.net/zlib-$ZLIB_VERSION.tar.gz" \
    && tar xzf "zlib-$ZLIB_VERSION.tar.gz" && cd "zlib-$ZLIB_VERSION" \
    && CC=musl-gcc ./configure --static --prefix=/usr/local/musl \
    && make && make install \
    && cd contrib/minizip \
    && autoreconf -fi \
    && ./configure --enable-shared=no --with-pic \
    && make -j$(nproc) install \
    && rm -r /tmp/*

RUN echo "Building expat" \
    && cd /tmp \
    && curl -k -LO https://github.com/libexpat/libexpat/releases/download/R_2_2_10/expat-2.2.10.tar.gz \
    && tar -xvf expat-2.2.10.tar.gz \
    && cd expat-2.2.10 \
    && CFLAGS="-fPIC" ./configure --prefix=/usr/local/musl/ --enable-shared=no \
    && make \
    && make install \
    && rm -r /tmp/*

RUN echo "Building xlsxio" \
    && cd /tmp \
    && curl -k -fLO "https://github.com/brechtsanders/xlsxio/archive/refs/tags/0.2.33.tar.gz" \
    && tar xzf 0.2.33.tar.gz \
    && cd xlsxio-0.2.33 \
    && make static-lib \
    && install -v -m755 libxlsxio_read.a /usr/local/musl/lib/ \
    && install -v -m755 libxlsxio_write.a /usr/local/musl/lib/ \
    && install -v -m755 include/* /usr/local/musl/include/ \
    && rm -r /tmp/*
