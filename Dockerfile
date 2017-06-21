FROM ruby:2.3.4-onbuild
WORKDIR /usr/src/app
CMD ["/usr/src/app/bin/start.sh"]
