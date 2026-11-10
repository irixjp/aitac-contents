# Event-Driven Ansible の概要とデモ

ここでは Event-Driven Ansible（EDA）の仕組みを解説し、あらかじめ準備したデモの rulebook を動かして、イベントによって自動化が動く様子を確認します。

「Ansible 基礎」の演習では、`ansible-playbook` コマンドを人が実行して playbook を動かしました。しかし実際の運用では、作業の多くは「何かが起きたこと」をきっかけに始まります。監視ツールがアラートを出した、アプリケーションがエラーを記録した、チケットが起票された、といったきっかけです。人がこのきっかけに気づき、内容を読み、どの playbook を動かすかを判断して実行している限り、playbook がいくら揃っていても対応の速さは人に依存します。

EDA は、この「気づく → 判断する → 実行する」の部分を自動化する仕組みです。


## Event-Driven Ansible の仕組み

EDA では、`rulebook`（ルールブック）と呼ばれるファイルに「どこからイベントを受け取り、どのような条件のときに、何を実行するか」を記述します。rulebook は `ansible-rulebook` コマンドに読み込ませて動かします。

```text
 監視ツール、アプリケーションなど
        │
        │ イベント（JSON）
        ▼
 ┌─ ansible-rulebook ───────────────────────────────┐
 │  source    : イベントを受け取る（webhook など）    │
 │      ↓                                           │
 │  rules     : 条件（condition）に合うかを判定する   │
 │      ↓                                           │
 │  action    : playbook やモジュールを実行する       │
 └──────────────────────────────────────────────────┘
        │
        ▼
     node1〜6
```

rulebook は次の 3 つの要素で構成されます。

- `source`（ソース）: イベントを受け取る部品です。HTTP でイベントを受け取る `webhook` のほか、Kafka、Prometheus の Alertmanager、URL の死活監視などが用意されています。ソースは `ansible.eda` collection に含まれています。
- `condition`（条件）: 受け取ったイベントが、ルールに当てはまるかを判定する式です。
- `action`（アクション）: 条件に当てはまったときに行う処理です。playbook の実行（`run_playbook`）、モジュールの実行（`run_module`）、イベントの表示（`print_event`）などがあります。

本演習で利用するソフトウェアは以下になります。

- `ansible-rulebook`: rulebook を読み込み、イベントを待ち受けて、条件に合えばアクションを実行するコマンドです。条件の判定には Java で書かれたルールエンジン（Drools）を利用しているため、起動に数秒かかります。
- `ansible.eda` collection: `webhook` などのソースを提供する collection です。

> Note: rulebook の条件の判定は ansible-rulebook の中で行われ、Ansible はアクションで playbook やモジュールを実行するときに使われます。つまり、EDA は Ansible を置き換えるものではなく、これまで作成してきた playbook を「いつ実行するか」を自動化するものです。


## rulebook の構造

デモの rulebook を確認します。`~/eda/working/demo_rulebook.yml` をエディタで開いてください。

`~/eda/working/demo_rulebook.yml`
```yaml
---
- name: demo rulebook
  hosts: node1
  sources:
  - ansible.eda.webhook:
      host: 0.0.0.0
      port: 5000

  rules:
  - name: message 1 - print event
    condition: event.payload.message == 1
    action:
      print_event:
        pretty: true

  - name: message 2 - run module
    condition: event.payload.message == 2
    action:
      run_module:
        name: ansible.builtin.ping

  - name: message 3 - run playbook
    condition: event.payload.message == 3
    action:
      run_playbook:
        name: demo_playbook.yml
```

playbook とよく似た構造をしていることがわかると思います。

- `name:` この rulebook（正確には rulebook の中の `ruleset`）の名前です。
- `hosts: node1`: アクションの実行対象となるグループやノードを指定します。playbook の `hosts` と同じく、インベントリー内に存在するグループやノードである必要があります。
- `sources:` イベントを受け取るソースを指定します。ここでは `ansible.eda.webhook` を利用し、ポート `5000` で HTTP のリクエストを待ち受けます。
- `rules:` ルールのリストです。各ルールは `name`、`condition`、`action` から構成されます。

受け取ったイベントは `event` という変数で参照できます。webhook の場合、HTTP で送られてきた JSON の本体は `event.payload` に入ります。つまり、このデモの rulebook は、送られてきた JSON の `message` の値に応じて、以下の 3 つの異なるアクションを実行します。

