# 一転語 — Ichtengo

FitnessGame 公式・毎日更新の気づきの言葉アプリ。

## ローカル起動

```bash
bundle install
ANTHROPIC_API_KEY=your_key ruby app.rb
```

ブラウザで http://localhost:4567 を開く。

## Render.com へのデプロイ手順

### 1. GitHub にプッシュ

```bash
git init
git add .
git commit -m "初回リリース: 一転語"
git remote add origin https://github.com/YOUR_USERNAME/ichtengo.git
git push -u origin main
```

### 2. Render で Web Service 作成

1. https://render.com → New → Web Service
2. GitHub リポジトリを連携
3. 設定:
   - **Runtime**: Ruby
   - **Build Command**: `bundle install`
   - **Start Command**: `bundle exec puma -C config/puma.rb`
   - **Plan**: Free

### 3. 環境変数を設定

Render のダッシュボード → Environment → Add Environment Variable:

| Key | Value |
|-----|-------|
| `ANTHROPIC_API_KEY` | あなたのAPIキー |
| `RACK_ENV` | production |

### 4. デプロイ完了

数分でデプロイ完了。URL は `https://your-app-name.onrender.com`

## 機能

- **固定フレーズ**: 日付ベースで毎日変わる（カテゴリ4種 × 7フレーズ）
- **AI生成**: Claude API でリアルタイム生成
- **X シェア**: ワンクリックでツイート
- **API**: `/api/phrase?category=筋トレ&mode=ai` で JSON 取得可能

## ファイル構成

```
ichtengo/
├── app.rb          # Sinatra メインアプリ
├── config.ru       # Rack 設定
├── Gemfile
├── Procfile
├── config/
│   └── puma.rb
├── views/
│   └── index.erb   # メインビュー
└── public/
    └── css/
        └── style.css
```
