# AITAC インフラ自動化演習（Event-Driven Ansible）

本演習は、`Event-Driven Ansible`（EDA）を題材として、イベントをきっかけに自動化を動かす仕組みの基礎を習得することを目的とします。

本演習は「インフラ自動化演習（Ansible 基礎）」の内容（インベントリー、モジュール、playbook、変数）を理解していることを前提としています。

## 演習に必要な環境

本演習では以下の環境を必要とします。

- インターネット接続可能なPC
  - VPNやプロキシ経由では接続できない場合があります。
- インターネットブラウザ(最新版の Chrome, Firefox, Safari, Edge を推奨、IEでは実施不可)

演習環境へのアクセス方法、ファイルエクスプローラーとターミナルの使い方は「Ansible 基礎」の [演習の概要と環境の準備](../101_ansible_basic/01_overview_and_prepare_ec2.md) と同じです。

## 演習内容

以下の演習項目を指示に従い進めてください。各演習は自習可能な形態となっているため、インストラクターが不在でも進めることが可能です。

1. [Event-Driven Ansible の概要とデモ](01_overview_demo.md)
2. [運用の playbook をイベントで動かす](02_ops_rulebook.md)
3. [条件の書き方](03_conditions.md)
4. [複数のイベントを組み合わせる](04_multiple_events.md)
5. [同じイベントの繰り返しを抑える](05_throttle.md)

## 演習で使うディレクトリ

本演習のファイルは `~/eda` に配置されています。

- `~/eda/working`: 演習で使うファイルと、演習で編集するファイル
- `~/eda/solutions`: 演習の解答

## 演習教材について

本演習環境の素材は以下で管理されています。

- https://github.com/irixjp/aitac-contents


本演習環境で利用しているソフトウェアは以下になります。

- [ansible](https://github.com/ansible/ansible)
- [ansible-rulebook](https://github.com/ansible/ansible-rulebook)
- [ansible.eda collection](https://github.com/ansible/event-driven-ansible)
- [code-server](https://github.com/coder/code-server)
