# 演習問題

以下の要件を満たす環境を後述されるステップに従い Ansible を使って自動化構築してください。

- `[app]` グループに所属する node4,5 で `httpd` をインストールして、起動状態にする
- httpd のトップページにはindex.htmlを配置し、httpd が起動するサーバーのIPアドレスが index.html に含まれる用にする
- `[other]` グループに所属する node6 には `nginx` をインストールして、起動状態にする。
- nginx はリバースプロキシとして動作し、http:/node6に アクセスされると node4, node5 の httpd にアクセスを振り分ける。


## ステップ1

下記の機能を持つロール `httpd_myip` 作成してください。

- ロールのディレクトリは `~/working/roles/httpd_myip` に配置します。
- このロールは httpd をインストールし、起動状態にします。
- トップページに index.html を配置し、このページは設定したホストのIPアドレスが表示されるように設定します。


## ステップ2

下記の機能を持つロール `nginx_lb` を作成してください。

- ロールのディレクトリは `~/working/roles/nginx_lb` に配置します。
- このロールは変数 `backend_server_list` に振り分け先のサーバーのリスト(node4,5)を取ります。
  - `backend_server_list` はデフォルト値は空リスト `[]` とします。
- このロールはサーバーに `nginx` をインストールし、以下の設定を行います。
- `backend_server_list` にセットされたIPアドレスのポート80へ、ロードバランサとして動作させます。

> ヒント
nginx は /etc/nginx/conf.d に設定ファイルを配置する。

例えば、以下のように /etc/nginx/conf.d/backend.conf を作成した場合、 http://lb_server へアクセスされると、backend にアクセスを転送する。backend は web_server1,2 で構成されており、デフォルトではラウンドロビンで振り分けが行われる。

```text
upstream backend {
  server web_server1;
  server web_server2;
}

server {
  listen 80;
  server_name lb_server;

  location / {
    proxy_pass http://backend;
  }
}
```

## ステップ3

下記の設定を行うPlaybook `~/working/lb_web.yml` を `httpd_myip` と `nginx_lb` ロールを使って作成してください。

- 演習環境3台を以下のように設定してください。
  - node4,5 に `httpd_myip` を適用してWEBサーバーとして設定する。
  - node6 に `nginx_lb` を適用してロードバランサとして設定する。
- ロードバランサは2台のWEBサーバーに対して負荷分散を行います。
  - ロードバランサにアクセスすると交互にWEBサーバーのページが表示される必要がある。

確認のためには、以下のコマンドを使ってください。

- `curl node4` → node4 のIPアドレスが表示されたトップページが表示されればOK
- `curl node5` → node5 のIPアドレスが表示されたトップページが表示されればOK
- `curl node6` → 実行するたびに node4,5 のトップページが交互に表示されればOK

サンプルの確認コマンド
```shell
for i in `seq 1 10`; do curl node6; done
```

## 解答例

- [httpd_myip](https://github.com/irixjp/aitac-automation/tree/main/101_ansible_basic/solutions/roles/httpd_myip)
- [nginx_lb](https://github.com/irixjp/aitac-automation/tree/main/101_ansible_basic/solutions/roles/nginx_lb)
- [lb_web.yml](https://github.com/irixjp/aitac-automation/blob/main/101_ansible_basic/solutions/lb_web.yml)
