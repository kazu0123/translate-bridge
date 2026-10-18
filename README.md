# Translate Bridge

OpenAI Chat Completions 互換 API をバックエンドとして、macOS 上で LibreTranslate 互換の翻訳 API を提供します。

## 要件

- macOS
- Go 1.23 以降

## インストール

1. プロジェクトディレクトリに移動します。

   ```bash
   cd translate-bridge
   ```

2. インストールスクリプトを実行します。

   ```bash
   ./scripts/install.sh
   ```

## 設定変更

1. 設定ファイルを開き、編集します。

   ```bash
   open ~/Library/Application\ Support/Translate\ Bridge/config.jsonc
   ```

2. サーバーを再起動します。

   ```bash
   ./scripts/restart.sh
   ```

## アンインストール

1. プロジェクトディレクトリに移動します。

   ```bash
   cd translate-bridge
   ```

2. アンインストールスクリプトを実行します。

   ```bash
   ./scripts/uninstall.sh
   ```

3. 完全なアンインストールが必要とされる場合、残留物の内容を確認したうえで、次の残留ファイルを削除します。

   - `~/Library/Application Support/Translate Bridge/config.jsonc`
   - `~/Library/Logs/Translate Bridge/`

## エンドポイント

LibreTranslate 互換の以下のエンドポイントを提供します。

| メソッド | エンドポイント | 機能 |
|---|---|---|
| `GET` | `/health` | ヘルスチェック |
| `POST` | `/detect` | テキストの言語判定 |
| `POST` | `/translate` | テキストの翻訳 |

各エンドポイントの必須パラメータおよびレスポンス形式は、LibreTranslate の仕様に準拠します。

### 詳細仕様

#### `/health` (GET)
ヘルスチェックエンドポイント。

**レスポンス**:
```json
{
  "status": "ok"
}
```

#### `/detect` (POST)
テキストの言語を検出します。

**リクエストパラメータ**:
- `q` (required): テキスト

**レスポンス**:
```json
[
  {
    "confidence": 90.0,
    "language": "fr"
  }
]
```

#### `/translate` (POST)
テキストを翻訳します。

**リクエストパラメータ**:
- `q` (required): 翻訳するテキスト
- `source` (required): ソース言語コード（例: "en"）
- `target` (required): 対象言語コード（例: "ja"）
- `format` (optional): テキスト形式（"text" または "html"）
- `alternatives` (optional): 置換候補の数
- `api_key` (optional): APIキー

**レスポンス**:
```json
{
  "translatedText": "こんにちは",
  "detectedLanguage": {
    "confidence": 90.0,
    "language": "en"
  }
}
```
