# エラーハンドリング

playbook で一連のタスクをグループ化し、まとめて `when` や `ingore_errors` を適用することができます。ここで登場するのが `block` 句です。また `block` 句にはエラーハンドリングの機能もあり、`block` 内でのエラー に対して `rescue` 句のタスクを実行したり、エラーに関係なく実行する `always` 句が使えます。

## block

`block` 句を用いた playbook は以下のように記述できます。

`~/working/block_playbook.yml` を編集してください。

![edit_file.png](https://raw.githubusercontent.com/irixjp/aitac-automation/main/101_ansible_basic/images/edit_file.png)
`~/working/block_playbook.yml`
```yaml
---
- name: using block statement
  hosts: node1
  become: yes
  tasks:
    - name: Install, configure, and start Apache
      block:
        - name: install httpd
          ansible.builtin.dnf:
            name: httpd
            state: latest

        - name: start & enabled httpd
          ansible.builtin.service:
            name: httpd
            state: started
            enabled: yes

        - name: copy index.html
          ansible.builtin.copy:
            src: files/index.html
            dest: /var/www/html/
      when:
        - exec_block == 'yes'
```

- `block: ~~ when:` ここでは3つのタスクを `block` 句でまとめて、`when` 句で条件をつけています。この `block` 部分は `exec_block == 'yes'` が成立した時にまとめて実行されます。

`block_playbook.yml` を `-e 'exec_block=no'` と `yes` の場合で実行結果にどのような違いがあるか見てみましょう。

![run_command.png](https://raw.githubusercontent.com/irixjp/aitac-automation/main/101_ansible_basic/images/run_command.png)
`cd ~/working`

まず、条件が成立しないケースです。

![run_command.png](https://raw.githubusercontent.com/irixjp/aitac-automation/main/101_ansible_basic/images/run_command.png)
`ansible-playbook block_playbook.yml -e 'exec_block=no'`

```text
TASK [install httpd] *********************************
skipping: [node1]

TASK [start & enabled httpd] *************************
skipping: [node1]

TASK [copy index.html] *******************************
skipping: [node1]
```

3つのタスクがまとめてスキップされていることがわかります。次に条件が成立するケースです。

![run_command.png](https://raw.githubusercontent.com/irixjp/aitac-automation/main/101_ansible_basic/images/run_command.png)
`ansible-playbook block_playbook.yml -e 'exec_block=yes'`

```text
TASK [install httpd] *********************************
ok: [node1]

TASK [start & enabled httpd] *************************
ok: [node1]

TASK [copy index.html] *******************************
ok: [node1]
```

`block` でグループ化された3つのタスクが実行されていることがわかります。

このように、関連するタスクをグループ化することで `when` 句などを使ってまとめて制御することが可能になります。

`block` に対して使用できるキーワードは [Playbook Keywords](https://docs.ansible.com/projects/ansible/latest/reference_appendices/playbooks_keywords.html#block) に記載されています。


## rescue, always

`block` 句では `rescue`, `always` を利用することが可能です。

`~/working/rescue_playbook.yml` を以下のように作成してください。

![edit_file.png](https://raw.githubusercontent.com/irixjp/aitac-automation/main/101_ansible_basic/images/edit_file.png)
`~/working/rescue_playbook.yml`
```yaml
---
- name: using block, rescue, always statement
  hosts: node1
  become: yes
  tasks:
    - block:
        - name: block task
          ansible.builtin.debug:
            msg: "message from block"

        - name: check error flag in block
          ansible.builtin.assert:
            that:
              - error_flag == 'no'

      rescue:
        - name: rescue task
          ansible.builtin.debug:
            msg: "message from rescue"

        - name: check error flag in rescue
          ansible.builtin.assert:
            that:
              - error_flag == 'no'

      always:
        - name: always task
          ansible.builtin.debug:
            msg: "message from always"
```

- `block`: メインとなる処理を記述します。
  - `assert`: 判定用のモジュールです。`that` で与えた条件が成立する場合に `ok` となり、条件が成立しない場合は `failed` になります。
- `rescue`: `block` 内でエラーが発生した場合に実行されます。
- `always`: 必ず実行したい処理を実行します。

この playbook は `error_flag` 変数の値が `no` の場合には正常終了し、それ以外ではエラーとなります。

実際に実行して結果を確認します。まず `error_flag=no` として、正常終了させます。

![run_command.png](https://raw.githubusercontent.com/irixjp/aitac-automation/main/101_ansible_basic/images/run_command.png)
`ansible-playbook rescue_playbook.yml -e 'error_flag=no'`

```text
TASK [block task] ************************************
ok: [node1] => {
    "msg": "message from block"
}

TASK [check error flag in block] *********************
ok: [node1] => {
    "changed": false,
    "msg": "All assertions passed"
}

TASK [always task] ***********************************
ok: [node1] => {
    "msg": "message from always"
}
```

この場合、`block` 内のタスクが実行され、その後 `always` 内のタスクが実行されています。

次に、エラーが発生する場合のケースを確認します。

![run_command.png](https://raw.githubusercontent.com/irixjp/aitac-automation/main/101_ansible_basic/images/run_command.png)
`ansible-playbook rescue_playbook.yml -e 'error_flag=yes'`

```text
TASK [block task] ************************************
ok: [node-1] => {
    "msg": "message from block"
}

TASK [check error flag in block] *********************
[ERROR]: Task failed: Action failed: Assertion failed
Origin: /student/rescue_playbook.yml:10:11

 8             msg: "message from block"
 9
10         - name: check error flag in block
             ^ column 11

fatal: [node1]: FAILED! => {
    "assertion": "error_flag == 'no'",
    "changed": false,
    "evaluated_to": false,
    "msg": "Assertion failed"
}

TASK [rescue task] ***********************************
ok: [node-1] => {
    "msg": "message from rescue"
}

TASK [check error flag in rescue] ********************
[ERROR]: Task failed: Action failed: Assertion failed
Origin: /student/rescue_playbook.yml:20:11

18             msg: "message from rescue"
19
20         - name: check error flag in rescue
             ^ column 11

fatal: [node1]: FAILED! => {
    "assertion": "error_flag == 'no'",
    "changed": false,
    "evaluated_to": false,
    "msg": "Assertion failed"
}

TASK [always task] ***********************************
ok: [node-1] => {
    "msg": "message from always"
}
```

ここではまず `block` のタスクが実行されますがエラーが発生します。エラーが発生したため `rescue` の処理が呼び出されています。さらに `rescue` 内でもエラーが発生しますが、 playbook は停止せずに `always` が実行されます。

このように、`block`, `rescue`, `always` を使うことで、 playbook 内のエラーハンドリングを行うことが可能となります。典型的な利用シーンとして、`rescue` で失敗時のリカバリ作業を行い、`always` で状態の通知を行うという使い方があります。


## 演習の解答

- [block\_playbook.yml](https://github.com/irixjp/aitac-automation/blob/main/101_ansible_basic/solutions/block_playbook.yml)
- [rescue\_playbook.yml](https://github.com/irixjp/aitac-automation/blob/main/101_ansible_basic/solutions/rescue_playbook.yml)
