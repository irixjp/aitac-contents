# Collections

`Collection` は Galaxy の再利用の仕組みを更に一歩進めたものです。複数のロールやカスタムモジュールをまとめて管理し配布することが可能です。Ansible 2.9 以降(2.8から実験的には利用可能)で利用できます。従来は1ロール1リポジトリで管理していたものを、組織やチームで利用する共通機能をまとめて1リポジトリで管理できるようになります。

またAnsible 2.10 以降ではビルトインされていた大量のモジュールが分離され、Collection として必要に応じてダウンロードして利用する形式となっています。

## Collection の種類

Collection の種類は大きく分類すると以下のようになります。

- [Community Collections](https://docs.ansible.com/projects/ansible/latest/collections/index.html): 広く認知され活用されており、Ansible コミュニティからもリンクされている（認定等があるわけではない）。Galaxy からインストール可能。
- [Certified Collections](https://access.redhat.com/articles/ansible-automation-platform-certified-content): Red Hat 社によりサポートされるコレクション(Ansible Automation Platform を購入することで利用可能となる)。Automation Hub からインストール可能。
- [その他のCollections](https://galaxy.ansible.com/): 個人や企業によって開発された上記以外の膨大なコレクション。Galaxy や github 等からインストール可能。


## コマンドラインからのインストール

Collection を利用するには先ずインストールを行う必要があります。最も簡単な方法はコマンドラインを利用する方法です。

その前に、現在インストールされているコレクションを確認してみましょう。以下を実行します。

![run_command.png](https://raw.githubusercontent.com/irixjp/aitac-automation/main/101_ansible_basic/images/run_command.png)
`ansible-galaxy collection list`

```text
(省略)
# /student/.local/lib/python3.12/site-packages/ansible/_internal/ansible_collections
Collection                               Version
---------------------------------------- -------
ansible._protomatter                     *      

# /student/.local/lib/python3.12/site-packages/ansible_collections
Collection                               Version
---------------------------------------- -------
amazon.aws                               10.1.2 
ansible.netcommon                        8.1.0  
ansible.posix                            2.1.0  
ansible.utils                            6.0.0  
ansible.windows                          3.2.0 
```

既にいくつかのコレクションがインストールされていることが確認できるはずです。

> 演習環境にはあらかじめほとんど全てのコミュニティモジュールをインストールしてあります。

> Note: インストールされているコレクションやバージョンは環境によって異なる可能性がありますが演習には影響ありません。

> Note: コレクション名は `<namespace>.<collection_name>` という形式で表現されます。

この状態で利用可能なモジュールの数を確認しておきます。

![run_command.png](https://raw.githubusercontent.com/irixjp/aitac-automation/main/101_ansible_basic/images/run_command.png)
`ansible-doc -l | wc -l`

このコマンドで数字が表示されるので、その値をメモしていてください（警告が表示される場合もありますが無視してください）

ここに新たなコレクション [`oracle.oci`](https://galaxy.ansible.com/ui/repo/published/oracle/oci/) をインストールしてみます。これは Oracle 社のクラウドを操作するモジュール群を含んだコレクションです。

![run_command.png](https://raw.githubusercontent.com/irixjp/aitac-automation/main/101_ansible_basic/images/run_command.png)
`ansible-galaxy collection install oracle.oci`

```text
Starting galaxy collection install process
Process install dependency map
Starting collection install process
Downloading https://galaxy.ansible.com/api/v3/plugin/ansible/content/published/collections/artifacts/oracle-oci-5.5.0.tar.gz to /student/.ansible/tmp/ansible-local-138058vy0l03yx/tmpsz0svcds/oracle-oci-5.5.0-fm22uy4t
Installing 'oracle.oci:5.5.0' to '/student/.ansible/collections/ansible_collections/oracle/oci'
oracle.oci:5.5.0 was installed successfully
```

このコマンドを実行すると、デフォルトで `galaxy.ansible.com` へ接続してコレクションをダウンロードします。接続先を他のサイトへと変更することも可能です。またインストール時にはコレクションの依存関係を解決し、関連するコレクションも同時にインストールされます。

インストールされたコレクションを確認します。

![run_command.png](https://raw.githubusercontent.com/irixjp/aitac-automation/main/101_ansible_basic/images/run_command.png)
`ansible-galaxy collection list | grep oracle`

```text
oracle.oci                               5.5.0 
```

依存関係が解決されて、複数のコレクションがインストールされていることが確認できるはずです。

利用可能なモジュールが増えているはずです。確認しておきましょう。

![run_command.png](https://raw.githubusercontent.com/irixjp/aitac-automation/main/101_ansible_basic/images/run_command.png)
`ansible-doc -l | wc -l`

ダウンロードされたコレクションはデフォルトで `~/.ansible/collections/ansible_collections/` へと保存されます。

![run_command.png](https://raw.githubusercontent.com/irixjp/aitac-automation/main/101_ansible_basic/images/run_command.png)
`ls -alF ~/.ansible/collections/ansible_collections/`

```text
drwxr-xr-x. 4 student student 49 Dec  7 06:14 ./
drwxr-xr-x. 3 student student 33 Dec  7 06:14 ../
drwxr-xr-x. 3 student student 17 Dec  7 06:14 oracle/
drwxr-xr-x. 2 student student 24 Dec  7 06:14 oracle.oci-5.5.0.info/
```

インストール先を変える時にはオプション `-p` をつけてディレクトリを指定します。ただし、インストール後にコレクションを Playbook から参照するには [`COLLECTIONS_PATHS`](https://docs.ansible.com/projects/ansible/latest/reference_appendices/config.html#collections-paths) にそのディレクトリが含まれている必要があります。

アンインストールするコマンドはありませんので、コレクションを削除したい場合にはコレクションのディレクトリを削除します。

![run_command.png](https://raw.githubusercontent.com/irixjp/aitac-automation/main/101_ansible_basic/images/run_command.png)
`rm -rf ~/.ansible/collections/ansible_collections/oracle*`

削除されたか確認しておきます。

![run_command.png](https://raw.githubusercontent.com/irixjp/aitac-automation/main/101_ansible_basic/images/run_command.png)
`ansible-galaxy collection list | grep oracle`

利用可能なモジュール数も減っているはずです。

![run_command.png](https://raw.githubusercontent.com/irixjp/aitac-automation/main/101_ansible_basic/images/run_command.png)
`ansible-doc -l | wc -l`

> Note: コレクションのインストールにはコレクションのバージョンを指定することも可能です。インストール時に `<namespace>.<collection_name>:<version>` と指定します(バージョンを指定しなかった場合は最新版がインストールされます)

## requirements.yml からのインストール

ロールと同様にコレクションも `requirements.yml` を利用してインストールが可能です。自分のPlaybookで利用するコレクション(と必要に応じてバージョン)を列挙しておき、一括で取得します。

ここでは既に作成済みのサンプルコレクション [https://galaxy.ansible.com/irixjp/sample\_collection\_hello](https://galaxy.ansible.com/irixjp/sample_collection_hello) をインストールしてみます。このコレクション名は `irixjp.sample_collection_hello` です。オリジナルのソースコードは [github](https://github.com/irixjp/ansible-sample-collection-hello) に格納されています。

このコレクションは以下を含んでいます。

- role: hello
- role: uptime
- module: sample\_get\_hello

コレクションを利用するには、`requirements.yml` を作成します。

`~/working/collections/requirements.yml` を以下のように編集します。

![edit_file.png](https://raw.githubusercontent.com/irixjp/aitac-automation/main/101_ansible_basic/images/edit_file.png)
`~/working/collections/requirements.yml`
```yaml
---
collections:
- name: irixjp.sample_collection_hello
  version: 1.0.0
```

コレクションを取得するには以下を実行します。

![run_command.png](https://raw.githubusercontent.com/irixjp/aitac-automation/main/101_ansible_basic/images/run_command.png)
`cd ~/working`

![run_command.png](https://raw.githubusercontent.com/irixjp/aitac-automation/main/101_ansible_basic/images/run_command.png)
`ansible-galaxy collection install -r collections/requirements.yml`

![run_command.png](https://raw.githubusercontent.com/irixjp/aitac-automation/main/101_ansible_basic/images/run_command.png)
`ansible-galaxy collection list | grep sample_collection`

```text
irixjp.sample_collection_hello 1.0.0
```


取得したコレクションを利用する playbook を作成します。コレクションへのアクセスは以下の形式で行います。

`<namespace>.<collection_name>.<role or module name>`

この指定方法を FQCN (fully qualified collection name) と呼びます。

> Note: 過去のAnsibleバージョンにはコレクションという概念が存在しなかったため、`dnf` や `copy` のようにコレクション名を指定せずにモジュール名のみを指定してPlaybookを記述できました（現在でも互換性維持のために一部はモジュール名のみでも呼び出し可能になっています）。これはAnsible内部で過去のモジュール名が呼び出された際に自動的にFQCNへと変換するテーブル [plugin\_routing](https://github.com/ansible/ansible/blob/devel/lib/ansible/config/ansible_builtin_runtime.yml) が準備されているためです。そのため、このテーブルに存在しないモジュールの場合は FQCN でしか呼び出すことができないので、過去のバージョンを使っていた人は注意が必要です。

`~/working/collection_playbook.yml` を以下のように編集します。

![edit_file.png](https://raw.githubusercontent.com/irixjp/aitac-automation/main/101_ansible_basic/images/edit_file.png)
`~/working/collection_playbook.yml`
```yaml
---
- name: using collection
  hosts: node1
  tasks:
    - import_role:
        name: irixjp.sample_collection_hello.hello

    - import_role:
        name: irixjp.sample_collection_hello.uptime

    - name: get locale
      irixjp.sample_collection_hello.sample_get_locale:
      register: ret

    - debug: var=ret
```

実行結果を確認します。

![run_command.png](https://raw.githubusercontent.com/irixjp/aitac-automation/main/101_ansible_basic/images/run_command.png)
`ansible-playbook collection_playbook.yml`

```text
TASK [hello : say hello! (C)] **************
ok: [node1] => {
    "msg": "Hello"
}

TASK [uptime : get uptime] *****************
ok: [node1]

TASK [uptime : debug] **********************
ok: [node1] => {
    "msg": " 03:38:16 up 4 days, 23:01,  1 user,  load average: 0.16, 0.05, 0.06"
}

TASK [get locale] **************************
ok: [node1]

TASK [debug] *******************************
ok: [node1] => {
    "ret": {
        "changed": false,
        "failed": false,
        "locale": "C.UTF-8"
    }
}
```

コレクション内の各ロール、モジュールを呼出していることが確認できます。単体のロールをgalaxyでインストールした時と比べて、カスタムモジュールを単体で呼び出すことも可能になっており、更に利便性が向上します。

## 補足情報

必要に応じて以下も確認してください。

- より詳細な利用方法: [Using collections](https://docs.ansible.com/projects/ansible/latest/collections_guide/index.html)
- コレクションを作成する方法: [Developing collections](https://docs.ansible.com/projects/ansible/devel/dev_guide/developing_collections.html)

コマンドラインでは `ansible-galaxy collection install` をつど実行する必要がありますが、Ansible Automation Platform や AWX では playbook の実行前に自動的に `requirements.yml` から必要なコレクションをダウンロードする機能がありますので、更新し忘れといった事故を防止することが可能です。


## 演習の解答
---
- [collection\_playbook.yml](https://github.com/irixjp/aitac-automation/blob/main/101_ansible_basic/solutions/collection_playbook.yml)
- [collections/requirements.yml](https://github.com/irixjp/aitac-automation/blob/main/101_ansible_basic/solutions/collections/requirements.yml)
