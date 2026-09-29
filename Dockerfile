FROM ruby:3.2

WORKDIR /app

ENV RAILS_ENV=production

RUN apt-get update -qq && apt-get install -y \
  build-essential \
  libpq-dev \
  nodejs \
  npm && \
  npm install -g yarn

COPY Gemfile Gemfile.lock ./
RUN bundle install

COPY package.json yarn.lock ./
RUN yarn install

COPY . .

RUN echo "🔥 START CSS BUILD"
RUN yarn build:css
RUN echo "🔥 END CSS BUILD"

RUN cp app/assets/builds/application.css public/application.css

RUN ls -la public
RUN head -n 20 public/application.css || true

# precompile 時だけダミー鍵を使う。ENV にすると実行時まで残り、
# 既知の鍵でセッション Cookie が署名されてしまうため、この RUN に限定する。
RUN SECRET_KEY_BASE_DUMMY=1 bundle exec rails assets:precompile

EXPOSE 3000

CMD ["bash", "-c", "bundle exec rails db:migrate && bundle exec rails server -b 0.0.0.0 -p 3000"]