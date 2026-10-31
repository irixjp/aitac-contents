# Ansible の基礎、インベントリー、認証情報

Ansible の基本となるインベントリー(inventory)と認証情報(credential)について学習します。これは Ansible を動かす上で最低限準備する3つの情報のうちの2つに該当します。

![ansible_structure.png](https://raw.githubusercontent.com/irixjp/aitac-automation/main/101_ansible_basic/images/ansible_structure.png)

## 演習環境での Ansible の実行

まず以下のコマンドを実行してください。これは Ansible を使って演習ノードのディスク使用量を確認しています。

![run_command.png](https://raw.githubusercontent.com/irixjp/aitac-automation/main/101_ansible_basic/images/run_command.png)
`cd ~/`

![run_command.png](https://raw.githubusercontent.com/irixjp/aitac-automation/main/101_ansible_basic/images/run_command.png)
`ansible all -m shell -a 'df -h'`

```text
node1 | CHANGED | rc=0 >>
Filesystem      Size  Used Avail Use% Mounted on
devtmpfs        1.8G     0  1.8G   0% /dev/mem
tmpfs           360M  504K  359M   1% /etc/hosts
shm              63M     0   63M   0% /dev/shm
overlay          30G  5.0G   25G  17% /
tmpfs            64M     0   64M   0% /dev
tmpfs           1.8G   36K  1.8G   1% /run
tmpfs           1.8G  128K  1.8G   1% /tmp
tmpfs           1.8G     0  1.8G   0% /run/lock
tmpfs           1.8G   16M  1.8G   1% /var/log/journal

node2 | CHANGED | rc=0 >>
Filesystem      Size  Used Avail Use% Mounted on
devtmpfs        1.8G     0  1.8G   0% /dev/mem
tmpfs           360M  504K  359M   1% /etc/hosts
shm              63M     0   63M   0% /dev/shm
overlay          30G  5.0G   25G  17% /
tmpfs            64M     0   64M   0% /dev
tmpfs           1.8G   36K  1.8G   1% /run
tmpfs           1.8G  128K  1.8G   1% /tmp
tmpfs           1.8G     0  1.8G   0% /run/lock
tmpfs           1.8G   16M  1.8G   1% /var/log/journal
(省略)
```

> Note: 実際の出力内容と上記の出力例の差分は無視してください。重要なのは `df -h` が実行されたということです。

> Note: `df` コマンドはサーバー上のディスクの使用状態を取得します。

これで複数のサーバーからディスク使用量の情報が取得できました。しかし、このサーバーはどのように決定されたのでしょうか。もちろんこれは演習用に予め設定されているものですが、その情報は Ansible のどこに設定されているか疑問を持つ方もいるはずです。今からその設定について確認していきます。

## ansible.cfg

まず以下のコマンドを実行します。

![run_command.png](https://raw.githubusercontent.com/irixjp/aitac-automation/main/101_ansible_basic/images/run_command.png)
`ansible --version`

```text
ansible [core 2.20.0]
  config file = /student/.ansible.cfg
  configured module search path = ['/student/.ansible/plugins/modules', '/usr/share/ansible/plugins/modules']
  ansible python module location = /student/.local/lib/python3.12/site-packages/ansible
  ansible collection location = /student/.ansible/collections:/usr/share/ansible/collections
  executable location = /student/.local/bin/ansible
  python version = 3.12.11 (main, Aug 14 2025, 00:00:00) [GCC 14.3.1 20250617 (Red Hat 14.3.1-2)] (/usr/bin/python3)
  jinja version = 3.1.6
  pyyaml version = 6.0.3 (with libyaml v0.2.5)
```

> Note: 出力内容は環境によって異なる場合があります。

ansible コマンドに `--version` オプションをつけると、実行環境に関する基本的な情報が出力されます。バージョンや利用している Python のバージョンなどです。ここでは以下の行に注目します。

- `config file = /student/.ansible.cfg`

これは、このディレクトリで ansible コマンドを実行した際に読み込まれる Ansible の設定ファイルのパスを表示しています。このファイルは Ansible の基本的な挙動を制御するための設定ファイルです。

「このディレクトリで実行したとき」という表現をつけましたが、 Ansible は ansible.cfg を検索する順番が決まっています。詳細は [Ansible Configuration Settings](https://docs.ansible.com/ansible/latest/reference_appendices/config.html#the-configuration-file) に記載されています。

簡単に説明すると、ansible.cfg は環境変数 `ANSIBLE_CONFIG` で与えられたパス、現在のディレクトリ、ホームディレクトリ、OS全体の共通パスという順序で検索されます。今回の演習環境ではホームディレクトリの `~/.ansible.cfg` が最初に見つかるため、このファイルが利用されています。

この中身を確認してみましょう。

![run_command.png](https://raw.githubusercontent.com/irixjp/aitac-automation/main/101_ansible_basic/images/run_command.png)
`cat ~/.ansible.cfg`

```ini
[defaults]
interpreter_python   = /usr/bin/python3
deprecation_warnings = False
host_key_checking    = False
force_color          = True
forks                = 2
inventory            = /student/inventory

[ssh_connection]
ssh_args = -o ControlMaster=auto -o ControlPersist=60s -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null
```

いくつかの設定が演習用に設定されています。ここで重要となるのが以下の設定です。

- `inventory            = /student/inventory`

これは、Ansible が自動化の実行対象を決定する「インベントリー」に関する設定です。

次のこの設定について詳しくみていきましょう。

## インベントリー

インベントリーは Ansible が自動化の実行対象を決定するための機能です。ファイルの中身を確認してみましょう。

![run_command.png](https://raw.githubusercontent.com/irixjp/aitac-automation/main/101_ansible_basic/images/run_command.png)
`cat ~/inventory`

```text
[web]
node1 ansible_host=172.22.22.101
node2 ansible_host=172.22.22.102
node3 ansible_host=172.22.22.103

[app]
node4 ansible_host=172.22.22.104
node5 ansible_host=172.22.22.105

[other]
node6 ansible_host=172.22.22.106

[all:vars]
ansible_user=student
ansible_ssh_private_key_file=/student/id_rsa_podman
```

このインベントリーは `ini` ファイル形式で記述されています。他にも `YAML` 形式や、スクリプトで動的にインベントリーを構成する `ダイナミックインベントリー` という仕組みもサポートされています。詳細は [How to build your inventory](https://docs.ansible.com/ansible/latest/user_guide/intro_inventory.html) を確認してください。

このインベントリーファイルは以下のルールで記述されています。

- `node1` `node2` のように1行1ノードで情報を記述します。
  - ノード行は `ノードの識別子(node1)`、ノードに与える`ホスト変数(複数可) (ansible_host=xxxx)` から構成されます。
  - `node1` の部分にはIPアドレスやFQDNを指定することも可能です。
- `[web]` でホストのグループを作ることができます。ここでは `web` というグループが作られます。
  - グループ名は `all` と `localhost` 以外の名前を自由に使用できます。
  - 演習環境では`[web]` `[app]` `[other]` の3つのグループが構成されています。
- `[all:vars]` では、`all` という特別なグループ名に対して `グループ変数` を定義しています。
  - `all` は特別なグループで、インベントリーに記述された全ノードを指し示すグループです。
  - ここで与えられている、 `ansible_user` `ansible_ssh_private_key_file` は特別な変数で、各ノードへのログインに使われるユーザー名とSSH秘密鍵のパスを示しています。
    - `ansible_xxxx` という[マジック変数](https://docs.ansible.com/ansible/latest/reference_appendices/special_variables.html)で、Ansible の挙動を制御したり、Ansible が自動的に取得する環境情報など特別な値が格納されています。詳細は変数の項目で解説します。

実際にこのインベントリーを利用して定義されたノードへ対して Ansible を実行してみます。以下のコマンドを実行してください。

![run_command.png](https://raw.githubusercontent.com/irixjp/aitac-automation/main/101_ansible_basic/images/run_command.png)
`ansible web -i ~/inventory -m ping -o`

```text
node1 | SUCCESS => {"changed": false,"ping": "pong"}
node2 | SUCCESS => {"changed": false,"ping": "pong"}
node3 | SUCCESS => {"changed": false,"ping": "pong"}
```

このコマンドのオプションの意味は以下になります。

- `web`: インベントリー内のグループを指定しています。
- `-i ~/inventory`: 利用するインベントリーファイルを指定します。
- `-m ping`: モジュール `ping` を実行します。モジュールに関しての詳細は後述します。
- `-o`: 出力を1ノード1行にまとめます。

今回の環境では、 `ansible.cfg` ファイルによって、デフォルトのインベントリーが指定されているため、以下のように `-i ~/inventory` を省略することが可能です。

![run_command.png](https://raw.githubusercontent.com/irixjp/aitac-automation/main/101_ansible_basic/images/run_command.png)
`ansible web -m ping -o`

```text
node1 | SUCCESS => {"changed": false,"ping": "pong"}
node2 | SUCCESS => {"changed": false,"ping": "pong"}
node3 | SUCCESS => {"changed": false,"ping": "pong"}
```

> Note: 以降の演習ではインベントリーの指定を省略します。

グループ名の代わりにノード名を指定することも可能です。

![run_command.png](https://raw.githubusercontent.com/irixjp/aitac-automation/main/101_ansible_basic/images/run_command.png)
`ansible node1 -m ping -o`

```text
node1 | SUCCESS => {"changed": false,"ping": "pong"}
```

複数のノードを指定することも可能です。

![run_command.png](https://raw.githubusercontent.com/irixjp/aitac-automation/main/101_ansible_basic/images/run_command.png)
`ansible node1,node3 -m ping -o`

```text
node1 | SUCCESS => {"changed": false,"ping": "pong"}
node3 | SUCCESS => {"changed": false,"ping": "pong"}
```

別のグループを指定することも可能です。

![run_command.png](https://raw.githubusercontent.com/irixjp/aitac-automation/main/101_ansible_basic/images/run_command.png)
`ansible app -m ping -o`

```text
node4 | SUCCESS => {"changed": false,"ping": "pong"}
node5 | SUCCESS => {"changed": false,"ping": "pong"}
```

特別なグループである `all` を指定してみます。`all` はインベントリーに含まれる全てのノードを対象とします。今回のインベントリーは `all` と `web` のグループが同じものを指しているため、結果も同じになります。

![run_command.png](https://raw.githubusercontent.com/irixjp/aitac-automation/main/101_ansible_basic/images/run_command.png)
`ansible all -m ping -o`

```text
node2 | SUCCESS => {"changed": false,"ping": "pong"}
node1 | SUCCESS => {"changed": false,"ping": "pong"}
node3 | SUCCESS => {"changed": false,"ping": "pong"}
node4 | SUCCESS => {"changed": false,"ping": "pong"}
node5 | SUCCESS => {"changed": false,"ping": "pong"}
node6 | SUCCESS => {"changed": false,"ping": "pong"}
```

> Note: 結果が表示される順番は決まっていません。Ansibleは複数台に対して並行して処理を実施するので、早く終わったサーバーほど先頭に表示されます。

ここまでの例では指定したグループに対して Ansible が何らかの処理(この場合は ping)を実行していますが、処理を行わずに対象のノードのみを確認するこも可能です。その場合は `--list-hosts` オプションを使います。

![run_command.png](https://raw.githubusercontent.com/irixjp/aitac-automation/main/101_ansible_basic/images/run_command.png)
`ansible web --list-hosts`

```text
  hosts (3):
    node1
    node2
    node3
```

![run_command.png](https://raw.githubusercontent.com/irixjp/aitac-automation/main/101_ansible_basic/images/run_command.png)
`ansible app --list-hosts`

```text
  hosts (2):
    node4
    node5
```


## 認証情報

上記のインベントリーの確認では、サーバーに対して `ping` モジュールを実行しました。このモジュールは実際にノードに対してログインを行い、Ansible が実行可能な状態かを調べています。このときにログインに使われる Credential (認証情報) について見ていきます。

> Note: ネットワークで利用するICMPを送信する ping コマンドとは完全に異なるものです。Ansibleの文脈での `ping` を実行しています。

今回の演習環境では、先に見たインベントリーの中で認証情報が指定されています。以下が抜粋となります。

```ini
[all:vars]
ansible_user=student
ansible_ssh_private_key_file=/student/id_rsa_podman
```

ここでは、全てのグループに対する変数として `[all:vars]` を定義し、そこで認証に利用する変数を定義しています。

- `ansible_user`: Ansible がログインに利用するユーザー名を指定する。
- `ansible_ssh_private_key_file`: Ansible がログインに利用する秘密鍵を指定する。

今回の演習では秘密鍵を用いていますが、ログインにパスワードを指定することも可能です。

- `ansible_password`: Ansible がログインに使用するパスワードを指定する。

この他にも認証情報を与える方法がいくつか提供されいます。代表的なものとしてコマンドラインのオプションとして与える方法があります。

![run_command.png](https://raw.githubusercontent.com/irixjp/aitac-automation/main/101_ansible_basic/images/run_command.png)
`ansible all -u student --private-key ~/id_rsa_podman -m ping`

- `-u student`: ログインに使用するユーザー名を指定できます。
- `--private-key`: ログインに使用する秘密鍵を指定できます。

パスワードを使用する方法もあります。以下がサンプルになります。

```text
$ ansible all -u student -k -m ping -o
SSH password:  ← ここでパスワード入力を求められる
node1 | SUCCESS => {"changed": false,"ping": "pong"}
node2 | SUCCESS => {"changed": false,"ping": "pong"}
node3 | SUCCESS => {"changed": false,"ping": "pong"}
node4 | SUCCESS => {"changed": false,"ping": "pong"}
node6 | SUCCESS => {"changed": false,"ping": "pong"}
node5 | SUCCESS => {"changed": false,"ping": "pong"}
```

> Note: 本演習環境ではパスワードは設定されていませんが、インベントリーファイルに秘密鍵が設定されているため、鍵認証が優先されて誤ったパスワードを入力しても操作は成功します。

- `-k`: コマンド実行時に、パスワード入力のプロンプトを出す。

Ansible に認証情報を渡す仕組みは、他にもいくつかの方法があります。本演習では最もベーシックでお手軽な手段(変数で直接指定)を用いていますが、実際に本番で利用する際には、認証情報をどう扱うかは事前に熟慮が必要です。当然ですが、ファイルに直接書かれた認証情報はそのファイルにアクセスできる全ての人が別の用途（不正にサーバーを操作するなど）で利用できてしまうためです。

> Note: 上記に合わせて、サーバーやネットワーク機器のログインにユーザー名とパスワードを用いる方法は現代ではセキュリティの観点から推奨されません。Ansible を利用する場合も鍵認証を行うことが推奨です。

秘密情報の管理を厳格化する必要がある場合には [Ansible Automation Platform](https://www.redhat.com/ja/technologies/management/ansible) や [AWX](https://github.com/ansible/awx) 等の自動化プラットフォームソフトウェアと組み合わせて使う方法が採用されます。
