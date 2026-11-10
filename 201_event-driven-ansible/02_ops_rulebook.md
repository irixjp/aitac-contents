# 運用の playbook をイベントで動かす

ここでは、運用で使う playbook をイベントで起動する rulebook を作成します。

監視ツールがアラートを出したとき、担当者はまず対象のサーバーにログインして、ログを見る、サービスの状態を見る、プロセスやディスクの使用状況を見る、といった初動の調査を行います。この調査の手順は、アラートの種類ごとにほぼ決まっています。決まった手順であれば playbook にでき、playbook にできれば、アラートをきっかけに自動で実行できます。

本演習では、この初動の調査を題材とします。最初に playbook を人が実行して内容を確認し、その後で同じ playbook をイベントで起動する rulebook を作成します。


## 運用の playbook の確認

`~/eda/working` には、以下の 3 つの playbook が準備されています。いずれも対象のノードの状態を参照するだけで、変更は行いません。

| playbook | 内容 | 変数 |
|---|---|---|
| `ops_logs.yml` | サービスのログ（journal）を直近から数行取得する | `service_name`（既定値 `sshd`）、`log_lines`（既定値 `5`） |
| `ops_service.yml` | サービスの状態（起動しているか、いつから動いているか）を取得する | `service_name`（既定値 `sshd`） |
| `ops_process.yml` | ロードアベレージ、CPU 使用率の高いプロセス、ディスクの使用量を取得する | なし |

`~/eda/working/ops_logs.yml` をエディタで開いて、内容を確認してください。

`~/eda/working/ops_logs.yml`
```yaml
---
- name: get recent logs
  hosts: all
  gather_facts: false
  become: yes
  vars:
    service_name: sshd
    log_lines: 5
  tasks:
  - name: get journal of {{ service_name }}
    ansible.builtin.command:
      cmd: "journalctl -u {{ service_name }} -n {{ log_lines }} --no-pager"
    register: ret_journal
    changed_when: false

  - name: show journal
    ansible.builtin.debug:
      var: ret_journal.stdout_lines
```

`hosts: all` となっているため、実行するときには `-l` で対象のノードを絞り込みます。`ops_service.yml`、`ops_process.yml` も同様に開いて、内容を確認してください。

### 🔸playbook を手動で実行する

まず、これらの playbook を `ansible-playbook` コマンドで実行します。

