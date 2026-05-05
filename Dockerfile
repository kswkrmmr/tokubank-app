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

# CSS build（ここが最重要）
RUN echo "🔥 START CSS BUILD"
RUN yarn build:css
RUN echo "🔥 END CSS BUILD"

# publicにコピー（今回はこれでOK）
RUN cp app/assets/builds/application.css public/application.css

# 確認
RUN ls -la public
RUN head -n 20 public/application.css || true

EXPOSE 3000

# DB migrateもちゃんとやる
CMD ["bash", "-c", "bundle exec rails db:migrate && bundle exec rails server -b 0.0.0.0 -p 3000"]