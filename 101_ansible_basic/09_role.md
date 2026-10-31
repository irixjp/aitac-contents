# Role による部品化

これまでは playbook に直接モジュールを列挙してきました。この方法でも Ansible の自動化は可能ですが、実際に Ansible を使っていくと、以前の処理を再利用したくなるケースに多々遭遇します。その際に以前のコードをコピー＆ペーストするのは効率が悪いですし、かといって別の playbook 全体を呼び出そうすると `hosts:` に書かれたグループ名とインベントリーの整合性が取れずうまく動作しないことがほとんどです。そこで登場するのが以下の図の `Role` という考え方です。

![ansible_structure.png](https://raw.githubusercontent.com/irixjp/aitac-automation/main/101_ansible_basic/images/ansible_structure.png)

様々な作業単位で自動化をパーツ化して再利用可能な部品とすることができます。[Role](https://docs.ansible.com/projects/ansible/latest/playbook_guide/playbooks_reuse_roles.html) は完全にインベントリーと切り離されており、様々な playbook から呼び出して利用することが可能です。

> Note: モジュールはインフラでよく発生する作業を部品化したものですが、ロールは「自分の組織やプロジェクトでよく発生する手順」をまとめた部品だと言うことができます。


## Role の構造

`Role` はディレクトリ内に予め決められた構成でファイルを配置して利用します。するとそのディレクトリが `Role` として Ansible から呼び出せるようになります。

代表的なロール構造を以下に掲載します。

```text
site.yml        # 呼び出し元のplaybook
roles/          # playbook と同じ階層の roles ディレクトリに
                # ロールが格納されていると Ansible が判断します。 
  your_role/    # your_role という role を格納するディレクトリ
                # (ディレクトリ名 = role 名となります)
    tasks/      #
      main.yml  #  ロールの中で実行するタスクを記述します。
    handlers/   #
      main.yml  #  ロールの中で使用するハンドラーを記述します。
    templates/  #
      ntp.conf.j2  # ロールで利用するテンプレートを配置します。
    files/      #
      bar.txt   #  ロールの中で利用するファイルを配置します。
      foo.sh    #
    defaults/   #
      main.yml  #  ロールの中で利用する変数の一覧と
                #  デフォルト値を記述します。
  your_2nd_role/   # your_2nd_role というロールになります。
```

上記のようなディレクトリ構造を作った時に、`site.yml` では以下のようにロールを呼び出すことができます。


```yaml
---
- hosts: all
  tasks:
  - ansible.builtin.import_role:
      name: your_role

  - ansible.builtin.include_role:
      name: your_2nd_role
```

このように `ansible.builtin.import_role`  `ansible.builtin.include_role` というモジュールを使ってロールの名前を指定するだけで処理が呼びだせるようになります。この2つのモジュールは両方ともロールを呼出しますが、違いは以下です。

- [`ansible.builtin.import_role`](https://docs.ansible.com/projects/ansible/latest/collections/ansible/builtin/import_role_module.html) playbook の実行前にロールを読み込む（先読み）
- [`ansible.builtin.include_role`](https://docs.ansible.com/projects/ansible/latest/collections/ansible/builtin/include_role_module.html) タスクの実行時にロールが読み込まれる（後読み）

> Note: 現時点でこの2つの使い分けは意識する必要はありません。基本的には `import_role` を使う方が安全でシンプルです。`include_role` は処理によって呼び出すロールを動的に変更するような、複雑な処理を記述する際に利用します。

手順の部分はRoleとして部品化して自動化の対象とは切り離して管理し、Playbookではどのホストグループにどのロールを順番に適用するかを管理します。このように何をどのような順番でといったロジック部分と、自動化の適用先という異なる情報を別々のファイルで管理することで、再利用性を高めて自動化の開発効率を上げることが可能です。


## Role の作成

実際にロールを作成してみます。と言っても難しいことはありません。今まで書いた処理を決められたディレクトリに分割していくだけです。

今回の演習ではWebサーバーを設定する `web_setup` ロールを作成します。以下のようなディレクトリ構造になります。

```text
role_playbook.yml     # 実際にロールを呼び出す playbook
roles
└── web_setup              # ロール名
    ├── defaults
    │   └── main.yml       # 変数のデフォルト値を格納
    ├── files
    │   └── httpd.conf     # 配布するファイルを格納
    ├── handlers
    │   └── main.yml       # ハンドラーを定義
    ├── tasks
    │   └── main.yml       # タスクを記述
    └── templates
        └── index.html.j2  # テンプレートファイルを配置
```

各ファイルを作成していきます。

### 🔸タスクファイルの作成

`~/working/roles/web_setup/tasks/main.yml` を編集

![edit_file.png](https://raw.githubusercontent.com/irixjp/aitac-automation/main/101_ansible_basic/images/edit_file.png)
`~/working/roles/web_setup/tasks/main.yml`
```yaml
---
- name: install httpd
  ansible.builtin.dnf:
    name: httpd
    state: latest

- name: start & enabled httpd
  ansible.builtin.service:
    name: httpd
    state: started
    enabled: yes

- name: Put index.html from template
  ansible.builtin.template:
    src: index.html.j2
    dest: /var/www/html/index.html

- name: Copy Apache configuration file
  ansible.builtin.copy:
    src: httpd.conf
    dest: /etc/httpd/conf/
  notify:
    - restart_apache
```

`tasks` ディレクトリには実行したいタスクのみを配置します。
またロールには `play` パートを記述する必要はありませんのでタスクのみを列挙していきます。ロール内の `ansible.builtin.templates` `ansible.builtin.files` ディレクトリは、明示的にパスを指定しなくてもモジュールからファイル名だけで参照できるようになっています。そのため、`ansible.builtin.copy` と `ansible.builtin.template` モジュールの `src` にはファイル名しか記述されていません。


### 🔸ハンドラーファイルの作成

`~/working/roles/web_setup/handlers/main.yml` を編集。

![edit_file.png](https://raw.githubusercontent.com/irixjp/aitac-automation/main/101_ansible_basic/images/edit_file.png)
`~/working/roles/web_setup/handlers/main.yml`
```yaml
---
- name: restart_apache
  ansible.builtin.service:
    name: httpd
    state: restarted
```

`handlers` ディレクトリにはハンドラーとして呼び出したい処理のみを配置します。

### 🔸デフォルト変数の作成

`~/working/roles/web_setup/defaults/main.yml` の編集

![edit_file.png](https://raw.githubusercontent.com/irixjp/aitac-automation/main/101_ansible_basic/images/edit_file.png)
`~/working/roles/web_setup/defaults/main.yml`
```yaml
---
LANG: JP
```

`defaults` にはこのRoleの内で利用する変数のデフォルト値を配置します。Roleのデフォルト変数は上書き優先順位が低いため、呼び出したPlaybook側で上書きして実行することも可能です。また、この変数はRoleが呼び出されるとPlaybook全体から参照できる値となるため、変数名の重複には注意しましょう。

> Note: 一般的にRole内で利用する変数名にはプリフィックスとしてRole名をつけることが多い。

### 🔸テンプレートファイルの作成

`~/working/roles/web_setup/templates/index.html.j2` の編集

![edit_file.png](https://raw.githubusercontent.com/irixjp/aitac-automation/main/101_ansible_basic/images/edit_file.png)
`~/working/roles/web_setup/templates/index.html.j2`
```jinja2
<html><body>
<h1>This server is running on {{ inventory_hostname }}.</h1>

!Created with Ansible Role!

{% if LANG == "JP" %}
     Konnichiwa!
{% else %}
     Hello!
{% endif %}
</body></html>
```

`templates` には `template` モジュールが利用するテンプレートファイルを配置します。ここに配置したファイルは、Role内で呼び出される特定のモジュールからファイル名のみでアクセスできるようになります。

### 🔸配布ファイルの作成

`~/working/roles/web_setup/files/httpd.conf` の編集

このファイルはサーバー側から取得します。以下のようにコマンドを実行してファイルを取得した後にファイルを編集してください。

![run_command.png](https://raw.githubusercontent.com/irixjp/aitac-automation/main/101_ansible_basic/images/run_command.png)
`cd ~/working/roles/web_setup`

![run_command.png](https://raw.githubusercontent.com/irixjp/aitac-automation/main/101_ansible_basic/images/run_command.png)
`ansible node1 -b -m ansible.builtin.dnf -a 'name=httpd state=latest'`

![run_command.png](https://raw.githubusercontent.com/irixjp/aitac-automation/main/101_ansible_basic/images/run_command.png)
`ansible node1 -m ansible.builtin.fetch -a 'src=/etc/httpd/conf/httpd.conf dest=files/httpd.conf flat=yes'`

ファイルが取得できていることを確認します。

![run_command.png](https://raw.githubusercontent.com/irixjp/aitac-automation/main/101_ansible_basic/images/run_command.png)
`ls -l files/`

ファイルの中身を編集します。演習の進み方によっては既に編集済みの場合もありますのでその場合はそのままにしてください。

![edit_file.png](https://raw.githubusercontent.com/irixjp/aitac-automation/main/101_ansible_basic/images/edit_file.png)
`~/working/roles/web_setup/files/httpd.conf`
```
ServerAdmin root@localhost
      ↓
ServerAdmin centos_role@localhost
```

`files` にはRoleで配布等に利用するファイルを配置します。このディレクトリもRole内から特定のモジュールがファイル名のみでアクセスできるようになります。


### 🔸playbook の作成

`~/working/role_playbook.yml` の編集

実際にロールを呼び出す playbook を作成します。

![edit_file.png](https://raw.githubusercontent.com/irixjp/aitac-automation/main/101_ansible_basic/images/edit_file.png)
`~/working/role_playbook.yml`
```yaml
---
- name: using role
  hosts: web
  become: yes
  tasks:
    - ansible.builtin.import_role:
        name: web_setup
```

### 🔸全体の確認

作成したロールを確認します。

![run_command.png](https://raw.githubusercontent.com/irixjp/aitac-automation/main/101_ansible_basic/images/run_command.png)
`cd ~/working`

![run_command.png](https://raw.githubusercontent.com/irixjp/aitac-automation/main/101_ansible_basic/images/run_command.png)
`tree roles`

以下のような構造になっていれば必要なファイルの準備が整っています。
```text
roles
└── web_setup
    ├── defaults
    │   └── main.yml
    ├── files
    │   ├── dummy_file  # ここは無視してください。
    │   └── httpd.conf
    ├── handlers
    │   └── main.yml
    ├── tasks
    │   └── main.yml
    └── templates
        └── index.html.j2
```

## 実行

作成した playbook を実行します。

![run_command.png](https://raw.githubusercontent.com/irixjp/aitac-automation/main/101_ansible_basic/images/run_command.png)
`ansible-playbook role_playbook.yml`

```text
(省略)
TASK [web_setup : install httpd] *********************
ok: [node1]
ok: [node3]
ok: [node2]

TASK [web_setup : start & enabled httpd] *************
ok: [node1]
ok: [node3]
ok: [node2]

TASK [web_setup : Put index.html from template] ******
ok: [node3]
ok: [node2]
ok: [node1]

TASK [web_setup : Copy Apache configuration file] ****
changed: [node3]
changed: [node2]
changed: [node1]

RUNNING HANDLER [web_setup : restart_apache] *********
changed: [node2]
changed: [node3]
changed: [node1]
(省略)
```

上記のような出力となれば成功です。node1,2,3 に対してブラウザでアクセスしてサイトの動作を確認してください。

アクセス先のIPアドレスを調べるには以下のコマンドを実行します。

![run_command.png](https://raw.githubusercontent.com/irixjp/aitac-automation/main/101_ansible_basic/images/run_command.png)
`curl 169.254.169.254/latest/meta-data/public-ipv4`

- node1: http://<自分の code-server IPアドレス>:8081
- node2: http://<自分の code-server IPアドレス>:8082
- node3: http://<自分の code-server IPアドレス>:8083


ロールを使うことで飛躍的に自動化の再利用性が高まります。これはタスクとインベントリーが完全に切り離されるためです。


## 演習の解答
---
- [role\_playbook.yml](https://github.com/irixjp/aitac-automation/blob/main/101_ansible_basic/solutions/role_playbook.yml)
- [web\_setup](https://github.com/irixjp/aitac-automation/tree/main/101_ansible_basic/solutions/roles/web_setup)
