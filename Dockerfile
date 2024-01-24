FROM ruby:3.2.3-alpine

RUN apk add --no-cache git build-base postgresql-dev curl-dev gcompat tzdata vips-dev

ENV BUNDLE_DEPLOYMENT=1 \
    BUNDLE_WITHOUT=development \
    BUNDLE_CACHE=/tmp/bundle \
    BUNDLE_JOBS=2 \
    PORT=8080 \
    RAILS_ENV=production

WORKDIR /rails
COPY Gemfile Gemfile.lock .tool-versions ./

RUN --mount=type=cache,id=gems,target=/tmp/bundle \
    bundle install

COPY . .

# Precompiling assets for production without requiring secret RAILS_MASTER_KEY
RUN bundle exec bootsnap precompile --gemfile app/ lib/
RUN SECRET_KEY_BASE_DUMMY=1 ./bin/rails assets:precompile

RUN adduser rails -D -h /rails -s /bin/sh && \
    chown -R rails:rails db log tmp bin && \
    chmod 755 /rails/bin/docker-entrypoint

USER rails:rails

ENTRYPOINT ["/rails/bin/docker-entrypoint"]
CMD ["bin/rails", "server", "-b", "0.0.0.0"]
