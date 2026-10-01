FROM ruby:3.4.11

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

# jsbundling-rails / cssbundling-rails が assets:precompile に
# yarn build / yarn build:css を紐付けているため、個別の実行は不要。
# precompile 時だけダミー鍵を使う。ENV にすると実行時まで残り、
# 既知の鍵でセッション Cookie が署名されてしまうため、この RUN に限定する。
RUN SECRET_KEY_BASE_DUMMY=1 bundle exec rails assets:precompile

EXPOSE 3000

CMD ["bash", "-c", "bundle exec rails db:migrate && bundle exec rails server -b 0.0.0.0 -p 3000"]
