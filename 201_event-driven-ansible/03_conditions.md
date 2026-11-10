# 条件の書き方

ここでは、rulebook の `condition`（条件）の書き方を、いくつかのパターンで確認します。

EDA では、届いたイベントのうち、どれに対して何を実行するかを条件で決めます。条件が緩すぎれば不要なアクションが動き、厳しすぎれば必要なときに動きません。自動化を任せられるかどうかは、条件を正しく書けるかどうかに懸かっています。


## 演習の進め方

この演習では、アクションに playbook ではなく `debug` を使います。`debug` アクションは、指定したメッセージを ansible-rulebook の画面に表示するだけのアクションです。どのルールが動いたかをすぐに確認できます。

送るイベントは、`~/eda/working/events` にファイルとして準備しています。`curl` の `-d @ファイル名` で、ファイルの内容をイベントとして送れます。

```bash
curl -H 'Content-Type: application/json' -d @events/cpu_95.json http://localhost:5000/endpoint
```

各ステップでは、以下の順に進めます。

1. `~/eda/working/conditions_rulebook.yml` を編集する
2. 左側のターミナルで rulebook を起動する（起動していれば `Ctrl+C` で停止してから起動し直す）
3. 右側のターミナルからイベントを送り、左側のターミナルで結果を確認する

左側のターミナルで rulebook を起動するコマンドは、以下になります。

```bash
cd ~/eda/working
ansible-rulebook -i ~/inventory -r conditions_rulebook.yml -v
```

右側のターミナルでも、`~/eda/working` に移動しておいてください。

