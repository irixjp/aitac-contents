# 変数

変数を利用することで playbook の汎用性を高めることができます。ここでは様々な変数の利用方法を学習します。

## 変数の基礎

Ansible における変数は以下の特徴を持っています。

- 型がない
- 定義するとほぼ全ての場所から参照できる（グルーバル変数のようなイメージ）
- 様々な場所で定義/上書きできるが優先順位がある

様々な方法で定義・上書きできるため命名規則などでチーム内での利用方針を定めておくなどの工夫をすると利便性が向上します。

変数がどこで定義できて、どのような優先順位を持っているかは[公式ドキュメント](https://docs.ansible.com/projects/ansible/latest/playbook_guide/playbooks_variables.html#variable-precedence-where-should-i-put-a-variable)を参照してください。

この演習では代表的な変数の利用方法について見ていきます。

## ansible.builtin.debug モジュール

定義した変数の中身を確認するはに [`ansible.builtin.debug`](https://docs.ansible.com/projects/ansible/latest/collections/ansible/builtin/debug_module.html) モジュールを使います。

`~/working/vars_debug_playbook.yml` を以下のように編集してください。

![edit_file.png](https://raw.githubusercontent.com/irixjp/aitac-automation/main/101_ansible_basic/images/edit_file.png)
`~/working/vars_debug_playbook.yml`
```yaml
---
- hosts: node1
  gather_facts: no
  tasks:
    - name: print all variables
      ansible.builtin.debug:
        var: vars

    - name: get one variable
      ansible.builtin.debug:
        msg: "This value is {{ vars.ansible_version.full }}"
```

- `gather_facts: no` Ansible はデフォルトでタスクの実行前に `setup` モジュールを実行して、操作対象ノードの情報を収集して変数にセットします。この変数を `no` に設定することで情報収集をスキップさせることができます。これは演習を進める上で変数一覧の出力量を抑えて演習を進めやすくするためです(setupモジュールは膨大な情報を収集する)。
- `- ansible.builtin.debug:`
  - `var: vars` var オプションは引数で与えられた変数の内容を表示します。ここでは `vars` という変数を引数として与えています。`vars` は全ての変数が格納された特別な変数です。
  - `msg: "This value is {{ vars.ansible_version.full }}"` msg オプションは任意の文字列を出力します。この中では `{{ }}` でくくった箇所は変数として展開されます。
    - 変数内の辞書データは `.keyname` という形で取り出します。
    - 変数内のリストデータは `[index_number]` という形で取り出します。

`vars_debug_playbook.yml` を実行します。

![run_command.png](https://raw.githubusercontent.com/irixjp/aitac-automation/main/101_ansible_basic/images/run_command.png)
`cd ~/working`

![run_command.png](https://raw.githubusercontent.com/irixjp/aitac-automation/main/101_ansible_basic/images/run_command.png)
`ansible-playbook vars_debug_playbook.yml`

```text
PLAY [node-1] ****************************************

TASK [print all variables] ***************************
k: [node1] => {
    "vars": {
        "ansible_check_mode": false,
        "ansible_config_file": "/student/.ansible.cfg",
        "ansible_dependent_role_names": [],
        "ansible_diff_mode": false,
        (省略)

TASK [get one variable] ******************************
ok: [node1] => {
    "msg": "This value is 2.20.0"
}
(省略)
```

`vars` の内容は Ansible がデフォルトで定義する [マジック変数](https://docs.ansible.com/projects/ansible/latest/reference_appendices/special_variables.html) 等の全てが表示されています。


## playbook 内での変数定義

では実際に変数の定義を行ってみましょう。

`~/working/vars_play_playbook.yml` を以下のように編集します。

![edit_file.png](https://raw.githubusercontent.com/irixjp/aitac-automation/main/101_ansible_basic/images/edit_file.png)
`~/working/vars_play_playbook.yml`
```yaml
---
- hosts: node1
  gather_facts: no
  vars:
    play_vars:
      - order: 1st word
        value: ansible
      - order: 2nd word
        value: is
      - order: 3rd word
        value: fine
  tasks:
    - name: print play_vars
      ansible.builtin.debug:
        var: play_vars

    - name: access to the array
      ansible.builtin.debug:
        msg: "{{ play_vars[1].order }}"

    - name: join variables
      ansible.builtin.debug:
        msg: "{{ play_vars[0].value}} {{ play_vars[1].value }} {{ play_vars[2].value }}"
```

- `vars:` play パートに `vars:` セクションを記述すると、その配下で変数が定義できるようになります。
  - `play_vars:` 変数名です。自由に設定できます。
    - この変数は値として、3つの要素を持つリストを作成し、その1つずつに`order` `value` というキーを持つ辞書データを作成しています。
  - `msg: "{{ play_vars[1].order }}"` リストの値を取り出しています。
  - `msg: "{{ play_vars[0].value}} {{ play_vars[1].value }} {{ play_vars[2].value }}"` この例のように、複数の変数の値を結合して利用することも可能です。

`vars_play_playbook.yml` を実行します。

![run_command.png](https://raw.githubusercontent.com/irixjp/aitac-automation/main/101_ansible_basic/images/run_command.png)
`cd ~/working`

![run_command.png](https://raw.githubusercontent.com/irixjp/aitac-automation/main/101_ansible_basic/images/run_command.png)
`ansible-playbook vars_play_playbook.yml`

```text
(省略)
TASK [print play_vars] **************
ok: [node1] => {
    "play_vars": [
        {
            "order": "1st word",
            "value": "ansible"
        },
        {
            "order": "2nd word",
            "value": "is"
        },
        {
            "order": "3rd word",
            "value": "fine"
        }
    ]
}

TASK [access to the array] **********
ok: [node1] => {
    "msg": "2nd word"
}

TASK [join variables] ***************
ok: [node1] => {
    "msg": "ansible is fine"
}
(省略)
```


## task 内での変数定義

1つのタスク内だけで使う変数を定義したり、一時的に上書きを行うことが可能です。

`~/working/vars_task_playbook.yml` を以下のように編集します。

![edit_file.png](https://raw.githubusercontent.com/irixjp/aitac-automation/main/101_ansible_basic/images/edit_file.png)
`~/working/vars_task_playbook.yml`
```yaml
---
- hosts: node1
  gather_facts: no
  vars:
    task_vars: 100
  tasks:
    - name: print task_vars 1
      ansible.builtin.debug:
        var: task_vars

    - name: override task_vars
      ansible.builtin.debug:
        var: task_vars
      vars:
        task_vars: 20

    - name: print task_vars 2
      ansible.builtin.debug:
        var: task_vars
```

`vars_task_playbook.yml` を実行します。

![run_command.png](https://raw.githubusercontent.com/irixjp/aitac-automation/main/101_ansible_basic/images/run_command.png)
`ansible-playbook vars_task_playbook.yml`

```text
(省略)
TASK [print task_vars 1] ************
ok: [node1] => {
    "task_vars": 100
}

TASK [override task_vars] ***********
ok: [node1] => {
    "task_vars": 20
}

TASK [print task_vars 2] ************
ok: [node1] => {
    "task_vars": 100
}
```

タスクの中での `vars:` はそのタスク内でのみ有効な変数となります。 [変数の優先順位](https://docs.ansible.com/projects/ansible/latest/playbook_guide/playbooks_variables.html#variable-precedence-where-should-i-put-a-variable) が `play vars` より高いため、2つ目のタスクでは変数の値が上書きされ、上記のような結果となります。

では更に優先順位の高い `extra_vars` (コマンドラインから指定する変数) を使うとどうなるか見てみましょう。

`extra_vars` を与えるには `ansible-playbook` コマンドに `-e` オプションをつけて実行します。

![run_command.png](https://raw.githubusercontent.com/irixjp/aitac-automation/main/101_ansible_basic/images/run_command.png)
`ansible-playbook vars_task_playbook.yml -e 'task_vars=50'`

```text
(省略)
TASK [print task_vars 1] ************
ok: [node1] => {
    "task_vars": "50"
}

TASK [override task_vars] ***********
ok: [node1] => {
    "task_vars": "50"
}

TASK [print task_vars 2] ************
ok: [node1] => {
    "task_vars": "50"
}
```

全てのタスクにおいて最も優先順位の高い `extra_vars` の値が用いられています。このように、Ansible では変数を定義した場所によって上書きの優先順位が異なるため注意が必要です。

## その他の変数定義

その他の変数の定義方法について紹介します。


### 🔸ansible.builtin.set\_fact での定義

[ansible.builtin.set_fact](https://docs.ansible.com/projects/ansible/latest/collections/ansible/builtin/set_fact_module.html) モジュールを使って、タスクパートの中で任意の変数を定義することができます。一般的な用途として、1つのタスクの実行結果を受け取り、その値を加工して新たな変数を定義し、その値を後続のタスクで利用する場合があります。

`ansible.builtin.set_fact` を使う演習は次のパートで登場します。


### 🔸host\_vars, group\_vars での定義

インベントリーの項目でも解説した変数です。特定のグループやホストに関連付けられる変数を定義することができます。インベントリーファイルに記載する以外にも、実行する playbook と同一ディレクトリに、`gourp_vars` `host_vars` ディレクトリを作成して、そこに `<group_name>.yml`, `<node_name>.yml` ファイルを作成することでグループ、ホスト変数として認識させることができます。

> Note: この `gourp_vars` `host_vars` というディレクトリ名は Ansible のルールとして決まっており変えることはできません。

実際にいくつかのホスト変数とグループ変数を定義します。

### 🔸`~/working/group_vars/all.yml`

グループ変数を定義します。

![edit_file.png](https://raw.githubusercontent.com/irixjp/aitac-automation/main/101_ansible_basic/images/edit_file.png)
`~/working/group_vars/all.yml`
```yaml
---
vars_by_group_vars: 1000
```

### 🔸`~/working/host_vars/node1.yml`

node1用のホスト変数を定義します。

![edit_file.png](https://raw.githubusercontent.com/irixjp/aitac-automation/main/101_ansible_basic/images/edit_file.png)
`~/working/host_vars/node1.yml`
```yaml
---
vars_by_host_vars: 111
```

### 🔸`~/working/host_vars/node2.yml`

node2用のホスト変数を定義します。

![edit_file.png](https://raw.githubusercontent.com/irixjp/aitac-automation/main/101_ansible_basic/images/edit_file.png)
`~/working/host_vars/node2.yml`
```yaml
---
vars_by_host_vars: 222
```

### 🔸`~/working/host_vars/node3.yml`

node3用のホスト変数を定義します。

![edit_file.png](https://raw.githubusercontent.com/irixjp/aitac-automation/main/101_ansible_basic/images/edit_file.png)
`~/working/host_vars/node3.yml`
```yaml
---
vars_by_host_vars: 333
```

### 🔸変数ファイルの確認

ここまでに作成したファイルを確認しておきます。

![run_command.png](https://raw.githubusercontent.com/irixjp/aitac-automation/main/101_ansible_basic/images/run_command.png)
`tree group_vars host_vars`

```text
group_vars
└── all.yml     <- vars_by_group_vars: 1000
host_vars
├── node-1.yml  <- vars_by_host_vars: 111
├── node-2.yml  <- vars_by_host_vars: 222
└── node-3.yml  <- vars_by_host_vars: 333
```


### 🔸`~/working/vars_host_group_playbook.yml`

これらの変数を利用する playbook を作成します。

![edit_file.png](https://raw.githubusercontent.com/irixjp/aitac-automation/main/101_ansible_basic/images/edit_file.png)
`~/working/vars_host_group_playbook.yml`
```yaml
---
- hosts: web
  gather_facts: no
  tasks:
    - name: print group_vars
      ansible.builtin.debug:
        var: vars_by_group_vars

    - name: print host vars
      ansible.builtin.debug:
        var: vars_by_host_vars

    - name: vars_by_group_vars + vars_by_host_vars
      ansible.builtin.set_fact:
        cal_result: "{{ vars_by_group_vars + vars_by_host_vars }}"

    - name: print cal_vars
      ansible.builtin.debug:
        var: cal_result
```

ここまで準備が整ったら `vars_host_group_playbook.yml` を実行します。

![run_command.png](https://raw.githubusercontent.com/irixjp/aitac-automation/main/101_ansible_basic/images/run_command.png)
`ansible-playbook vars_host_group_playbook.yml`

```text
(省略)
TASK [print group_vars] ******************************
ok: [node1] => {
    "vars_by_group_vars": 1000
}
ok: [node2] => {
    "vars_by_group_vars": 1000
}
ok: [node3] => {
    "vars_by_group_vars": 1000
}

TASK [print host vars] *******************************
ok: [node1] => {
    "vars_by_host_vars": 111
}
ok: [node2] => {
    "vars_by_host_vars": 222
}
ok: [node3] => {
    "vars_by_host_vars": 333
}

TASK [vars_by_group_vars + vars_by_host_vars] ********
ok: [node1]
ok: [node2]
ok: [node3]

TASK [print cal_vars] ********************************
ok: [node1] => {
    "cal_result": "1111"
}
ok: [node2] => {
    "cal_result": "1222"
}
ok: [node3] => {
    "cal_result": "1333"
}
(省略)
```

このように、同じ変数名でグループやホストごとに別々の値を持たせることが可能となります。


### 🔸register による実行結果の保存

Ansible のモジュールは実行されると様々な戻り値を返します。playbook の中ではこの戻り値を保存して後続のタスクで利用することができます。その際に利用するのが `register` 句です。`register` に変数名を指定すると、その変数に戻り値を格納します。

`~/working/vars_register_playbook.yml` を以下のように編集します。

![edit_file.png](https://raw.githubusercontent.com/irixjp/aitac-automation/main/101_ansible_basic/images/edit_file.png)
`~/working/vars_register_playbook.yml`
```yaml
---
- hosts: node1
  gather_facts: no
  tasks:
    - name: exec hostname command
      ansible.builtin.shell: hostname
      register: ret

    - name: print ret
      ansible.builtin.debug:
        var: ret

    - name: create a directory
      ansible.builtin.file:
        path: /tmp/testdir
        state: directory
        mode: '0755'
      register: ret

    - name: print ret
      ansible.builtin.debug:
        var: ret
```


`vars_register_playbook.yml` を実行します。

![run_command.png](https://raw.githubusercontent.com/irixjp/aitac-automation/main/101_ansible_basic/images/run_command.png)
`ansible-playbook vars_register_playbook.yml`

```text
(省略)
TASK [exec hostname command] *************************
changed: [node1]

TASK [print ret] *************************************
ok: [node1] => {
    "ret": {
        "changed": true,
        "cmd": "hostname",
        "delta": "0:00:00.005116",
        "end": "2025-12-06 14:19:27.640396",
        "failed": false,
        "msg": "",
        "rc": 0,
        "start": "2025-12-06 14:19:27.635280",
        "stderr": "",
        "stderr_lines": [],
        "stdout": "node1",
        "stdout_lines": [
            "node1"
        ]
    }
}

TASK [create a directory] ****************************
changed: [node1]

TASK [print ret] *************************************
ok: [node1] => {
    "ret": {
        "changed": true,
        "failed": false,
        "gid": 1000,
        "group": "student",
        "mode": "0755",
        "owner": "student",
        "path": "/tmp/testdir",
        "size": 40,
        "state": "directory",
        "uid": 1000
    }
}
```

この例では、まず `ansible.builtin.shell` モジュールで hostname コマンドを実行した結果を変数 `ret` に格納し、直後の `ansible.builtin.debug` モジュールで内容を表示しています。次に、[`ansible.builtin.file`](https://docs.ansible.com/projects/ansible/latest/collections/ansible/builtin/file_module.html) モジュールを使ってディレクトリを作成し、その戻り値を `ret` に格納しています。そして同じく `ansible.builtin.debug` モジュールで内容を確認しています。

各モジュールの戻り値が何を返すかはモジュールのドキュメントで確認することができます。

変数を使うことで playbook に大きな柔軟性を持たせることが可能になります。この後に登場するループや条件式と組み合わせについても続けて学んでいきましょう。

## 演習の解答

- [vars\_debug\_playbook.yml](https://github.com/irixjp/aitac-automation/blob/main/101_ansible_basic/solutions/vars_debug_playbook.yml)
- [vars\_play\_playbook.yml](https://github.com/irixjp/aitac-automation/blob/main/101_ansible_basic/solutions/vars_play_playbook.yml)
- [vars\_task\_playbook.yml](https://github.com/irixjp/aitac-automation/blob/main/101_ansible_basic/solutions/vars_task_playbook.yml)
- [vars\_host\_group\_playbook.yml](https://github.com/irixjp/aitac-automation/blob/main/101_ansible_basic/solutions/vars_host_group_playbook.yml)
  - [host\_vars/node1.yml](https://github.com/irixjp/aitac-automation/blob/main/101_ansible_basic/solutions/host_vars/node1.yml)
  - [host\_vars/node2.yml](https://github.com/irixjp/aitac-automation/blob/main/101_ansible_basic/solutions/host_vars/node2.yml)
  - [host\_vars/node3.yml](https://github.com/irixjp/aitac-automation/blob/main/101_ansible_basic/solutions/host_vars/node3.yml)
  - [group\_vars/all.yml](https://github.com/irixjp/aitac-automation/blob/main/101_ansible_basic/solutions/group_vars/all.yml)
- [vars\_register\_playbook.yml](https://github.com/irixjp/aitac-automation/blob/main/101_ansible_basic/solutions/vars_register_playbook.yml)
