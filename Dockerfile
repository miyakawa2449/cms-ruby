# syntax=docker/dockerfile:1
FROM ruby:3.4-slim

# 必要なパッケージのインストール
RUN apt-get update -qq && apt-get install -yq --no-install-recommends \
    build-essential \
    gnupg2 \
    less \
    git \
    libpq-dev \
    postgresql-client \
    libvips \
    curl \
    libjemalloc2 \
    libmagickwand-dev \
    imagemagick \
    nodejs \
    npm \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# jemalloc を使用してメモリ使用量を最適化
ENV LD_PRELOAD=/usr/lib/aarch64-linux-gnu/libjemalloc.so.2

# Node.js と Yarn をインストール（NodeSource リポジトリ経由）
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && \
    apt-get install -y nodejs && \
    npm install -g yarn && \
    rm -rf /var/lib/apt/lists/*

# アプリケーションディレクトリの作成
RUN mkdir /app
WORKDIR /app

# Ruby の依存関係をインストール
COPY Gemfile Gemfile.lock ./
RUN gem install bundler && \
    bundle config set --local deployment false && \
    bundle config set --local without 'development test' && \
    bundle install --jobs 4 --retry 3

# JavaScript の依存関係をインストール
COPY package.json yarn.lock ./
RUN yarn install --check-files

# アプリケーションコードをコピー
COPY . .

# bootsnap のプリコンパイル
RUN bundle exec bootsnap precompile --gemfile app/ lib/

# アセットのプリコンパイル（本番環境用）
# RUN SECRET_KEY_BASE_DUMMY=1 bundle exec rails assets:precompile

# エントリーポイントスクリプトの設定
COPY entrypoint.sh /usr/bin/
RUN chmod +x /usr/bin/entrypoint.sh
ENTRYPOINT ["entrypoint.sh"]

# Rails サーバーの起動
EXPOSE 3000
CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0"]