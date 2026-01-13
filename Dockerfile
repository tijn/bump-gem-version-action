FROM ruby:3.2.1-alpine3.17 AS base
RUN gem update --system 3.4.7 && \
    apk --no-cache add git jq curl github-cli
RUN gem install gem-release
COPY labels /labels
COPY src/*.sh /
ENTRYPOINT ["/entrypoint.sh"]
