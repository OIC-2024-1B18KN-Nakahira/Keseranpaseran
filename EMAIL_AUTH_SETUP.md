# メール認証機能セットアップガイド

このドキュメントでは、アカウント作成、パスワードリセット、メールアドレス変更時のメール認証機能のセットアップ方法を説明します。

## 実装した機能

1. **アカウント作成時のメール認証**
   - ユーザーがアカウントを作成すると、確認メールが送信されます
   - メール内のリンクをクリックすることでアカウントが有効化されます
   - 有効化後、自動的にusersテーブルにユーザー情報が保存されます

2. **パスワードリセット機能**
   - ログイン画面から「パスワードを忘れた方はこちら」をクリック
   - メールアドレスを入力すると、パスワードリセット用のメールが送信されます
   - メール内のリンクをクリックすると、新しいパスワードを設定できます

3. **メールアドレス変更機能**
   - 設定画面からメールアドレスを変更できます
   - 新しいメールアドレスに確認メールが送信されます
   - メール内のリンクをクリックすることで変更が完了します

## Supabaseの設定手順

### 1. メール認証を有効化

1. Supabaseダッシュボードにログイン
2. プロジェクトを選択
3. Authentication → Settings → Auth Providers
4. "Email" を有効化
5. "Confirm email" を有効化

### 2. メールテンプレートの設定

Authentication → Email Templates で以下のテンプレートを設定できます:

- **Confirm signup**: アカウント作成時の確認メール
- **Reset password**: パスワードリセットメール
- **Change email address**: メールアドレス変更の確認メール

### 3. リダイレクトURLの設定

Authentication → URL Configuration で以下のURLを追加:

```
io.supabase.flutter://login-callback/
io.supabase.flutter://reset-callback/
```

### 4. データベーストリガーの設定

`supabase_setup.sql` ファイルの内容をSupabase SQL Editorで実行してください。

1. Supabaseダッシュボードで SQL Editor を開く
2. `supabase_setup.sql` の内容をコピー&ペースト
3. "Run" をクリックして実行

このトリガーにより、メール認証完了後に自動的にusersテーブルにユーザー情報が保存されます。

### 5. Mailpit（開発用メールサーバー）の設定

開発環境でメールをテストするために、Mailpitを使用できます:

```bash
# Mailpitを起動
docker-compose up -d

# ブラウザで確認
# http://localhost:19980
```

Supabaseの設定でSMTPを以下のように設定:
- Host: localhost (またはコンテナのIPアドレス)
- Port: 19925
- Username: (空欄)
- Password: (空欄)

## 実装したファイル

### 新規作成したファイル

- `lib/acount_page/password_reset.dart`: パスワードリセット画面
- `lib/acount_page/password_update.dart`: 新しいパスワード設定画面
- `supabase_setup.sql`: データベーストリガーのSQL
- `EMAIL_AUTH_SETUP.md`: このドキュメント

### 更新したファイル

- `lib/acount_page/account_create.dart`: メール認証フローに変更
- `lib/acount_page/login.dart`: パスワードリセットリンクを追加
- `lib/setting_page/6_change_email.dart`: メール変更機能を実装
- `lib/router.dart`: 新しいルートを追加
- `lib/main.dart`: Deep Link処理を追加
- `android/app/src/main/AndroidManifest.xml`: Deep Link設定を追加

## テスト手順

### 1. アカウント作成のテスト

1. アプリを起動
2. 「アカウント作成」をクリック
3. 年齢と妊娠状態を設定
4. メールアドレスとパスワードを入力
5. 「アカウント作成」をクリック
6. Mailpit (http://localhost:19980) で確認メールを確認
7. メール内のリンクをクリック
8. アプリに戻り、ログインできることを確認

### 2. パスワードリセットのテスト

1. ログイン画面で「パスワードを忘れた方はこちら」をクリック
2. メールアドレスを入力
3. Mailpitでパスワードリセットメールを確認
4. メール内のリンクをクリック
5. 新しいパスワードを入力
6. 新しいパスワードでログインできることを確認

### 3. メールアドレス変更のテスト

1. ログイン後、設定画面に移動
2. 「メールアドレス変更」をクリック
3. 新しいメールアドレスを入力
4. Mailpitで確認メールを確認
5. メール内のリンクをクリック
6. メールアドレスが更新されたことを確認

## トラブルシューティング

### メールが届かない

- Supabaseのメール設定を確認
- MailpitのSMTP設定を確認
- Supabaseのログを確認（Authentication → Logs）

### Deep Linkが動作しない

- AndroidManifest.xmlの設定を確認
- アプリを再インストール
- デバイスの設定でデフォルトアプリをクリア

### データベースにユーザー情報が保存されない

- `supabase_setup.sql` のトリガーが正しく実行されているか確認
- Supabaseのログを確認
- usersテーブルのスキーマが正しいか確認

## 注意事項

1. 本番環境では、必ずSupabaseの正式なSMTPサービス（またはSendGrid、AWS SESなど）を設定してください
2. メールテンプレートをカスタマイズして、アプリに合わせたデザインにしてください
3. リダイレクトURLは、本番環境のURLスキームに合わせて変更してください
4. セキュリティのため、パスワードは最低8文字以上に設定してください
