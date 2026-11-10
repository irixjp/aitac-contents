# Ad-Hocコマンドとモジュール

ここでは Ansible における重要な要素である `Module` (モジュール) と、モジュールを実行するための `Ad-hoc コマンド` について学習します。

![ansible_structure.png](https://raw.githubusercontent.com/irixjp/aitac-contents/main/101_ansible_basic/images/ansible_structure.png)

## モジュールとは

モジュールとは「インフラ作業でよくある操作を部品化」したものです。Ansible は膨大な数のモジュールを備えています。正確な表現ではないですが、「インフラ作業におけるライブラリ集」だと言うこともできるかもしれません。

モジュールが提供されることで、自動化の記述をシンプルにすることができます。1つの例として、Ansible で提供される `dnf` モジュールについて見てみます。

この `dnf` モジュールはOSに対してパッケージの管理を行うモジュールです。このモジュールにパラメーターを渡すことでパッケージのインストールや削除を行うことができます。ここで、同じ動作をするシェルスクリプトを記述することを考えてみましょう。

最も単純に実装すると以下のようになります。
```bash
function dnf_install () {
    PKG=$1
    dnf install -y ${PKG}
}
```
> Note: スクリプト内容は動作を説明するためのもので正確ではありません

実際に利用するにはこのスクリプトでは不十分です。例えば、インストールしようとしたパッケージがすでにインストールされている場合を考慮しなければなりません。すると以下のようになるはずです。

```bash
function dnf_install () {
    PKG=$1
    if [ Does this package already exist? ]; then
        exit 0
    else
        dnf install -y ${PKG}
    fi
}
```
> Note: スクリプト内容は動作を説明するためのもので正確ではありません

しかし、まだこれでも不十分です。パッケージが既にインストールされているとして、そのパッケージのバージョンが、いまからインストールするものよりも古い、同じ、新しいといったケースではどうすればよいでしょうか？このケースも考慮するようにスクリプトを拡張しましょう。

```bash
function dnf_install () {
    PKG=$1
    VERSION=$2
    if [ Does this package already exist? ]; then
        case ${VERSION} in
            lower ) dnf install -y ${PKG} ;;
            same ) exit 0
            higher ) exit 0
    else
        dnf install -y ${PKG}
    fi
}
```
> Note: スクリプト内容は動作を説明するためのもので正確ではありません

このように、パッケージをインストールするという単純な動作でも、ゼロから実装しようとすると様々な考慮事項が発生し、それに対応するための実装が必要となっていきます。実装が増えれば当然ロジックも複雑化し、バグも発生しやすくなり、メンテナンスのコストも増えてしまいます。しかもこういった基本的なインフラ操作における自動化は世界中で行われており、各人が車輪の再発明を日々繰り返しており、膨大な無駄が生じています。

これらの無駄を排除し、皆のナレッジを集約して品質の高いインフラ自動化を実現するために Ansible のモジュールが存在しています。モジュールには「インフラを自動化するときによくある考慮事項」が予め組み込まれており、ユーザーは細かな制御を実装することなく自動化を実装可能になります。つまり、車輪の再発明を避けて、本来やりたい自動化の実装に集中することができ、結果として自動化の記述量を大幅に減らすことへとつながります。

## モジュールの一覧

モジュールは`collection`という形式で管理され、それぞれのcollectionには関連するモジュールが複数含まれています。[Collectionの一覧](https://docs.ansible.com/projects/ansible/latest/collections/index.html) から必要に応じて自分の利用したい collection を探し、インストールして利用します。

> Note: バージョン 2.9 までのAnsibleはデフォルトで全てのモジュールが含んでおりましたが、あまりにモジュールの数が増えすぎてしまったため、現在の形式へと変更されました(2.10以降)

初期インストール状態のAnsibleは `ansible.builtin` コレクションのみがインストールされています。ansible.builtin がもつモジュールの一覧は [こちら](https://docs.ansible.com/projects/ansible/latest/collections/ansible/builtin/index.html#modules) から確認できます。

> Note: Collection の扱い方については後続の演習に含まれます。

現在の環境でどのようなモジュールが利用可能になっているかは `ansible-doc` コマンドで参照することができます。
このコマンドはインストール済みのモジュールの一覧を表示します。

![run_command.png](https://raw.githubusercontent.com/irixjp/aitac-contents/main/101_ansible_basic/images/run_command.png)
`ansible-doc -l`

```text
amazon.aws.autoscaling_group                   Create or delete AWS AutoScaling Groups (ASGs)
amazon.aws.autoscaling_group_info              Gather information about EC2 Auto Scaling Groups (ASGs) in AWS 
amazon.aws.autoscaling_instance                manage instances associated with AWS AutoScaling Groups (ASGs) 
amazon.aws.autoscaling_instance_info           describe instances associated with AWS AutoScaling Groups (ASGs...
amazon.aws.autoscaling_instance_refresh        Start or cancel an EC2 Auto Scaling Group (ASG) instance refres...
(省略)
```
> Note: f で進む、b で戻る、q で終了。

特定のモジュールのドキュメントを参照するには以下のように実行します。

![run_command.png](https://raw.githubusercontent.com/irixjp/aitac-contents/main/101_ansible_basic/images/run_command.png)
`ansible-doc ansible.builtin.dnf`

```text
> MODULE ansible.builtin.dnf (/student/.local/lib/python3.12/site-packages/ansible/modules/dnf.py)

  Installs, upgrade, removes, and lists packages and groups with the dnf package manager.

  * note: This module has a corresponding action plugin.

OPTIONS (red indicates it is required):
(省略)
```
> Note: f で進む、b で戻る、q で終了。

モジュールのドキュメントでは、モジュールに与えられるパラメーターの説明や、モジュールが実行された後の戻り値、そして実際の利用方法のサンプル(Examples)が参照できます。

> Note: モジュールの利用方法の Examples は非常に参考になります。

## Ad-hoc コマンド

これらのモジュールをAnsibleで1つだけ実行して Ansible に小さな仕事を実行させることができます。この方法を `Ad-hoc コマンド` とよびます。

コマンドの形式は以下になります。

```bash
$ ansible all -m <module_name> -a '<parameters>'
```

- `-m <module_name>`: モジュール名を指定します。
- `-a <parameters>`: モジュールにわたすパラメーターを指定します。省略可能な場合もあります。

Ad-hoc コマンドを利用して、いくつかのモジュールを実際に動作させてみましょう。

### 🔸ansible.builtin.ping

[`ansible.builtin.ping`](https://docs.ansible.com/projects/ansible/latest/collections/ansible/builtin/ping_module.html) モジュールを実行してみましょう。これは Ansible が操作対象のノードに対して「Ansible としての疎通」が可能かどうかを判定するモジュールです(ネットワークで利用するICMPとは意味合いが異なります)。pingモジュールのパラメーターは省略可能です。

![run_command.png](https://raw.githubusercontent.com/irixjp/aitac-contents/main/101_ansible_basic/images/run_command.png)
`ansible all -m ansible.builtin.ping`

```text
node2 | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
node1 | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
(省略)
```


### 🔸ansible.builtin.shell

次に、[`shell`](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/shell_module.html) モジュールを呼び出してみましょう。これは対象のノード上で任意のコマンドを実行し、その結果を回収するコマンドです。

![run_command.png](https://raw.githubusercontent.com/irixjp/aitac-contents/main/101_ansible_basic/images/run_command.png)
`ansible all -m ansible.builtin.shell -a 'hostname'`

```text
node2 | CHANGED | rc=0 >>
node2
node1 | CHANGED | rc=0 >>
node1
node3 | CHANGED | rc=0 >>
node3
node4 | CHANGED | rc=0 >>
(省略)
```

他にもいくつかのコマンドを実行して結果を確かめてください。

カーネル情報を取得する

![run_command.png](https://raw.githubusercontent.com/irixjp/aitac-contents/main/101_ansible_basic/images/run_command.png)
`ansible all -m ansible.builtin.shell -a 'uname -a'`


日付を取得する

![run_command.png](https://raw.githubusercontent.com/irixjp/aitac-contents/main/101_ansible_basic/images/run_command.png)
`ansible all -m ansible.builtin.shell -a 'date'`

> Note: UTCで表示されるため、+9時間すると日本の時間になります。

ディスクの使用状況を取得する

![run_command.png](https://raw.githubusercontent.com/irixjp/aitac-contents/main/101_ansible_basic/images/run_command.png)
`ansible all -m ansible.builtin.shell -a 'df -h'`

インストールされたパッケージの情報から特定の情報を抽出する

![run_command.png](https://raw.githubusercontent.com/irixjp/aitac-contents/main/101_ansible_basic/images/run_command.png)
`ansible all -m ansible.builtin.shell -a 'rpm -qa |grep bash'`


### 🔸ansible.builtin.dnf

[`ansible.builtin.dnf`](https://docs.ansible.com/projects/ansible/latest/collections/ansible/builtin/dnf_module.html#ansible-collections-ansible-builtin-dnf-module)はパッケージの操作を行うモジュールです。このモジュールを利用して新しくパッケージをインストールしてみます。

今回は tmux パッケージをインストールします。まず現在の環境に tmux がインストールされていないことを確認します。

![run_command.png](https://raw.githubusercontent.com/irixjp/aitac-contents/main/101_ansible_basic/images/run_command.png)
`ansible node1 -m ansible.builtin.shell -a 'which tmux'`

```text
ERROR]: Task failed: Module failed: non-zero return code
Origin: <adhoc 'ansible.builtin.shell' task>

{'action': 'ansible.builtin.shell', 'args': {'_raw_params': 'which tmux'}, 'timeout': 0, 'async_val': 0, 'poll': 15}

node1 | FAILED | rc=1 >>
which: no tmux in (/home/student/.local/bin:/home/student/bin:/usr/local/bin:/usr/bin:/usr/local/sbin:/usr/sbin)non-zero return code
```

このコマンドはまだ tmux がインストールされていないためエラーになるはずです。

では、 ansible.builtin.dnf モジュールで tmux のインストールを行います。

![run_command.png](https://raw.githubusercontent.com/irixjp/aitac-contents/main/101_ansible_basic/images/run_command.png)
`ansible node1 -b -m ansible.builtin.dnf -a 'name=tmux state=latest'`

```text
node1 | CHANGED => {
    "ansible_facts": {
        "pkg_mgr": "dnf"
    },
    "changed": true,
    "msg": "",
    "rc": 0,
    "results": [
        "Installed: tmux-3.3a-13.20230918gitb202a2f.el10.x86_64"
    ]
}
```

- `-b`: become オプション。これは接続先のノードでの操作に root 権限を利用するためのオプションです。パッケージのインストールには root 権限が必要となるため、このオプションをつけています。つけない場合、このコマンドは失敗します。

再度、tmux コマンドの確認を行うと、今度はパッケージがインストールされたため成功するはずです。

![run_command.png](https://raw.githubusercontent.com/irixjp/aitac-contents/main/101_ansible_basic/images/run_command.png)
`ansible node1 -m ansible.builtin.shell -a 'which tmux'`

```text
node1 | CHANGED | rc=0 >>
/usr/bin/tmux
```

### 🔸ansible.builtin.setup

[`ansible.builtin.setup`](https://docs.ansible.com/projects/ansible/latest/collections/ansible/builtin/setup_module.html) は対象ノードの情報を取得するモジュールです。取得された情報は `ansible_xxx` という変数名で自動的にアクセス可能となります。

出力される情報量が多いため、1台のノードのみに実行します。

![run_command.png](https://raw.githubusercontent.com/irixjp/aitac-contents/main/101_ansible_basic/images/run_command.png)
`ansible node1 -m ansible.builtin.setup`

このように Ansible は様々なモジュールを持ち、これらを使ってノードに対して操作を行ったり、情報収集を行うことが可能です。


次の演習ではこれらモジュールを使って実際に `Playbook` を作成します。
