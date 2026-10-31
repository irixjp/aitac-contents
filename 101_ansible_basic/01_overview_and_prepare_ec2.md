# 演習の概要と環境の準備
ここでは演習環境の概要の解説と、演習環境の準備を行います。

## 演習環境について
本演習環境は以下のように構成されています。

![environment.png](https://raw.githubusercontent.com/irixjp/aitac-automation/main/101_ansible_basic/images/environment.png)


## 演習環境への利用方法

### 🔸演習環境へのアクセス
講師の案内に従い演習環境へアクセスしてください。アクセスにはパスワードの入力が必要となります。

![vscode_pass.png](https://raw.githubusercontent.com/irixjp/aitac-automation/main/101_ansible_basic/images/vscode_pass.png)

アクセスすると以下のような画面が表示されます。

![vscode_start_page](https://raw.githubusercontent.com/irixjp/aitac-automation/main/101_ansible_basic/images/vscode_start_page.png)

### 🔸ファイルエクスプローラーの設定

画面左上の ![file_exp_icon.png](https://raw.githubusercontent.com/irixjp/aitac-automation/main/101_ansible_basic/images/file_exp_icon.png) をクリックします。

左ウインドにファイルエクスプローラーが起動しますので、`Open Folder` を選択する。

![file_exp_open_folder.png](https://raw.githubusercontent.com/irixjp/aitac-automation/main/101_ansible_basic/images/file_exp_open_folder.png)

`/student/` (デフォルトのまま) を入力してOKを選択すると、ファイルエクスプローラーに `/student` が表示されます。演習中のファイル作成や編集をここから行います。

![select_dir.png](https://raw.githubusercontent.com/irixjp/aitac-automation/main/101_ansible_basic/images/select_dir.png)

このときに、いくつかの警告が表示される場合がありますが `Yes` を選択してください。

![notification.png](https://raw.githubusercontent.com/irixjp/aitac-automation/main/101_ansible_basic/images/notification.png)

> Note: この後も警告が表示される場合はありますが、全て `Yes` や `Accept` を選択してください。

### 🔸ターミナルの起動

画面左上側の「≡」(横三本線)アイコンをクリックして、`Terminal` -> `New Terminal` を選択するとターミナルを起動できます。

![open_terminal.png](https://raw.githubusercontent.com/irixjp/aitac-automation/main/101_ansible_basic/images/open_terminal.png)

起動すると以下のような画面になります。

![terminal.png](https://raw.githubusercontent.com/irixjp/aitac-automation/main/101_ansible_basic/images/terminal.png)

ターミナルを起動したら動作確認を行います。以下のコマンドをターミナルから実行してください。

> Note: 本演習では ![run_command.png](https://raw.githubusercontent.com/irixjp/aitac-automation/main/101_ansible_basic/images/run_command.png) とついている部分が演習で実行するコマンドになります。

![run_command.png](https://raw.githubusercontent.com/irixjp/aitac-automation/main/101_ansible_basic/images/run_command.png)
`ansible --version`

```text
ansible [core 2.20.0]
  config file = /student/.ansible.cfg
  configured module search path = ['/student/.ansible/plugins/modules', '/usr/share/ansible/plugins/modules']
  ansible python module location = /student/.local/lib/python3.12/site-packages/ansible
  ansible collection location = /student/.ansible/collections:/usr/share/ansible/collections
  executable location = /student/.local/bin/ansible
  python version = 3.12.11 (main, Aug 14 2025, 00:00:00) [GCC 14.3.1 20250617 (Red Hat 14.3.1-2)] (/usr/bin/python3)
  jinja version = 3.1.6
  pyyaml version = 6.0.3 (with libyaml v0.2.5)
```

![run_command.png](https://raw.githubusercontent.com/irixjp/aitac-automation/main/101_ansible_basic/images/run_command.png)
`ansible all -m ping -o`

```text
node1 | SUCCESS => {"changed": false,"ping": "pong"}
node2 | SUCCESS => {"changed": false,"ping": "pong"}
node3 | SUCCESS => {"changed": false,"ping": "pong"}
node4 | SUCCESS => {"changed": false,"ping": "pong"}
node5 | SUCCESS => {"changed": false,"ping": "pong"}
node6 | SUCCESS => {"changed": false,"ping": "pong"}
```

> Note: 表示されるバージョン等の差異については無視してください。コマンドがエラーにならなければ演習が可能な状態になっています。

> Note: 起動したターミナルはドラッグして移動することて表示位置を変更できます。演習が進めやすいように各自配置を調整してください。

### 🔸補足事項

本演習環境でファイルを編集する場合には左側のファイルブラウザからファイルを開くことでエディタを起動できます（ターミナル内で vi を使うことも可能です）。

一部のファイル形式(.md や .html) はファイルブラウザからダブルクリックで開くとプレビュー表示となります。ファイルを編集したい場合は「右クリック」 → 「Open with」 から Editor を選択してください。

