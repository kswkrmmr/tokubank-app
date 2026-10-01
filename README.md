# 徳積み貯金

![トップ画面](app/assets/images/back.png)

## 概要
- 誰かのために行動をしてもお礼を言われることもない人のために、少しでも報われてほしいなと思い作りました。
- 良いことをしたら徳を登録し、ポイントを貯めれます。
- ポイントが貯まったら自分へのご褒美を叶えましょう。

## できること
- ユーザー登録・ログイン・ログアウト
- 徳の記録
- 徳の一覧表示（合計徳ポイント・今日の徳ポイントの表示）
- 登録済み徳の削除
- みんなの徳の閲覧（全ユーザーの合計・今日のポイントを表示）
- 他ユーザーの徳へのいいね

## 技術スタック
- Ruby on Rails 8.1 / Ruby 3.4
- PostgreSQL
- Bootstrap 5
- Docker / Render

## 今後の改善ポイント
- ご褒美登録・一覧・実行（徳ポイント消費）
- Xへの投稿

## 公開URL
- https://tokubank.onrender.com/

## 開発

### テストの実行

ローカルに Ruby を用意せず Docker で実行する。`Dockerfile.test` は system テスト用に Chromium を含む。

```sh
# 初回のみ
docker build -f Dockerfile.test -t tokubank-systest .
docker network create tb-net
docker volume create tokubank-bundle

# PostgreSQL を起動
docker run -d --name tb-pg --network tb-net \
  -e POSTGRES_USER=postgres -e POSTGRES_PASSWORD=postgres postgres:16

# テスト（system テストを含む）
docker run --rm --network tb-net \
  -v "$PWD":/myapp -v tokubank-bundle:/usr/local/bundle -w /myapp \
  -e RAILS_ENV=test -e DATABASE_URL=postgres://postgres:postgres@tb-pg:5432 \
  tokubank-systest bin/rails db:test:prepare test test:system
```

`bin/rubocop` と `bin/brakeman` も同じコンテナで実行できる（DB 不要）。

### テストが失敗したとき

`tmp/screenshots/` に3点が残る。CI も同じディレクトリを artifact として保存している。

| ファイル | 内容 |
|---|---|
| `failures_<テスト名>.png` | 失敗時の画面 |
| `failures_<テスト名>.html` | 失敗時の HTML |
| `failures_<テスト名>.console.log` | ブラウザのコンソールログ |

### 詰まりやすいところ

- **`public/assets` に古いプリコンパイル済みアセットが残っていると、test 環境ではそちらが配信される。** JS や CSS の変更が反映されないときは `rm -rf public/assets` する
- **gem を更新したら `bundle lock --add-checksums` を実行する。** コンテナ（arm64）で取得したチェックサムしか記録されず、CI（x86_64）の `bundle install` が frozen モードで失敗する
- 手元は Chromium（arm64）、CI は google-chrome-stable（x86_64）。バージョンは揃えているが環境は完全には一致しない
