FROM ruby:3.1.3

# Install bundler
# Set LOCALE to UTF8
RUN mkdir /gems \
    && apt update -qq \
    && apt install -y postgresql-client libxml2 libpq-dev locales build-essential sudo vim iputils-ping tzdata \
    && rm -rf /var/lib/apt/lists/* \
    && gem install bundler:2.3.26 --no-document \
    && echo "en_US.UTF-8 UTF-8" > /etc/locale.gen \
    && locale-gen en_US.UTF-8 \
    && dpkg-reconfigure -f noninteractive locales \
    && /usr/sbin/update-locale LANG=en_US.UTF-8

ENV LC_ALL en_US.UTF-8

ENV PATH=/app/bin:$PATH
ENV BUNDLE_PATH "/gems"

WORKDIR /app

# Install gems
COPY Gemfile Gemfile.lock /app/
RUN bundle config set without 'development test' && bundle install --jobs 20 --retry 10