| message | アクション | 内容 |
|---|---|---|
| 1 | `print_event` | 受け取ったイベントを画面に表示する |
| 2 | `run_module` | node1 に対して `ansible.builtin.ping` モジュールを実行する |
| 3 | `run_playbook` | node1 に対して `demo_playbook.yml` を実行する |

`demo_playbook.yml` も開いて内容を確認してください。

`~/eda/working/demo_playbook.yml`
```yaml
---
- name: demo playbook started by rulebook
  hosts: all
  gather_facts: false
  tasks:
  - name: show event
    ansible.builtin.debug:
      msg: "受信したメッセージ: {{ ansible_eda.event.payload.message }}"

  - name: get uptime
    ansible.builtin.command:
      cmd: uptime
    register: ret_uptime
    changed_when: false

  - name: show uptime
    ansible.builtin.debug:
      msg: "{{ inventory_hostname }}: {{ ret_uptime.stdout }}"
```

通常の playbook ですが、`ansible_eda.event` という変数を使っている点に注目してください。rulebook から実行された playbook では、きっかけとなったイベントを `ansible_eda.event` で参照できます。

> Note: playbook は `hosts: all` となっていますが、rulebook から実行すると rulebook の `hosts`（ここでは node1）に絞り込まれて実行されます。`ansible-playbook` コマンドの `-l node1` と同じ動きです。


## デモの実行

### 🔸ターミナルを 2 つ用意する

本演習では、rulebook を動かすターミナルと、イベントを送るターミナルの 2 つを使います。

ターミナルを起動し（「≡」アイコン → `Terminal` → `New Terminal`）、ターミナルの右上にある分割のアイコン（`Split Terminal`）をクリックしてください。ターミナルが左右に分割されます。本演習では、左側を rulebook 用、右側をイベント送信用として説明します。

> Note: 分割のアイコンが見つからない場合は、「≡」アイコン → `Terminal` → `Split Terminal` でも分割できます。

### 🔸rulebook の起動

左側のターミナルで以下のコマンドを実行してください。

