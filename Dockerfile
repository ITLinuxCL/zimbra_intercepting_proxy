FROM ruby:2.3.4-alpine
RUN apk update
RUN apk add g++ musl-dev make

RUN bundle config --global frozen 1
RUN mkdir -p /usr/src/app
COPY Gemfile.docker /usr/src/app/Gemfile
COPY Gemfile.lock /usr/src/app/

WORKDIR /usr/src/app
RUN bundle install

COPY . /usr/src/app
COPY Gemfile.docker /usr/src/app/Gemfile
CMD ["/usr/src/app/bin/start.sh"]
