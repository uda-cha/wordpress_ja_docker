# uda-cha/wordpress_ja_docker

## これはなに？

以下のコンテナを組み合わせて、https対応の日本語版WordPressを構築するdocker-composeです。

- nginx
- php-fpm
- MySQL
- certbot

## 特徴

- [WordPress日本語版](https://ja.wordpress.org/about-wp-ja/)をphp-fpmのコンテナイメージでビルドしています。
- HTTP/2、およびTLS1.3に対応しています。
- https対応をdockerで完結させるために、初回起動時は自己証明書でnginxを起動し、その後にcertbotで証明書を発行し、自己証明書と入れ替える手法をとっています。
- データベースやWordPressコンテンツなどのデータはホスト側に永続化してあります。
- WordPressのテーマもホスト側に永続化しています。また、gitリポジトリに含めて管理することもできます。その場合、`.gitignore`の`wp-themes/*`をコメントアウトしてください。
- コンテナのログはdockerホストのjournaldへ飛ばす設定を行っています。

# 使い方

1. dockerをインストール
2. docker-composeをインストール
3. このリポジトリを`git clone`

```
$ git clone https://github.com/uda-cha/wordpress_ja_docker.git
```

4. nginxの設定ファイルを編集する

- `web/conf.d/default.conf.sample`を`web/conf.d/default.conf`にリネームして、WordPressの管理画面へのアクセスを許可するソースIPアドレスを追加する

```
geo $from {
    default         untrusted;
    127.0.0.1       trusted;
    192.168.0.0/16  trusted;
    172.16.0.0/12   trusted;
    10.0.0.0/8      trusted;
    8.8.8.8         trusted;  #追加例
}
```

- `web/conf.d/default.conf.sample`を`web/conf.d/default.conf`にリネームして、`server_name`に自分のFQDNを設定する(2箇所)

```
    server_name www.yourdomain.com;
```

5. `docker-compose.yml`を編集して、DB名、DB接続ユーザ名、パスワード、およびDBのrootパスワードを編集する

```
(~snip~)
  app:
    build: ./app
    environment:
        WORDPRESS_DB_HOST: db
        WORDPRESS_DB_USER: wpuser #任意のユーザ名に
        WORDPRESS_DB_PASSWORD: wpuserpasswd #任意のパスワードに
        WORDPRESS_DB_NAME: wpdb #任意のデータベース名に

  db:
    build: ./db
    environment:
        MYSQL_USER: wpuser #WORDPRESS_DB_USERと同じ値を設定する
        MYSQL_PASSWORD: wpuserpasswd #WORDPRESS_DB_PASSWORDと同じ値を設定する
        MYSQL_ROOT_PASSWORD: rootpasswd #変更しておく
        MYSQL_DATABASE: wpdb #WORDPRESS_DB_NAMEと合わせる
        TZ: Asia/Tokyo
(~snip~)
```

6. dockerイメージをビルドして起動する。certbotコンテナは終了コードが1になるが問題ない(docker-composeでcertbotを起動させる必要はありませんが、ネットワーク設定、マウント設定を容易にするためにdocker-compose.ymlに記載しています)

```
$ docker-compose build
$ docker-compose up -d
```

7. certbotコンテナを利用して証明書を発行する。`www.yourdomain.com`は自分のFQDNに変更する。メールアドレスを聞かれるので答える

```
$ docker-compose run --rm certbot certonly --agree-tos --webroot -w /var/www/certbot -d www.yourdomain.com
```

8. 証明書のシンボリックリンクを作成してnginxをリロードする。`www.yourdomain.com`は自分のFQDNに変更する。

```
$ docker-compose exec web ln -fs /etc/letsencrypt/live/www.yourdomain.com/fullchain.pem /etc/nginx/server.crt
$ docker-compose exec web ln -fs /etc/letsencrypt/live/www.yourdomain.com/privkey.pem /etc/nginx/server.key
$ docker-compose exec web nginx -s reload
```

## 運用

### 証明書の更新

certbotで証明書を更新し、nginxをリロードする。

```
$ docker-compose run --rm certbot renew --force-renew
$ docker-compose exec web nginx -s reload
```

### 各種バックアップ

#### WordPressコンテンツ

ホスト側から直接ファイルをバックアップします。
そのため、リストア時にコンテナ内からchownしてください。(www-data:www-data)

```
$ sudo tar cvfz docroot_bak.tar.gz -C /var/lib/docker/volumes/wordpress_ja_docker_docroot/_data . --exclude wp-content/themes
```

#### データベース

```
$ docker-compose exec db bash -c 'mysqldump -u$MYSQL_USER -p$MYSQL_PASSWORD --all-databases --events --opt 2>/dev/null' > dump.sql
```
