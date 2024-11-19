# syntax = docker/dockerfile:1

### START of FLY ####

# Make sure RUBY_VERSION matches the Ruby version in .ruby-version and Gemfile
ARG RUBY_VERSION=3.3.5
FROM quay.io/evl.ms/fullstaq-ruby:${RUBY_VERSION}-jemalloc-slim as base-for-fly

LABEL fly_launch_runtime="rails"

# Rails app lives here
WORKDIR /rails

# Set production environment
ENV BUNDLE_DEPLOYMENT="1" \
    BUNDLE_PATH="/usr/local/bundle" \
    BUNDLE_WITHOUT="development:test" \
    RAILS_ENV="production"

# Update gems and bundler
RUN gem update --system --no-document && \
    gem install -N bundler


# Throw-away build stage to reduce size of final image
FROM base-for-fly as build

# Install packages needed to build gems
RUN --mount=type=cache,id=dev-apt-cache,sharing=locked,target=/var/cache/apt \
    --mount=type=cache,id=dev-apt-lib,sharing=locked,target=/var/lib/apt \
    apt-get update -qq && \
    apt-get install --no-install-recommends -y git build-essential libpq-dev libvips libyaml-dev

# Install application gems
COPY --link Gemfile Gemfile.lock .ruby-version ./
RUN --mount=type=cache,id=bld-gem-cache,sharing=locked,target=/srv/vendor \
    bundle config set app_config .bundle && \
    bundle config set path /srv/vendor && \
    bundle install && \
    bundle exec bootsnap precompile --gemfile && \
    bundle clean && \
    mkdir -p vendor && \
    bundle config set path vendor && \
    cp -ar /srv/vendor .

# Copy application code
COPY --link . .

# Precompile bootsnap code for faster boot times
RUN bundle exec bootsnap precompile app/ lib/

# Adjust binfiles to set current working directory
RUN grep -l '#!/usr/bin/env ruby' /rails/bin/* | xargs sed -i '/^#!/aDir.chdir File.expand_path("..", __dir__)'

# Precompiling assets for production without requiring secret RAILS_MASTER_KEY
RUN SECRET_KEY_BASE_DUMMY=1 ./bin/rails assets:precompile


# Final stage for app image
FROM base-for-fly AS fly-production

# Install packages needed for deployment
RUN --mount=type=cache,id=dev-apt-cache,sharing=locked,target=/var/cache/apt \
    --mount=type=cache,id=dev-apt-lib,sharing=locked,target=/var/lib/apt \
    apt-get update -qq && \
    apt-get install --no-install-recommends -y curl imagemagick libvips postgresql-client

# Copy built artifacts: gems, application
COPY --from=build "${BUNDLE_PATH}" "${BUNDLE_PATH}"
COPY --from=build /rails /rails

# Run and own only the runtime files as a non-root user for security
RUN groupadd --system --gid 1000 rails && \
    useradd rails --uid 1000 --gid 1000 --create-home --shell /bin/bash && \
    chown -R 1000:1000 db log storage tmp
USER 1000:1000

# Deployment options
ENV RUBY_YJIT_ENABLE="1"

# Entrypoint sets up the container.
ENTRYPOINT ["/rails/bin/docker-entrypoint"]

# Start the server by default, this can be overwritten at runtime
EXPOSE 3000

#### END of FLY ####

#### START of POSTGRES ####
FROM postgres:16 as postgres-development

RUN mkdir -p /docker-entrypoint-initdb.d
WORKDIR /docker-entrypoint-initdb.d

RUN touch 01-create-rails-user.sh
RUN echo "#!/bin/bash" >> 01-create-rails-user.sh
RUN echo "set -e" >> 01-create-rails-user.sh
# the script uses the DATABASE_URL env var (if set)
# to extract the username and password and set HOSTEDGPT_DB_USERNAME and HOSTEDGPT_DB_PASSWORD
# if DATABASE_URL is not set, it uses the existing HOSTEDGPT_DB_USERNAME and HOSTEDGPT_DB_PASSWORD
# to create the rails user
RUN echo "if [ -n \"\$DATABASE_URL\" ]; then" >> 01-create-rails-user.sh
RUN echo "	echo \"DATABASE_URL is set, using it to extract username and password\"" >> 01-create-rails-user.sh
RUN echo "	HOSTEDGPT_DB_USERNAME=\"\$(echo \$DATABASE_URL | sed -n 's|.*://\([^:]*\):.*|\\\\1|p')\"" >> 01-create-rails-user.sh
RUN echo "	HOSTEDGPT_DB_PASSWORD=\"\$(echo \$DATABASE_URL | sed -n 's|.*://[^:]*:\([^@]*\)@.*|\\\\1|p')\"" >> 01-create-rails-user.sh
RUN echo "fi" >> 01-create-rails-user.sh

RUN echo "echo \"creating user \$HOSTEDGPT_DB_USERNAME\"" >> 01-create-rails-user.sh
RUN echo "psql -v ON_ERROR_STOP=1 --username \"\$POSTGRES_USER\" <<-EOSQL" >> 01-create-rails-user.sh
RUN echo "	CREATE USER \$HOSTEDGPT_DB_USERNAME WITH SUPERUSER PASSWORD '\$HOSTEDGPT_DB_PASSWORD';" >> 01-create-rails-user.sh
RUN echo "EOSQL" >> 01-create-rails-user.sh

WORKDIR /

#### END of POSTGRES ####

#### START of DEV ####

# RUBY_VERSION is the only thing used from anything above
FROM ruby:${RUBY_VERSION}-alpine AS development

RUN apk add --no-cache bash git build-base postgresql-dev curl-dev gcompat tzdata vips-dev imagemagick

ENV BUNDLE_CACHE=/tmp/bundle \
  BUNDLE_JOBS=2 \
  PORT=3000

WORKDIR /rails
COPY Gemfile Gemfile.lock .ruby-version ./

RUN --mount=type=cache,id=gems,target=/tmp/bundle \
  bundle install

RUN apk add --no-cache postgresql-client

ENTRYPOINT ["/rails/bin/docker-entrypoint"]
CMD ["./bin/dev"]

#### END of DEV ####

#### START of RENDER ####
# Render must be last because render.yml cannot specify a build target so it default to the last one
# RUBY_VERSION is the only thing used from anything above
FROM ruby:${RUBY_VERSION}-alpine AS render-production

RUN apk add --no-cache git build-base postgresql-dev curl-dev gcompat tzdata vips-dev imagemagick

WORKDIR /rails
COPY Gemfile Gemfile.lock .ruby-version ./

ENV BUNDLE_CACHE=/tmp/bundle \
  BUNDLE_JOBS=2 \
  BUNDLE_DEPLOYMENT=1 \
  BUNDLE_WITHOUT=development \
  RAILS_ENV=production \
  PORT=8080

RUN --mount=type=cache,id=gems,target=/tmp/bundle \
  bundle install

COPY . .

# Precompiling assets for production without requiring secret RAILS_MASTER_KEY
RUN bundle exec bootsnap precompile --gemfile app/ lib/
RUN SECRET_KEY_BASE_DUMMY=1 ./bin/rails assets:precompile

RUN mkdir -p log tmp bin

RUN adduser rails -D -h /rails -s /bin/sh && \
  chown -R rails:rails db log tmp bin && \
  chmod 755 /rails/bin/docker-entrypoint

USER rails:rails

ENTRYPOINT ["/rails/bin/docker-entrypoint"]
CMD ["./bin/rails", "server", "-b", "0.0.0.0"]

#### END of RENDER ####
