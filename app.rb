require "openssl"
require "sinatra"
require "sinatra/json"
require "json"
require "net/http"
require "uri"
require "digest"

set :port, ENV.fetch("PORT", 4567)
set :bind, "0.0.0.0"
set :public_folder, File.dirname(__FILE__) + "/public"
set :views, File.dirname(__FILE__) + "/views"

# ── 固定フレーズ集 ──────────────────────────────────────────
FIXED_PHRASES = {
  "筋トレ" => [
    { text: "今日上げた鉄は、明日の自分を支える柱になる。", author: "一転語" },
    { text: "限界は筋肉が決めるのではなく、心が決める。", author: "一転語" },
    { text: "昨日できなかった重量が、今日できる。それが成長の証だ。", author: "一転語" },
    { text: "汗は裏切らない。サボった言い訳は、積み重ならない。", author: "一転語" },
    { text: "一回の追い込みが、一年後の体を作る。", author: "一転語" },
    { text: "痛みは弱さが体を去っていくサインだ。", author: "一転語" },
    { text: "鏡の前に立て。それが今日の自分との契約だ。", author: "一転語" },
  ],
  "マインド" => [
    { text: "行動しない完璧より、行動する不完全の方が100倍価値がある。", author: "一転語" },
    { text: "迷っている時間は、すでに動いている人との差になっている。", author: "一転語" },
    { text: "恐れているものの正体は、まだ見ぬ自分の可能性だ。", author: "一転語" },
    { text: "誰かの成功を羨む時間で、自分の一歩が踏み出せる。", author: "一転語" },
    { text: "今日の選択が、一年後の自分の住所を決める。", author: "一転語" },
    { text: "弱さを認めることが、強くなるための最初の筋トレだ。", author: "一転語" },
    { text: "思考は現実の設計図だ。何を描くかを選べ。", author: "一転語" },
  ],
  "習慣" => [
    { text: "1日1%の改善は、1年で37倍になる。今日の小さな一歩を侮るな。", author: "一転語" },
    { text: "やる気を待つな。習慣はやる気より先に動き出す。", author: "一転語" },
    { text: "毎朝同じ時間に起きることが、人生のリズムを作る土台だ。", author: "一転語" },
    { text: "続けることを恥じるな。やめることを恥じよ。", author: "一転語" },
    { text: "環境が人を作る。まず机の上を片付けろ。", author: "一転語" },
    { text: "3日坊主で終わったなら、4日目にまた始めればいい。", author: "一転語" },
    { text: "朝の最初の選択が、その日の全ての選択の質を決める。", author: "一転語" },
  ],
  "挑戦" => [
    { text: "失敗は終わりではない。挑戦しなかったことが終わりだ。", author: "一転語" },
    { text: "リスクを取らないことが、最大のリスクだと気づいた時から人生は変わる。", author: "一転語" },
    { text: "正解を探すより、自分の選択を正解にする力を鍛えろ。", author: "一転語" },
    { text: "誰もやっていない道が、あなたの道になる可能性がある。", author: "一転語" },
    { text: "準備が整うのを待つな。船は港にいる時が一番安全だが、それが船の目的ではない。", author: "一転語" },
    { text: "今日の挑戦が、来月の自信の根拠になる。", author: "一転語" },
    { text: "人生はRPGだ。経験値は行動からしか得られない。", author: "一転語" },
  ],
}

CATEGORIES = FIXED_PHRASES.keys

# ── 今日のインデックス（日付ベースで固定） ─────────────────
def today_index(category)
  date_str = Time.now.strftime("%Y%m%d") + category
  Digest::MD5.hexdigest(date_str).to_i(16)
end

def todays_fixed_phrase(category)
  phrases = FIXED_PHRASES[category] || FIXED_PHRASES["マインド"]
  idx = today_index(category) % phrases.length
  phrases[idx]
end

# ── Claude API 呼び出し ─────────────────────────────────────
def generate_ai_phrase(category)
  api_key = ENV["ANTHROPIC_API_KEY"]
  return nil unless api_key

  begin
    uri = URI("https://api.anthropic.com/v1/messages")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    http.read_timeout = 15

    prompt = <<~PROMPT
      あなたは「一転語」という日本語の短い気づきの言葉を生み出す達人です。
      カテゴリ「#{category}」に関する、心に刺さる一転語を1つ作ってください。

      条件：
      - 40〜80文字程度の日本語
      - 説教や説明ではなく、ハッとする気づきや問いかけ
      - 読んだ瞬間に行動したくなる力強さ
      - 「今日の自分」に語りかけるような温度感
      - 「。」で終わる

      悪い例：「筋肉を鍛えるために定期的に運動することが大切だ。」（説明になっている）
      良い例：「限界は筋肉が決めるのではなく、心が決める。」（気づきになっている）

      一転語の文章のみを返してください。前置きや説明は不要です。
    PROMPT

    request = Net::HTTP::Post.new(uri)
    request["Content-Type"] = "application/json"
    request["x-api-key"] = api_key
    request["anthropic-version"] = "2023-06-01"
    request.body = JSON.generate({
      model: "claude-haiku-4-5-20251001",
      max_tokens: 200,
      messages: [{ role: "user", content: prompt }]
    })

    response = http.request(request)
    data = JSON.parse(response.body)
    text = data.dig("content", 0, "text")&.strip
    text ? { text: text, author: "AI一転語", ai: true } : nil
  rescue => e
    puts "API ERROR: #{e.class} - #{e.message}"
    nil
  end
end
# ── ルーティング ────────────────────────────────────────────
get "/" do
  @categories = CATEGORIES
  @category = params[:category] || "マインド"
  @category = "マインド" unless CATEGORIES.include?(@category)
  @mode = params[:mode] || "fixed"

  if @mode == "ai"
    @phrase = generate_ai_phrase(@category)
    @phrase ||= todays_fixed_phrase(@category).merge(ai: false, fallback: true)
  else
    @phrase = todays_fixed_phrase(@category).merge(ai: false)
  end

  erb :index
end

get "/api/phrase" do
  content_type :json
  category = params[:category] || "マインド"
  category = "マインド" unless CATEGORIES.include?(category)
  mode = params[:mode] || "fixed"

  phrase = if mode == "ai"
    p = generate_ai_phrase(category)
    p || todays_fixed_phrase(category).merge(ai: false, fallback: true)
  else
    todays_fixed_phrase(category).merge(ai: false)
  end

  phrase.merge(category: category).to_json
end
