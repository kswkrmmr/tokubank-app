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

RUN yarn install

RUN echo "🔥 START CSS BUILD"
RUN yarn build:css
RUN echo "🔥 END CSS BUILD"
RUN cp app/assets/builds/application.css public/application.css

RUN ls -la app/assets/builds || true
RUN cat app/assets/builds/application.css || true

RUN bundle exec rails assets:precompile

EXPOSE 3000

CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0", "-p", "3000"]

#CMD ["bash", "-c", "bundle exec rails db:migrate && bundle exec rails server -b 0.0.0.0 -p 3000"]