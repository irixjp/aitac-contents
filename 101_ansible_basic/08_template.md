# テンプレートとフィルター

Ansible はテンプレート機能を備えており、動的なファイル作成が可能です。テンプレートエンジンとしては [`jinja2`](https://palletsprojects.com/projects/jinja/) を利用しています。

テンプレートはとても汎用性の高い機能で、様々な状況で活用できます。アプリ用のコンフィグファイルを動的に生成して配布したり、各ノードから収集した情報を元にレポートを作成することが可能です。

## Jinja2 

テンプレートを利用するには2つの要素が必要になります。

- テンプレートファイル: jinja2 形式の表現が埋め込まれたファイルで、一般的に j2 拡張子を付加します。
- [`ansible.builtin.template`](https://docs.ansible.com/projects/ansible/latest/collections/ansible/builtin/template_module.html) モジュール: コピーモジュールに似ています。src にテンプレートファイルを指定し、dest に配置先を指定すると、テンプレートファイルをコピーする際に、jinja2 部分を処理してからファイルをコピーします。

実際にテンプレートを作成します。

`~/working/templates/index.html.j2` ファイルを作成し、中身を以下となるように編集してください。このファイルが `jinja2` テンプレートファイルになります。

![edit_file.png](https://raw.githubusercontent.com/irixjp/aitac-automation/main/101_ansible_basic/images/edit_file.png)
`~/working/templates/index.html.j2`
```jinja2
<html><body>
<h1>This server is running on {{ inventory_hostname }}.</h1>

{% if LANG == "JP" %}
     Konnichiwa!
{% else %}
     Hello!
{% endif %}
</body></html>
```

このファイルは一見すると単純な HTML ファイルに見えますが、`{{ }}` や `{% %}` で囲われた部分が存在しています。この部分がテンプレートエンジンにより展開される `Jinja2` 表現に該当します。

- `{{ }}` 内の変数を評価し、値をカッコの場所に埋め込みます。
- `{% %}` には制御文を埋め込むことができます。

詳細な解説を行う前に、まず `~/working/template_playbook.yml` を作成して、実際にテンプレートを動かしてみましょう。以下のように `template_playbook.yml` を編集してください。

![edit_file.png](https://raw.githubusercontent.com/irixjp/aitac-automation/main/101_ansible_basic/images/edit_file.png)
`~/working/template_playbook.yml`
```yaml
---
- name: using template
  hosts: web
  become: yes
  tasks:
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
        src: templates/index.html.j2
        dest: /var/www/html/index.html
```

- `template:` テンプレートモジュールを呼び出しています。

ではこの playbook を動かしてみます。

![run_command.png](https://raw.githubusercontent.com/irixjp/aitac-automation/main/101_ansible_basic/images/run_command.png)
`cd ~/working`

![run_command.png](https://raw.githubusercontent.com/irixjp/aitac-automation/main/101_ansible_basic/images/run_command.png)
`ansible-playbook template_playbook.yml -e 'LANG=JP'`

```text
(省略)
TASK [Put index.html from template] **********************
changed: [node2]
changed: [node3]
changed: [node1]
(省略)
```

どのような結果になったかを確認してみましょう。以下のコマンドを実行してください。

![run_command.png](https://raw.githubusercontent.com/irixjp/aitac-automation/main/101_ansible_basic/images/run_command.png)
`ansible web -m ansible.builtin.uri -a 'url=http://localhost/ return_content=yes'`

このコマンドは [`ansible.builtin.uri`](https://docs.ansible.com/projects/ansible/latest/collections/ansible/builtin/uri_module.html) モジュールという HTTPリクエストを発行するモジュールを利用しています。このモジュールを使って、それぞれのノード上から `http://localhost/` へアクセスしてコンテンツを取得しています。

```text
node1 | SUCCESS => {
    (省略)
    "content": "<html><body>\n<h1>This server is running on node-1.</h1>\n\n<p>\n     Konnichiwa!\n</p>\n</body></html>\n",
    (省略)
    "url": "http://localhost/"
}
node2 | SUCCESS => {
    (省略)
    "content": "<html><body>\n<h1>This server is running on node-2.</h1>\n\n<p>\n     Konnichiwa!\n</p>\n</body></html>\n",
    (省略)
    "status": 200,
    "url": "http://localhost/"
}
node3 | SUCCESS => {
    (省略)
    "content": "<html><body>\n<h1>This server is running on node-3.</h1>\n\n<p>\n     Konnichiwa!\n</p>\n</body></html>\n",
    (省略)
    "status": 200,
    "url": "http://localhost/"
}
```

`content` キーに取得した `index.html` の内容が格納されています。この内容を確認すると、テンプレートファイル内の `{{ inventory_hostname }}` の部分はホスト名に置き換えられ、`{% if LANG == "JP" %}` の部分には「Konnichiwa!」となっていることが確認できます。

では、条件を変えて `LANG == "JP"` が成立しない場合にはどうなるか確認してください。

![run_command.png](https://raw.githubusercontent.com/irixjp/aitac-automation/main/101_ansible_basic/images/run_command.png)
`ansible-playbook template_playbook.yml -e 'LANG=EN'`

![run_command.png](https://raw.githubusercontent.com/irixjp/aitac-automation/main/101_ansible_basic/images/run_command.png)
`ansible web -m ansible.builtin.uri -a 'url=http://localhost/ return_content=yes'`

今度の実行では、「Hello!」と挿入されたことが確認できるはずです。
以下の手順でブラウザから確認することも可能です。

![run_command.png](https://raw.githubusercontent.com/irixjp/aitac-automation/main/101_ansible_basic/images/run_command.png)
`curl 169.254.169.254/latest/meta-data/public-ipv4`

- node1: http://<自分の code-server IPアドレス>:8081
- node2: http://<自分の code-server IPアドレス>:8082
- node3: http://<自分の code-server IPアドレス>:8083

このようにテンプレートを使うことで、動的にファイルの生成を行うことが可能になります。この機能はとても応用範囲が広く、設定ファイルの自動生成や設定報告書の自動作成など様々な場面で活用できます。


## Filter

Jinja2 の機能の一つで [`filter`](https://docs.ansible.com/projects/ansible/latest/playbook_guide/playbooks_filters.html) があります。これは `{{ }}` で変数を展開する際に利用でき、変数の値を簡易的に加工することができます。この機能は playbook 内でも利用可能です。

フィルターを利用するには `{{ var_name | filter_name }}` という形式で利用します。いつくか例をみてみましょう。


### 🔸default フィルター

変数に値が入っていない場合に、初期値を設定してくれるフィルターです。

![run_command.png](https://raw.githubusercontent.com/irixjp/aitac-automation/main/101_ansible_basic/images/run_command.png)
`ansible node1 -m ansible.builtin.debug -a 'msg={{ hoge | default("abc") }}'`

```text
node1 | SUCCESS => {
    "msg": "abc"
}
```

### 🔸upper/lower フィルター

文字列を大文字・小文字に変換するフィルターです。

![run_command.png](https://raw.githubusercontent.com/irixjp/aitac-automation/main/101_ansible_basic/images/run_command.png)
`ansible node1 -e 'str=abc' -m ansible.builtin.debug -a 'msg="{{ str | upper }}"'`

```text
node1 | SUCCESS => {
    "msg": "ABC"
}
```

### 🔸min/max フィルター

リストから最小・最大値を取り出すフィルターです。

![run_command.png](https://raw.githubusercontent.com/irixjp/aitac-automation/main/101_ansible_basic/images/run_command.png)
`ansible node1 -m ansible.builtin.debug -a 'msg="{{ [5, 1, 10] | min }}"'`

```text
node1 | SUCCESS => {
    "msg": "1"
}
```

![run_command.png](https://raw.githubusercontent.com/irixjp/aitac-automation/main/101_ansible_basic/images/run_command.png)
`ansible node1 -m ansible.builtin.debug -a 'msg="{{ [5, 1, 10] | max }}"'`

```text
node1 | SUCCESS => {
    "msg": "10"
}
```

他にも多数のフィルターが実装されていますので、状況に応じて使い分けることでより簡単に playbook が作成できるようになります。

## 演習の解答

- [template\_html\_playbook.yml](https://github.com/irixjp/aitac-automation/blob/main/101_ansible_basic/solutions/template_playbook.yml)
- [files/index.html.j2](https://github.com/irixjp/aitac-automation/blob/main/101_ansible_basic/solutions/templates/index.html.j2)
