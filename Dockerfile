# syntax=docker/dockerfile:experimental

FROM ruby:2.7.1-buster AS base

ENV APP_ROOT="/app"
ENV NODE_VERSION="11.0.0"
ENV YARN_VERSION="1.17.3"

# nodejs
FROM base as nodejs-installer
RUN curl --compressed "https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-x64.tar.xz" > /tmp/node.tar.xz && \
    tar -xJf /tmp/node.tar.xz -C /usr/local --strip-components=1 && \
    rm /tmp/node.tar.xz

# yarn
FROM base as yarn-installer
RUN curl -L --compressed "https://yarnpkg.com/downloads/${YARN_VERSION}/yarn-v${YARN_VERSION}.tar.gz" > /tmp/yarn.tar.gz && \
    tar -xzf /tmp/yarn.tar.gz -C /opt && \
    cp -a /opt/yarn-v${YARN_VERSION}/bin/* /usr/local/bin/ && \
    cp -a /opt/yarn-v${YARN_VERSION}/lib/* /usr/local/lib/

# rails bundle install & yarn build
FROM base AS bundle-installer

COPY --from=nodejs-installer /usr/local/bin/node /usr/local/bin/
COPY --from=yarn-installer /usr/local/bin/* /usr/local/bin/
COPY --from=yarn-installer /usr/local/lib/* /usr/local/lib/

WORKDIR $APP_ROOT

ADD Gemfile $APP_ROOT/Gemfile
ADD Gemfile.lock $APP_ROOT/Gemfile.lock
RUN bundle install

FROM base

EXPOSE 3000

RUN LANG=ja_JP.UTF-8
RUN ln -sf /usr/share/zoneinfo/Asia/Tokyo /etc/localtime

RUN --mount=type=cache,target=/var/cache/apt --mount=type=cache,target=/var/lib/apt \
      apt update \
      && apt upgrade -y \
      && apt install -y --no-install-recommends \
          git \
          openssh-client \
          make \
          gcc \
          default-libmysqlclient-dev \
          libxrender1

COPY --from=nodejs-installer /usr/local/bin/node /usr/local/bin/nodejs
COPY --from=yarn-installer /opt/yarn-v$YARN_VERSION/bin/yarn \
                           /opt/yarn-v$YARN_VERSION/bin/yarn.cmd \
                           /opt/yarn-v$YARN_VERSION/bin/yarnpkg \
                           /opt/yarn-v$YARN_VERSION/bin/yarnpkg.cmd \
                           /opt/yarn-v$YARN_VERSION/bin/yarn.js \
                           /usr/local/bin/
COPY --from=yarn-installer /opt/yarn-v$YARN_VERSION/lib/cli.js \
                           /opt/yarn-v$YARN_VERSION/lib/v8-compile-cache.js \
                           /usr/local/lib/
COPY --from=bundle-installer /usr/local/bundle /usr/local/bundle

ADD . $APP_ROOT

WORKDIR $APP_ROOT
RUN bundle exec rake webpacker:compile

CMD ["bundle", "exec", "rails", "server", "--binding=0.0.0.0"]