# 複数のイベントを組み合わせる

ここでは、複数のイベントの組み合わせを条件にするルールを作成します。

1 つのイベントだけでは、対応が必要かどうかを判断できない場合があります。例えば、ディスクの使用量が逼迫したというアラート（`disk_full`）だけであれば、すぐに対応しなくてもよいかもしれません。アプリケーションのエラー（`app_error`）が 1 回出ただけであれば、一時的なものかもしれません。しかし、同じホストで `disk_full` が出た直後に `app_error` が出たのであれば、ディスクの逼迫によってアプリケーションが障害を起こしている可能性が高く、すぐに対応すべき状況です。

人であれば、2 つのアラートを並べて見て、このような判断をします。EDA では、このような判断も条件として記述できます。


## ステップ1: all と timeout

`~/eda/working/multiple_rulebook.yml` をエディタで開き、以下のように追記してください。

![edit_file.png](https://raw.githubusercontent.com/irixjp/aitac-contents/main/101_ansible_basic/images/edit_file.png)
`~/eda/working/multiple_rulebook.yml`
```yaml
---
- name: multiple events rulebook
  hosts: all
  sources:
  - ansible.eda.webhook:
      host: 0.0.0.0
      port: 5000

  rules:
  - name: disk full and app error
    condition:
      all:
      - event.payload.alert == "disk_full"
      - event.payload.alert == "app_error" and event.payload.host == events.m_0.payload.host
      timeout: 1 minute
    action:
      debug:
        msg: "{{ events.m_0.payload.host }}: 1 分以内に disk_full と app_error が発生しました"
```

- `all:` リストのすべての条件に当てはまるイベントが揃ったときに、ルールが動きます。条件ごとに別々のイベントが当てはまります。
- `events.m_0`、`events.m_1`: `all` の 1 つ目、2 つ目の条件に当てはまったイベントです。2 つ目の条件の `event.payload.host == events.m_0.payload.host` は、「1 つ目の条件に当てはまったイベントと同じ host であること」を意味します。アクションでも `events.m_0` で参照できます。
- `timeout: 1 minute`: すべてのイベントが 1 分以内に揃った場合だけ、ルールが動きます。1 分を過ぎると、揃わなかったイベントは破棄されます。

> Note: 演習では待ち時間を短くするために 1 分としていますが、実際の運用では、`5 minutes` のように、関連するアラートが届くまでの時間を考慮して決めます。`seconds`、`minutes`、`hours` などの単位が使えます。

以下のイベントを使います。

| ファイル | 内容 |
|---|---|
| `events/disk_full_node1.json` | `{"host": "node1", "alert": "disk_full"}` |
| `events/app_error_node1.json` | `{"host": "node1", "alert": "app_error"}` |
| `events/app_error_node2.json` | `{"host": "node2", "alert": "app_error"}` |

ここからは、前の確認で送ったイベントが残っていると結果が変わるため、**確認ごとに rulebook を起動し直してから** イベントを送ってください。

### 🔸確認1: 同じホストで disk_full → app_error

rulebook を起動し、右側のターミナル（`~/eda/working` にいること）から、以下の 2 つのイベントを続けて送ってください。

![run_command.png](https://raw.githubusercontent.com/irixjp/aitac-contents/main/101_ansible_basic/images/run_command.png)
`curl -H 'Content-Type: application/json' -d @events/disk_full_node1.json http://localhost:5000/endpoint`

1 つ目のイベントでは、まだ何も表示されません。

![run_command.png](https://raw.githubusercontent.com/irixjp/aitac-contents/main/101_ansible_basic/images/run_command.png)
`curl -H 'Content-Type: application/json' -d @events/app_error_node1.json http://localhost:5000/endpoint`

```text
** 2026-11-10 07:39:06.238665 [debug] ******************************************
node1: 1 分以内に disk_full と app_error が発生しました
********************************************************************************
```

2 つ目のイベントが届いた時点で、2 つの条件が揃い、ルールが動きました。

### 🔸確認2: 異なるホストで disk_full → app_error

rulebook を起動し直してから、以下の 2 つのイベントを続けて送ってください。

![run_command.png](https://raw.githubusercontent.com/irixjp/aitac-contents/main/101_ansible_basic/images/run_command.png)
`curl -H 'Content-Type: application/json' -d @events/disk_full_node1.json http://localhost:5000/endpoint`

![run_command.png](https://raw.githubusercontent.com/irixjp/aitac-contents/main/101_ansible_basic/images/run_command.png)
`curl -H 'Content-Type: application/json' -d @events/app_error_node2.json http://localhost:5000/endpoint`

host が異なるため、何も表示されません。

### 🔸確認3: 同じホストで app_error → disk_full（順番が逆）

rulebook を起動し直してから、確認1 と逆の順番で送ってください。

![run_command.png](https://raw.githubusercontent.com/irixjp/aitac-contents/main/101_ansible_basic/images/run_command.png)
`curl -H 'Content-Type: application/json' -d @events/app_error_node1.json http://localhost:5000/endpoint`

![run_command.png](https://raw.githubusercontent.com/irixjp/aitac-contents/main/101_ansible_basic/images/run_command.png)
`curl -H 'Content-Type: application/json' -d @events/disk_full_node1.json http://localhost:5000/endpoint`

```text
** 2026-11-10 07:39:31.166216 [debug] ******************************************
node1: 1 分以内に disk_full と app_error が発生しました
********************************************************************************
```

順番が逆でもルールが動きました。`all` は、条件に当てはまるイベントが揃ったかどうかだけを判定し、届いた順番は問いません。


## ステップ2: 順番を条件にする

今回の想定は「`disk_full` の **後に** `app_error` が出た」場合です。`app_error` が先に出ていたのであれば、アプリケーションのエラーはディスクとは別の原因かもしれません。そこで、届いた順番も条件に加えます。

ルールを以下のように変更してください。ルールの名前、2 つ目の条件、メッセージの 3 か所を変更しています。

![edit_file.png](https://raw.githubusercontent.com/irixjp/aitac-contents/main/101_ansible_basic/images/edit_file.png)
`~/eda/working/multiple_rulebook.yml`
```yaml
---
- name: multiple events rulebook
  hosts: all
  sources:
  - ansible.eda.webhook:
      host: 0.0.0.0
      port: 5000

  rules:
  - name: app error after disk full
    condition:
      all:
      - event.payload.alert == "disk_full"
      - event.payload.alert == "app_error" and event.payload.host == events.m_0.payload.host and event.meta.received_at > events.m_0.meta.received_at
      timeout: 1 minute
    action:
      debug:
        msg: "{{ events.m_0.payload.host }}: disk_full の後、1 分以内に app_error が発生しました"
```

「デモ」の演習で確認したとおり、イベントの `meta.received_at` には ansible-rulebook がイベントを受信した時刻（例: `2026-11-10T07:44:07.121681Z`）が入っています。`event.meta.received_at > events.m_0.meta.received_at` は、「2 つ目のイベントの受信時刻が、1 つ目のイベントの受信時刻より後であること」を意味します。

> Note: 受信時刻は同じ形式の文字列のため、`>` で比べると時刻の前後を判定できます。送る側の時刻ではなく、ansible-rulebook が受信した時刻で判定している点に注意してください。

### 🔸確認4: 同じホストで app_error → disk_full（順番が逆）

rulebook を起動し直してから、確認3 と同じ順番で送ってください。

![run_command.png](https://raw.githubusercontent.com/irixjp/aitac-contents/main/101_ansible_basic/images/run_command.png)
`curl -H 'Content-Type: application/json' -d @events/app_error_node1.json http://localhost:5000/endpoint`

![run_command.png](https://raw.githubusercontent.com/irixjp/aitac-contents/main/101_ansible_basic/images/run_command.png)
`curl -H 'Content-Type: application/json' -d @events/disk_full_node1.json http://localhost:5000/endpoint`

今度は何も表示されません。

### 🔸確認5: 同じホストで disk_full → app_error

rulebook を起動し直してから、確認1 と同じ順番で送ってください。

![run_command.png](https://raw.githubusercontent.com/irixjp/aitac-contents/main/101_ansible_basic/images/run_command.png)
`curl -H 'Content-Type: application/json' -d @events/disk_full_node1.json http://localhost:5000/endpoint`

![run_command.png](https://raw.githubusercontent.com/irixjp/aitac-contents/main/101_ansible_basic/images/run_command.png)
`curl -H 'Content-Type: application/json' -d @events/app_error_node1.json http://localhost:5000/endpoint`

```text
** 2026-11-10 07:39:56.070020 [debug] ******************************************
node1: disk_full の後、1 分以内に app_error が発生しました
********************************************************************************
```

`disk_full` の後に `app_error` が届いた場合だけ、ルールが動くようになりました。

### 🔸確認6: 1 分を過ぎてから app_error（時間に余裕があれば）

rulebook を起動し直し、`events/disk_full_node1.json` を送ってから **1 分以上待って**、`events/app_error_node1.json` を送ってください。`timeout` を過ぎているため、何も表示されません。

確認が終わったら、左側のターミナルで `Ctrl+C` を押して rulebook を停止してください。

> Note: 「`disk_full` が届いたのに、一定時間内に復旧のイベントが届かなかったら動く」のように、イベントが **届かなかったこと** を条件にする `not_all` もあります。詳しくは [Conditions のドキュメント](https://docs.ansible.com/projects/rulebook/en/latest/conditions.html) の「Adding time constraints for rules when "not all" conditions matched」を確認してください。


## 演習の解答

- [multiple\_rulebook.yml](https://github.com/irixjp/aitac-contents/blob/main/201_event-driven-ansible/solutions/multiple_rulebook.yml)