![run_command.png](https://raw.githubusercontent.com/irixjp/aitac-contents/main/101_ansible_basic/images/run_command.png)
`cd ~/eda/working`


## ステップ1: 比較演算子

CPU 使用率のアラートを想定して、値が一定以上のときに動くルールを作成します。

`~/eda/working/conditions_rulebook.yml` をエディタで開き、以下のように追記してください。

![edit_file.png](https://raw.githubusercontent.com/irixjp/aitac-contents/main/101_ansible_basic/images/edit_file.png)
`~/eda/working/conditions_rulebook.yml`
```yaml
---
- name: conditions rulebook
  hosts: all
  sources:
  - ansible.eda.webhook:
      host: 0.0.0.0
      port: 5000

  rules:
  - name: cpu critical
    condition: event.payload.cpu >= 90
    action:
      debug:
        msg: "CPU 使用率が危険域です: {{ event.payload.host }} {{ event.payload.cpu }}%"
```

条件には以下の比較演算子が使えます。

| 演算子 | 意味 |
|---|---|
| `==` | 等しい |
| `!=` | 等しくない |
| `>`、`>=` | より大きい、以上 |
| `<`、`<=` | より小さい、以下 |

rulebook を起動し、右側のターミナルから以下の 3 つのイベントを順に送ってください。

| ファイル | 内容 |
|---|---|
| `events/cpu_95.json` | `{"host": "node1", "cpu": 95}` |
| `events/cpu_50.json` | `{"host": "node1", "cpu": 50}` |
| `events/cpu_95_str.json` | `{"host": "node1", "cpu": "95"}` |

![run_command.png](https://raw.githubusercontent.com/irixjp/aitac-contents/main/101_ansible_basic/images/run_command.png)
`curl -H 'Content-Type: application/json' -d @events/cpu_95.json http://localhost:5000/endpoint`

```text
** 2026-11-10 07:38:07.849417 [debug] ******************************************
CPU 使用率が危険域です: node1 95%
********************************************************************************
```

![run_command.png](https://raw.githubusercontent.com/irixjp/aitac-contents/main/101_ansible_basic/images/run_command.png)
`curl -H 'Content-Type: application/json' -d @events/cpu_50.json http://localhost:5000/endpoint`

`cpu` が 50 のため、何も表示されません（受信のログだけが表示されます）。

![run_command.png](https://raw.githubusercontent.com/irixjp/aitac-contents/main/101_ansible_basic/images/run_command.png)
`curl -H 'Content-Type: application/json' -d @events/cpu_95_str.json http://localhost:5000/endpoint`

```text
2026-11-10 07:38:11 834 [drools-async-evaluator-thread] ERROR org.drools.ansible.rulebook.integration.api.domain.constraints.RulebookConstraintOperator - Cannot compare values of different types: str and int. RuleSet: conditions rulebook. RuleName: cpu critical. Condition: {lhs={Event=payload.cpu}, rhs={Integer=90}}
```

`cpu_95_str.json` の `"95"` は、ダブルクォートで囲まれているため文字列です。文字列と数値は比較できないため、エラーが表示され、ルールは動きません。同じ 95 に見えても、イベントのデータ型が違えば条件は当てはまりません。イベントを送る側（監視ツールなど）がどのような型で値を送ってくるかを、事前に確認しておく必要があります。

### 🔸ルールの順番

次に、もう一段低いしきい値のルールを `cpu critical` の下に追加します。

![edit_file.png](https://raw.githubusercontent.com/irixjp/aitac-contents/main/101_ansible_basic/images/edit_file.png)
`~/eda/working/conditions_rulebook.yml`
```yaml
---
- name: conditions rulebook
  hosts: all
  sources:
  - ansible.eda.webhook:
      host: 0.0.0.0
      port: 5000

  rules:
  - name: cpu critical
    condition: event.payload.cpu >= 90
    action:
      debug:
        msg: "CPU 使用率が危険域です: {{ event.payload.host }} {{ event.payload.cpu }}%"

  - name: cpu warning
    condition: event.payload.cpu >= 80
    action:
      debug:
        msg: "CPU 使用率が高くなっています: {{ event.payload.host }} {{ event.payload.cpu }}%"
```

rulebook を起動し直し、`events/cpu_85.json`（`{"host": "node1", "cpu": 85}`）と `events/cpu_95.json` を順に送ってください。

![run_command.png](https://raw.githubusercontent.com/irixjp/aitac-contents/main/101_ansible_basic/images/run_command.png)
`curl -H 'Content-Type: application/json' -d @events/cpu_85.json http://localhost:5000/endpoint`

```text
** 2026-11-10 07:38:13.850329 [debug] ******************************************
CPU 使用率が高くなっています: node1 85%
********************************************************************************
```

![run_command.png](https://raw.githubusercontent.com/irixjp/aitac-contents/main/101_ansible_basic/images/run_command.png)
`curl -H 'Content-Type: application/json' -d @events/cpu_95.json http://localhost:5000/endpoint`

```text
** 2026-11-10 07:38:07.849417 [debug] ******************************************
CPU 使用率が危険域です: node1 95%
********************************************************************************
```

95 は `cpu warning` の条件（80 以上）にも当てはまりますが、動いたのは `cpu critical` だけです。ansible-rulebook は、既定では 1 つのイベントに対して、上から順に判定して最初に当てはまったルールだけを動かします。そのため、より厳しい条件（より限定的な条件）のルールを上に書きます。仮に `cpu warning` を上に書くと、95 のイベントでも `cpu warning` だけが動き、`cpu critical` は動かなくなります。

> Note: 当てはまったルールをすべて動かしたい場合は、ruleset に `match_multiple_rules: true` を指定します。詳しくは [Rulebook のドキュメント](https://docs.ansible.com/projects/rulebook/en/latest/rulebooks.html) を確認してください。


## ステップ2: and / or / not

複数の条件を組み合わせます。重要度（`severity`）が `critical` のアラートを、重要なホスト（node1、node2）とそれ以外とで分けて扱うルールを作成します。`rules` の末尾に以下の 2 つのルールを追記してください。

![edit_file.png](https://raw.githubusercontent.com/irixjp/aitac-contents/main/101_ansible_basic/images/edit_file.png)
`~/eda/working/conditions_rulebook.yml`（`rules` の末尾に追記）
```yaml
  - name: critical on important hosts
    condition: event.payload.severity == "critical" and (event.payload.host == "node1" or event.payload.host == "node2")
    action:
      debug:
        msg: "重要なホストで critical が発生しました: {{ event.payload.host }}"

  - name: critical on other hosts
    condition: event.payload.severity == "critical" and not (event.payload.host == "node1" or event.payload.host == "node2")
    action:
      debug:
        msg: "その他のホストで critical が発生しました: {{ event.payload.host }}"
```

- `and`: 両方の条件が当てはまる
- `or`: どちらかの条件が当てはまる
- `not`: 条件が当てはまらない

`( )` で囲んだ部分が先に判定されます。`critical on important hosts` は「severity が critical」かつ「host が node1 または node2」、`critical on other hosts` は「severity が critical」かつ「host が node1 でも node2 でもない」という意味になります。

rulebook を起動し直し、以下の 3 つのイベントを順に送ってください。

| ファイル | 内容 |
|---|---|
| `events/critical_node1.json` | `{"host": "node1", "severity": "critical"}` |
| `events/critical_node3.json` | `{"host": "node3", "severity": "critical"}` |
| `events/warning_node1.json` | `{"host": "node1", "severity": "warning"}` |

![run_command.png](https://raw.githubusercontent.com/irixjp/aitac-contents/main/101_ansible_basic/images/run_command.png)
`curl -H 'Content-Type: application/json' -d @events/critical_node1.json http://localhost:5000/endpoint`

```text
** 2026-11-10 07:38:15.865936 [debug] ******************************************
重要なホストで critical が発生しました: node1
********************************************************************************
```

![run_command.png](https://raw.githubusercontent.com/irixjp/aitac-contents/main/101_ansible_basic/images/run_command.png)
`curl -H 'Content-Type: application/json' -d @events/critical_node3.json http://localhost:5000/endpoint`

```text
** 2026-11-10 07:38:17.875023 [debug] ******************************************
その他のホストで critical が発生しました: node3
********************************************************************************
```

![run_command.png](https://raw.githubusercontent.com/irixjp/aitac-contents/main/101_ansible_basic/images/run_command.png)
`curl -H 'Content-Type: application/json' -d @events/warning_node1.json http://localhost:5000/endpoint`

`severity` が `warning` のため、どちらのルールも動きません。


## ステップ3: 文字列のパターン

ログのメッセージのような文字列は、完全に一致するかどうかではなく、特定の語を含むかどうかで判定したい場合がほとんどです。このような場合は `is search` や `is match` を使います。`rules` の末尾に以下の 2 つのルールを追記してください。

![edit_file.png](https://raw.githubusercontent.com/irixjp/aitac-contents/main/101_ansible_basic/images/edit_file.png)
`~/eda/working/conditions_rulebook.yml`（`rules` の末尾に追記）
```yaml
  - name: timeout in log
    condition: event.payload.log is search("timeout", ignorecase=true)
    action:
      debug:
        msg: "タイムアウトのログです: {{ event.payload.host }} {{ event.payload.log }}"

  - name: error log
    condition: event.payload.log is match("ERROR")
    action:
      debug:
        msg: "エラーのログです: {{ event.payload.host }} {{ event.payload.log }}"
```

| 書き方 | 意味 |
|---|---|
| `is search("パターン")` | 文字列のどこかにパターンが含まれる |
| `is match("パターン")` | 文字列の先頭がパターンに一致する |
| `is regex("パターン")` | 文字列のどこかにパターンが含まれる（`search` と同じ動き） |

パターンには正規表現が使えます。`ignorecase=true` を指定すると、大文字と小文字を区別しません。

rulebook を起動し直し、以下の 3 つのイベントを順に送ってください。

| ファイル | 内容 |
|---|---|
| `events/log_timeout.json` | `{"host": "node2", "log": "WARN: read TIMEOUT from db server"}` |
| `events/log_error.json` | `{"host": "node2", "log": "ERROR: failed to write /var/log/app.log"}` |
| `events/log_no_error.json` | `{"host": "node2", "log": "INFO: no ERROR found in last check"}` |

![run_command.png](https://raw.githubusercontent.com/irixjp/aitac-contents/main/101_ansible_basic/images/run_command.png)
`curl -H 'Content-Type: application/json' -d @events/log_timeout.json http://localhost:5000/endpoint`

```text
** 2026-11-10 07:38:21.901876 [debug] ******************************************
タイムアウトのログです: node2 WARN: read TIMEOUT from db server
********************************************************************************
```

`TIMEOUT` は大文字ですが、`ignorecase=true` を指定しているため当てはまります。

![run_command.png](https://raw.githubusercontent.com/irixjp/aitac-contents/main/101_ansible_basic/images/run_command.png)
`curl -H 'Content-Type: application/json' -d @events/log_error.json http://localhost:5000/endpoint`

```text
** 2026-11-10 07:38:23.916738 [debug] ******************************************
エラーのログです: node2 ERROR: failed to write /var/log/app.log
********************************************************************************
```

![run_command.png](https://raw.githubusercontent.com/irixjp/aitac-contents/main/101_ansible_basic/images/run_command.png)
`curl -H 'Content-Type: application/json' -d @events/log_no_error.json http://localhost:5000/endpoint`

このログにも `ERROR` という語は含まれていますが、先頭ではないため `is match("ERROR")` には当てはまらず、何も表示されません。`is search` と `is match` の違いを確認してください。


## ステップ4: 項目の有無

ここまでのルールは、イベントに `host` が含まれていることを前提にしています。`host` を含まないイベントが届いた場合にどうなるかを確認します。rulebook を起動したまま、`events/no_host.json`（`{"cpu": 95}`）を送ってください。

![run_command.png](https://raw.githubusercontent.com/irixjp/aitac-contents/main/101_ansible_basic/images/run_command.png)
`curl -H 'Content-Type: application/json' -d @events/no_host.json http://localhost:5000/endpoint`

```text
2026-11-10 07:36:55,199 - ansible_rulebook.rule_set_runner - ERROR - Undefined jinja variable  'host' in action debug
```

`cpu critical` のルールに当てはまりましたが、メッセージの `{{ event.payload.host }}` が存在しないため、アクションがエラーになりました。アクションが playbook の実行であれば、対象のノードが分からないまま実行しようとすることになります。

このような想定外のイベントは、ほかのルールより先に見分けて扱います。`rules` の **先頭** に以下のルールを追記してください。

![edit_file.png](https://raw.githubusercontent.com/irixjp/aitac-contents/main/101_ansible_basic/images/edit_file.png)
`~/eda/working/conditions_rulebook.yml`（`rules` の先頭に追記）
```yaml
  rules:
  - name: event without host
    condition: event.payload is defined and event.payload.host is not defined
    action:
      debug:
        msg: "host が含まれていないイベントです: {{ event.payload }}"

  - name: cpu critical
（以下、これまでのルール）
```

- `is defined`: その項目がイベントに存在する
- `is not defined`: その項目がイベントに存在しない

ステップ1で確認したとおり、ルールは上から順に判定され、最初に当てはまったルールだけが動きます。このルールを先頭に置くことで、`host` を含まないイベントは、ここで止まり、後ろのルールでは扱われなくなります。

rulebook を起動し直し、もう一度 `events/no_host.json` を送ってください。

![run_command.png](https://raw.githubusercontent.com/irixjp/aitac-contents/main/101_ansible_basic/images/run_command.png)
`curl -H 'Content-Type: application/json' -d @events/no_host.json http://localhost:5000/endpoint`

```text
** 2026-11-10 07:38:27.943191 [debug] ******************************************
host が含まれていないイベントです: {'cpu': 95}
********************************************************************************
```

> Note: `is not defined` は、`event.payload.host is not defined` のように単独で書くと、意図どおりに動きません。単独で書いた場合、「そのようなイベントが存在しない」という意味で判定されるため、rulebook の起動直後に空のイベントで一度だけ動き、その後に届いたイベントには反応しません。届いたイベントの項目の有無を調べるときは、`event.payload is defined and ...` のように、イベントに必ず存在する項目の条件と組み合わせて書きます。

これまでのイベントを送って、ステップ1〜3 のルールが変わらずに動くことも確認してください。確認が終わったら、左側のターミナルで `Ctrl+C` を押して rulebook を停止してください。


## その他の条件

ここで扱った以外にも、条件には以下のような書き方があります。詳しくは [Conditions のドキュメント](https://docs.ansible.com/projects/rulebook/en/latest/conditions.html) を確認してください。

- リストに含まれるか（`in`、`not in`、`contains`）
- リストの要素を条件で判定する（`is select`、`is selectattr`）
- rulebook の外から渡した変数（`--vars`、`vars.変数名`）と比較する
- 複数のイベントを組み合わせる（`all`、`any`）: 次の演習で扱います
- 同じイベントの繰り返しを抑える（`throttle`）: その次の演習で扱います


## 演習の解答

- [conditions\_rulebook.yml](https://github.com/irixjp/aitac-contents/blob/main/201_event-driven-ansible/solutions/conditions_rulebook.yml)
