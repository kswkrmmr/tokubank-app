FROM ruby:3.2

WORKDIR /app

ENV RAILS_ENV=production
ENV SECRET_KEY_BASE=dummy

RUN apt-get update -qq && apt-get install -y \
  build-essential \
  libpq-dev \
  nodejs \
  npm && \
  npm install -g yarn

# Gem
COPY Gemfile Gemfile.lock ./
RUN bundle install

# JS
COPY package.json yarn.lock ./
RUN yarn install

# App
COPY . .

# Build（ここが重要）
RUN yarn build
RUN yarn build:css
RUN echo "=== builds check ==="
RUN ls -la app/assets/builds
RUN echo "=== css content ==="
RUN cat app/assets/builds/application.css || echo "NO FILE"
RUN cp app/assets/builds/application.css public/application.css
RUN bundle exec rails assets:precompile

EXPOSE 3000

CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0", "-p", "3000"]

#CMD ["bash", "-c", "bundle exec rails db:migrate && bundle exec rails server -b 0.0.0.0 -p 3000"]