![run_command.png](https://raw.githubusercontent.com/irixjp/aitac-contents/main/101_ansible_basic/images/run_command.png)
`cd ~/eda/working`

![run_command.png](https://raw.githubusercontent.com/irixjp/aitac-contents/main/101_ansible_basic/images/run_command.png)
`ansible-rulebook -i ~/inventory -r demo_rulebook.yml -v`

- `-i ~/inventory`: アクションで利用するインベントリーを指定します。「Ansible 基礎」と同じインベントリーです。
- `-r demo_rulebook.yml`: 読み込む rulebook を指定します。
- `-v`: 動作のログを表示します。

数秒待つと、以下のような表示になります。

```text
2026-11-10 07:43:51,445 - ansible_rulebook.app - INFO - max_concurrent_actions=25
2026-11-10 07:43:51,446 - ansible_rulebook.app - INFO - Starting sources
2026-11-10 07:43:51,446 - ansible_rulebook.app - INFO - Starting rules
（中略）
2026-11-10 07:43:53,141 - ansible_rulebook.rule_set_runner - INFO - Waiting for actions on events from demo rulebook
2026-11-10 07:43:53,141 - ansible_rulebook.rule_set_runner - INFO - Waiting for events, ruleset: demo rulebook
```

最後に `Waiting for events` と表示されれば、イベントを待ち受けている状態です。ansible-rulebook はイベントを待ち続けるため、このコマンドは終了せず、プロンプトも戻りません。

### 🔸メッセージ 1 を送る

右側のターミナルから、`curl` コマンドで webhook にイベントを送ります。

![run_command.png](https://raw.githubusercontent.com/irixjp/aitac-contents/main/101_ansible_basic/images/run_command.png)
`curl -H 'Content-Type: application/json' -d '{"message": 1}' http://localhost:5000/endpoint`

- `-H 'Content-Type: application/json'`: 送るデータが JSON であることを示します。
- `-d '{"message": 1}'`: 送るデータ（イベントの本体）です。これが rulebook の `event.payload` になります。
- `http://localhost:5000/endpoint`: rulebook が待ち受けているポート 5000 に送ります。

右側のターミナルには `endpoint` と表示されます（webhook が受信したことを示す応答です）。

左側のターミナルを確認してください。以下のように、受け取ったイベントが表示されています。

```text
** 2026-11-10 07:44:07.155797 [event] ******************************************
{'meta': {'endpoint': 'endpoint',
          'headers': {'Accept': '*/*',
                      'Content-Length': '14',
                      'Content-Type': 'application/json',
                      'Host': 'localhost:5000',
                      'User-Agent': 'curl/8.12.1'},
          'received_at': '2026-11-10T07:44:07.121681Z',
          'source': {'name': 'ansible.eda.webhook',
                     'type': 'ansible.eda.webhook'},
          'uuid': '8326eeec-e14a-4af7-bc8e-405a68f9471c'},
 'payload': {'message': 1}}
********************************************************************************
```

`print_event` アクションが実行され、イベントの全体が表示されました。イベントは `payload`（送った JSON）と `meta`（受信した時刻、送信元のヘッダーなど ansible-rulebook が付け加えた情報）から構成されていることがわかります。

> Note: 時刻や uuid などの値は、実行するたびに異なります。

### 🔸メッセージ 2 を送る

右側のターミナルから、`message` を 2 にして送ります。

![run_command.png](https://raw.githubusercontent.com/irixjp/aitac-contents/main/101_ansible_basic/images/run_command.png)
`curl -H 'Content-Type: application/json' -d '{"message": 2}' http://localhost:5000/endpoint`

左側のターミナルに以下が表示されます。

```text
PLAY [wrapper] *****************************************************************

TASK [Module wrapper] **********************************************************
ok: [node1]

TASK [save result] *************************************************************
ok: [node1]

PLAY RECAP *********************************************************************
node1                      : ok=2    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```

`run_module` アクションが実行され、node1 に対して `ansible.builtin.ping` モジュールが実行されました。ansible-rulebook は、指定されたモジュールを実行するための playbook（`wrapper`）を内部で作成して実行するため、このような表示となります。

### 🔸メッセージ 3 を送る

右側のターミナルから、`message` を 3 にして送ります。

![run_command.png](https://raw.githubusercontent.com/irixjp/aitac-contents/main/101_ansible_basic/images/run_command.png)
`curl -H 'Content-Type: application/json' -d '{"message": 3}' http://localhost:5000/endpoint`

左側のターミナルに以下が表示されます。

```text
PLAY [demo playbook started by rulebook] ***************************************

TASK [show event] **************************************************************
ok: [node1] => {
    "msg": "受信したメッセージ: 3"
}

TASK [get uptime] **************************************************************
ok: [node1]

TASK [show uptime] *************************************************************
ok: [node1] => {
    "msg": "node1:  07:25:38 up 20 min,  1 user,  load average: 0.19, 0.21, 0.48"
}

PLAY RECAP *********************************************************************
node1                      : ok=3    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```

`run_playbook` アクションが実行され、`demo_playbook.yml` が node1 に対して実行されました。playbook の中で、イベントの内容（`受信したメッセージ: 3`）を参照できていることも確認してください。

### 🔸どのルールにも当てはまらないメッセージを送る

最後に、`message` を 4 にして送ります。

![run_command.png](https://raw.githubusercontent.com/irixjp/aitac-contents/main/101_ansible_basic/images/run_command.png)
`curl -H 'Content-Type: application/json' -d '{"message": 4}' http://localhost:5000/endpoint`

左側のターミナルには、以下のような受信のログが 1 行表示されるだけで、アクションは何も実行されません。

```text
2026-11-10 07:44:09,133 - aiohttp.access - INFO - 127.0.0.1 [10/Nov/2026:07:44:09 +0000] "POST /endpoint HTTP/1.1" 200 160 "-" "curl/8.12.1"
```

イベントは受信されましたが、どのルールの条件にも当てはまらなかったため、何も起きませんでした。EDA では、届いたイベントのうち、条件に当てはまるものだけに対してアクションが実行されます。

### 🔸rulebook の停止

左側のターミナルで `Ctrl+C` を押して、ansible-rulebook を停止してください。プロンプトが戻れば停止しています。

> Note: 本演習では、rulebook を編集したら、ansible-rulebook を一度停止してから起動し直します。ansible-rulebook は起動時に rulebook を読み込むため、起動したままファイルを編集しても反映されません。起動し直すときは、左側のターミナルで `↑` キーを押すと、前に実行したコマンドを呼び出せます。

ここまでで、同じ webhook に届いたイベントでも、その内容によって異なるアクションが実行されることを確認できました。次の演習では、運用で使う playbook をイベントで動かす rulebook を作成します。
