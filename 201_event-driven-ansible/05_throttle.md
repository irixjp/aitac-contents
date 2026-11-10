# 同じイベントの繰り返しを抑える

ここでは、同じイベントが繰り返し届いたときに、アクションの実行を抑えるルールを作成します。

監視ツールの多くは、障害が続いている間、同じアラートを数十秒から数分ごとに送り続けます。これまでの rulebook では、届いたイベントのそれぞれに対してアクションが実行されるため、同じ調査の playbook が何度も実行されることになります。参照するだけの playbook であれば無駄が増えるだけですが、サービスの再起動やチケットの起票を行う playbook であれば、繰り返し実行されることで状況をかえって悪くしかねません。このような短時間に大量のイベントが届く状況は、イベントストームと呼ばれます。

ansible-rulebook では、ルールに `throttle` を指定して、同じイベントに対するアクションの実行を一定時間に 1 回に抑えられます。


## ステップ1: once_within

サービスが停止したというアラート（`service_down`）を受け取ったら、そのホストのサービスの状態を `ops_service.yml` で取得するルールを作成します。

`~/eda/working/throttle_rulebook.yml` をエディタで開き、以下のように追記してください。

![edit_file.png](https://raw.githubusercontent.com/irixjp/aitac-automation/main/101_ansible_basic/images/edit_file.png)
`~/eda/working/throttle_rulebook.yml`
```yaml
---
- name: throttle rulebook
  hosts: all
  sources:
  - ansible.eda.webhook:
      host: 0.0.0.0
      port: 5000
    filters:
    - eda.builtin.insert_hosts_to_meta:
        host_path: payload.host

  rules:
  - name: service down
    condition: event.payload.alert == "service_down"
    throttle:
      once_within: 1 minute
      group_by_attributes:
      - event.payload.host
    action:
      run_playbook:
        name: ops_service.yml
        extra_vars:
          service_name: "{{ event.payload.service }}"
```

`filters` と `extra_vars` は「運用の playbook をイベントで動かす」の演習と同じです。新しく追加したのは `throttle` です。

- `once_within: 1 minute`: 最初のイベントでアクションを実行し、その後 1 分間に届いた同じイベントは無視します。
- `group_by_attributes`: 何をもって「同じイベント」とするかを指定します。ここでは `event.payload.host` を指定しているため、host ごとに数えます。node1 のアラートが繰り返し届いている間でも、node2 のアラートは別のイベントとして扱われ、アクションが実行されます。

以下のイベントを使います。

| ファイル | 内容 |
|---|---|
| `events/service_down_node1.json` | `{"host": "node1", "alert": "service_down", "service": "sshd"}` |
| `events/service_down_node2.json` | `{"host": "node2", "alert": "service_down", "service": "sshd"}` |

左側のターミナルで rulebook を起動してください。

![run_command.png](https://raw.githubusercontent.com/irixjp/aitac-automation/main/101_ansible_basic/images/run_command.png)
`ansible-rulebook -i ~/inventory -r throttle_rulebook.yml -v`

右側のターミナル（`~/eda/working` にいること）から、node1 のアラートを 1 秒おきに 3 回送ります。

![run_command.png](https://raw.githubusercontent.com/irixjp/aitac-automation/main/101_ansible_basic/images/run_command.png)
`for i in 1 2 3; do curl -H 'Content-Type: application/json' -d @events/service_down_node1.json http://localhost:5000/endpoint; echo; sleep 1; done`

続けて、node2 のアラートを 1 回送ります。

![run_command.png](https://raw.githubusercontent.com/irixjp/aitac-automation/main/101_ansible_basic/images/run_command.png)
`curl -H 'Content-Type: application/json' -d @events/service_down_node2.json http://localhost:5000/endpoint`

左側のターミナルを確認してください。node1 のイベントを 3 回送りましたが、`ops_service.yml` は node1 に対して 1 回、node2 に対して 1 回だけ実行されています。

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

PLAY RECAP *********************************************************************
node1                      : ok=2    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0

PLAY [get service status] ******************************************************

TASK [get status of sshd] ******************************************************
ok: [node2]

TASK [show status] *************************************************************
ok: [node2] => {
    "msg": [
        "service : sshd",
        "state   : active (running)",
        "since   : Tue 2026-11-10 07:12:17 UTC",
        "main pid: 87"
    ]
}

PLAY RECAP *********************************************************************
node2                      : ok=2    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```

最初に node1 のイベントを送ってから 1 分以上たってから、もう一度 node1 のイベントを送ってください。

![run_command.png](https://raw.githubusercontent.com/irixjp/aitac-automation/main/101_ansible_basic/images/run_command.png)
`curl -H 'Content-Type: application/json' -d @events/service_down_node1.json http://localhost:5000/endpoint`

1 分の期間が終わっているため、node1 に対して再び `ops_service.yml` が実行されます。

```text
PLAY [get service status] ******************************************************
（略）
PLAY RECAP *********************************************************************
node1                      : ok=2    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```


## ステップ2: once_after

`throttle` には、`once_within` のほかに `once_after` があります。`throttle_rulebook.yml` の `once_within: 1 minute` を、以下のように変更してください。

![edit_file.png](https://raw.githubusercontent.com/irixjp/aitac-automation/main/101_ansible_basic/images/edit_file.png)
`~/eda/working/throttle_rulebook.yml`（変更する部分のみ）
```yaml
    throttle:
      once_after: 30 seconds
      group_by_attributes:
      - event.payload.host
```

rulebook を起動し直し、node1 のアラートを 1 秒おきに 3 回送ってください。

![run_command.png](https://raw.githubusercontent.com/irixjp/aitac-automation/main/101_ansible_basic/images/run_command.png)
`for i in 1 2 3; do curl -H 'Content-Type: application/json' -d @events/service_down_node1.json http://localhost:5000/endpoint; echo; sleep 1; done`

イベントを送った直後には、何も実行されません。最初のイベントから 30 秒たつと、node1 に対して `ops_service.yml` が 1 回だけ実行されます。

```text
PLAY [get service status] ******************************************************
（略）
PLAY RECAP *********************************************************************
node1                      : ok=2    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```

2 つの違いは、アクションを実行するタイミングです。

| 指定 | アクションを実行するタイミング | 向いている用途 |
|---|---|---|
| `once_within` | 最初のイベントが届いたとき（その後の期間中のイベントは無視する） | すぐに対応を始めたい場合（初動の調査、復旧の処理） |
| `once_after` | 最初のイベントから期間が終わったとき | イベントが落ち着いてからまとめて扱いたい場合（通知、報告） |

確認が終わったら、左側のターミナルで `Ctrl+C` を押して rulebook を停止してください。

> Note: 一定の数のイベントが届いてから実行する指定もあります。詳しくは [Conditions のドキュメント](https://docs.ansible.com/projects/rulebook/en/latest/conditions.html) の「Throttle actions to counter event storms」を確認してください。


## 演習の解答

- [throttle\_rulebook.yml](https://github.com/irixjp/aitac-automation/blob/main/201_event-driven-ansible/solutions/throttle_rulebook.yml)

> Note: 解答は、ステップ1 の `once_within` の状態です。