![run_command.png](https://raw.githubusercontent.com/irixjp/aitac-automation/main/101_ansible_basic/images/run_command.png)
`cd ~/eda/working`

node2 の sshd のログを取得します。

![run_command.png](https://raw.githubusercontent.com/irixjp/aitac-automation/main/101_ansible_basic/images/run_command.png)
`ansible-playbook ops_logs.yml -l node2`

```text
PLAY [get recent logs] *********************************************************

TASK [get journal of sshd] *****************************************************
ok: [node2]

TASK [show journal] ************************************************************
ok: [node2] => {
    "ret_journal.stdout_lines": [
        "Nov 10 07:35:31 node2 sshd-session[215]: pam_unix(sshd:session): session opened for user student(uid=1000) by root(uid=0)",
        "Nov 10 07:41:41 node2 sshd-session[319]: Accepted publickey for student from 172.22.22.1 port 53062 ssh2: RSA SHA256:JJWqpVrV752LIdJm9QXj+isWQGHRyEeFDWDskPCruD8",
        "Nov 10 07:41:41 node2 sshd-session[319]: pam_unix(sshd:session): session opened for user student(uid=1000) by root(uid=0)",
        "Nov 10 07:44:54 node2 sshd-session[418]: Accepted publickey for student from 172.22.22.1 port 54608 ssh2: RSA SHA256:JJWqpVrV752LIdJm9QXj+isWQGHRyEeFDWDskPCruD8",
        "Nov 10 07:44:55 node2 sshd-session[418]: pam_unix(sshd:session): session opened for user student(uid=1000) by root(uid=0)"
    ]
}

PLAY RECAP *********************************************************************
node2                      : ok=2    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```

node3 の sshd の状態を取得します。`-e` で変数 `service_name` を指定しています。

![run_command.png](https://raw.githubusercontent.com/irixjp/aitac-automation/main/101_ansible_basic/images/run_command.png)
`ansible-playbook ops_service.yml -l node3 -e service_name=sshd`

```text
PLAY [get service status] ******************************************************

TASK [get status of sshd] ******************************************************
ok: [node3]

TASK [show status] *************************************************************
ok: [node3] => {
    "msg": [
        "service : sshd",
        "state   : active (running)",
        "since   : Tue 2026-11-10 07:12:24 UTC",
        "main pid: 87"
    ]
}

PLAY RECAP *********************************************************************
node3                      : ok=2    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```

node4 のプロセスとリソースの状況を取得します。

![run_command.png](https://raw.githubusercontent.com/irixjp/aitac-automation/main/101_ansible_basic/images/run_command.png)
`ansible-playbook ops_process.yml -l node4`

```text
PLAY [get process and resource usage] ******************************************

TASK [get load average] ********************************************************
ok: [node4]

TASK [get top processes] *******************************************************
ok: [node4]

TASK [get disk usage] **********************************************************
ok: [node4]

TASK [show results] ************************************************************
ok: [node4] => {
    "msg": [
        " 07:44:59 up 39 min,  1 user,  load average: 0.11, 0.11, 0.20",
        [
            "    PID USER     %CPU %MEM COMMAND",
            "    610 student  92.0  0.7 python3",
            "    474 student   3.7  0.3 systemd",
            "    485 student   1.0  0.2 sshd-session",
            "    469 root      0.8  0.2 sshd-session",
            "      1 root      0.0  0.3 systemd"
        ],
        [
            "Filesystem      Size  Used Avail Use% Mounted on",
            "overlay          20G  5.5G   15G  28% /"
        ]
    ]
}

PLAY RECAP *********************************************************************
node4                      : ok=4    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```

> Note: ログの内容、時刻、プロセスの一覧などは環境によって異なります。CPU 使用率の高いプロセスとして表示される `python3` は、この playbook を実行している Ansible 自身です。

ここで人が判断して指定したのは、「どの playbook を」「どのノードに」「どの変数で」実行するかの 3 つです。次に、この 3 つをイベントの内容から決めて playbook を実行する rulebook を作成します。


## rulebook の作成

本演習では、以下のような JSON のイベントを受け取ることにします。

```json
{"action": "logs", "host": "node2"}
```

- `action`: 実行したい調査の種類です。`logs`、`service`、`process` のいずれかとします。
- `host`: 調査の対象のノードです。

> Note: 実際の監視ツールが送るアラートの形式はツールごとに異なりますが、多くの場合、何が起きたか（アラートの名前や種類）と、どこで起きたか（ホスト名）が含まれています。

### 🔸ステップ1: ログ取得のルール

`~/eda/working/ops_rulebook.yml` をエディタで開いてください。このファイルには先頭に `---` のみが記載されています。以下のように追記してください。

![edit_file.png](https://raw.githubusercontent.com/irixjp/aitac-automation/main/101_ansible_basic/images/edit_file.png)
`~/eda/working/ops_rulebook.yml`
```yaml
---
- name: ops rulebook
  hosts: all
  sources:
  - ansible.eda.webhook:
      host: 0.0.0.0
      port: 5000

  rules:
  - name: get logs
    condition: event.payload.action == "logs"
    action:
      run_playbook:
        name: ops_logs.yml
```

`action` が `logs` のイベントを受け取ったら、`ops_logs.yml` を実行するルールです。

左側のターミナルで rulebook を起動してください。

![run_command.png](https://raw.githubusercontent.com/irixjp/aitac-automation/main/101_ansible_basic/images/run_command.png)
`ansible-rulebook -i ~/inventory -r ops_rulebook.yml -v`

`Waiting for events` と表示されたら、右側のターミナルから node2 のログ取得のイベントを送ります。

![run_command.png](https://raw.githubusercontent.com/irixjp/aitac-automation/main/101_ansible_basic/images/run_command.png)
`curl -H 'Content-Type: application/json' -d '{"action": "logs", "host": "node2"}' http://localhost:5000/endpoint`

左側のターミナルで `ops_logs.yml` が実行されます。ただし、PLAY RECAP を確認すると、node2 だけでなく node1〜6 のすべてで実行されています。

```text
PLAY RECAP *********************************************************************
node1                      : ok=2    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
node2                      : ok=2    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
node3                      : ok=2    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
node4                      : ok=2    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
node5                      : ok=2    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
node6                      : ok=2    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```

rulebook の `hosts: all` に対して playbook が実行されたためです。イベントの `host` はまだ使われていません。

### 🔸ステップ2: 対象のノードをイベントから決める

イベントの `host` の値を、playbook の実行対象にします。以下のように `filters` を追記してください。

![edit_file.png](https://raw.githubusercontent.com/irixjp/aitac-automation/main/101_ansible_basic/images/edit_file.png)
`~/eda/working/ops_rulebook.yml`
```yaml
---
- name: ops rulebook
  hosts: all
  sources:
  - ansible.eda.webhook:
      host: 0.0.0.0
      port: 5000
    filters:
    - eda.builtin.insert_hosts_to_meta:
        host_path: payload.host

  rules:
  - name: get logs
    condition: event.payload.action == "logs"
    action:
      run_playbook:
        name: ops_logs.yml
```

`filters` は、ソースが受け取ったイベントを、ルールで判定する前に加工する仕組みです。ここで利用している `eda.builtin.insert_hosts_to_meta` は、イベントの `host_path` で指定した場所（`payload.host`）の値を、アクションの実行対象のノードとして登録します。`run_playbook` は、登録されたノードだけに絞り込んで playbook を実行します。手動で実行したときの `-l node2` を、イベントから自動で指定するイメージです。

左側のターミナルで `Ctrl+C` を押して rulebook を停止し、起動し直してください。

![run_command.png](https://raw.githubusercontent.com/irixjp/aitac-automation/main/101_ansible_basic/images/run_command.png)
`ansible-rulebook -i ~/inventory -r ops_rulebook.yml -v`

右側のターミナルから、先ほどと同じイベントを送ります。

![run_command.png](https://raw.githubusercontent.com/irixjp/aitac-automation/main/101_ansible_basic/images/run_command.png)
`curl -H 'Content-Type: application/json' -d '{"action": "logs", "host": "node2"}' http://localhost:5000/endpoint`

今度は node2 だけで実行されます。

```text
PLAY [get recent logs] *********************************************************

TASK [get journal of sshd] *****************************************************
ok: [node2]

TASK [show journal] ************************************************************
ok: [node2] => {
    "ret_journal.stdout_lines": [
（略）
    ]
}

PLAY RECAP *********************************************************************
node2                      : ok=2    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```

`host` にはリストも指定できます。以下のイベントを送ると、node5 と node6 で実行されます。

![run_command.png](https://raw.githubusercontent.com/irixjp/aitac-automation/main/101_ansible_basic/images/run_command.png)
`curl -H 'Content-Type: application/json' -d '{"action": "logs", "host": ["node5", "node6"]}' http://localhost:5000/endpoint`

```text
PLAY RECAP *********************************************************************
node5                      : ok=2    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
node6                      : ok=2    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```

### 🔸ステップ3: サービスの状態とプロセスのルール

残りの 2 つの playbook のルールを追加します。`rules` に以下の 2 つのルールを追記してください。

![edit_file.png](https://raw.githubusercontent.com/irixjp/aitac-automation/main/101_ansible_basic/images/edit_file.png)
`~/eda/working/ops_rulebook.yml`
```yaml
---
- name: ops rulebook
  hosts: all
  sources:
  - ansible.eda.webhook:
      host: 0.0.0.0
      port: 5000
    filters:
    - eda.builtin.insert_hosts_to_meta:
        host_path: payload.host

  rules:
  - name: get logs
    condition: event.payload.action == "logs"
    action:
      run_playbook:
        name: ops_logs.yml

  - name: get service status
    condition: event.payload.action == "service"
    action:
      run_playbook:
        name: ops_service.yml
        extra_vars:
          service_name: "{{ event.payload.service | default('sshd') }}"

  - name: get process
    condition: event.payload.action == "process"
    action:
      run_playbook:
        name: ops_process.yml
```

`get service status` のルールでは、`extra_vars` で playbook に変数を渡しています。手動で実行したときの `-e service_name=sshd` と同じ働きです。値には Jinja2 のテンプレートが使えるため、イベントの `service` の値を渡しています。`default('sshd')` は、イベントに `service` が含まれていない場合に `sshd` を使う指定です。

rulebook を起動し直してから、右側のターミナルで以下のイベントを順に送ってください。

![run_command.png](https://raw.githubusercontent.com/irixjp/aitac-automation/main/101_ansible_basic/images/run_command.png)
`curl -H 'Content-Type: application/json' -d '{"action": "service", "host": "node3", "service": "sshd"}' http://localhost:5000/endpoint`

```text
PLAY [get service status] ******************************************************

TASK [get status of sshd] ******************************************************
ok: [node3]

TASK [show status] *************************************************************
ok: [node3] => {
    "msg": [
        "service : sshd",
        "state   : active (running)",
        "since   : Tue 2026-11-10 07:12:24 UTC",
        "main pid: 87"
    ]
}

PLAY RECAP *********************************************************************
node3                      : ok=2    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```

![run_command.png](https://raw.githubusercontent.com/irixjp/aitac-automation/main/101_ansible_basic/images/run_command.png)
`curl -H 'Content-Type: application/json' -d '{"action": "process", "host": "node4"}' http://localhost:5000/endpoint`

```text
PLAY [get process and resource usage] ******************************************
（略）
PLAY RECAP *********************************************************************
node4                      : ok=4    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```

`service` を含まないイベントも送ってみます。

![run_command.png](https://raw.githubusercontent.com/irixjp/aitac-automation/main/101_ansible_basic/images/run_command.png)
`curl -H 'Content-Type: application/json' -d '{"action": "service", "host": "node1"}' http://localhost:5000/endpoint`

```text
PLAY [get service status] ******************************************************

TASK [get status of sshd] ******************************************************
ok: [node1]

TASK [show status] *************************************************************
ok: [node1] => {
    "msg": [
        "service : sshd",
        "state   : active (running)",
        "since   : Tue 2026-11-10 07:12:11 UTC",
        "main pid: 88"
    ]
}
（略）
```

既定値の `sshd` が使われていることがわかります。

確認が終わったら、左側のターミナルで `Ctrl+C` を押して rulebook を停止してください。

ここで作成した rulebook は、playbook の内容には一切手を加えていません。人が手動で実行していた playbook を、そのままイベントで起動しています。EDA を導入するときは、まず人が使っている playbook を揃え、その playbook を「いつ」「どこに」「どの値で」実行するかを rulebook に記述する、という順に進めるのが基本です。

> Note: ここではイベントの `action` の値で playbook を選びましたが、実際の運用では、アラートの名前や重要度などに応じて playbook を選ぶことになります。次の演習では、このような判定に使う条件の書き方を確認します。


## 演習の解答

- [ops\_rulebook.yml](https://github.com/irixjp/aitac-automation/blob/main/201_event-driven-ansible/solutions/ops_rulebook.yml)
