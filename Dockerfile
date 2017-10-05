FROM ruby:2.3.4-alpine
RUN apk update \
    && \
    apk add musl libgcc libstdc++ binutils-libs binutils \
    isl libgomp libatomic pkgconf mpfr3 mpc1 gcc musl-dev \
    libc-dev g++ musl-utils make


RUN mkdir -p /usr/src/app
COPY Gemfile.docker /usr/src/app/Gemfile
COPY Gemfile.lock /usr/src/app/Gemfile.lock
WORKDIR /usr/src/app
RUN bundle config --global frozen 1 \
    && \
    bundle install \
    && \
    apk del mpfr3 mpc1 gcc musl-dev libc-dev make \
    libc-dev g++ openssl-dev zlib-dev yaml-dev \
    libffi-dev .ruby-rundeps openssl-dev zlib-dev \
    yaml-dev libffi-dev \
    && \
    apk add yaml zlib ca-certificates \
    && \
    rm -rf /root/.gem \
    /root/.bundle \
    /usr/local/lib/ruby/gems/2.3.0/gems/test-unit-* \
    /usr/local/lib/ruby/gems/2.3.0/gems/net-telnet-* \
    /usr/local/lib/ruby/gems/2.3.0/gems/minitest-* \
    /usr/local/lib/ruby/gems/2.3.0/gems/did_you_mean-*

COPY . /usr/src/app
COPY Gemfile.docker /usr/src/app/Gemfile
CMD ["/usr/src/app/bin/start.sh"]
