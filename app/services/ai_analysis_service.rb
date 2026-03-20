# frozen_string_literal: true

class AiAnalysisService
  def initialize(product)
    @product = product
  end

  def self.call(product)
    new(product).call
  end

  def call
    # Return fresh cached result
    existing = product.ai_deal_analysis
    return existing if existing&.fresh?

    histories = product.price_histories.last_90_days.recent.limit(60).to_a

    stats = compute_stats(histories)
    prompt = build_prompt(stats)
    result = query_openai(prompt)

    return nil unless result

    upsert_analysis(result, stats)
  rescue => e
    Rails.logger.error "AiAnalysisService error for product #{product.id}: #{e.message}"
    nil
  end

  private

  attr_reader :product

  def compute_stats(histories)
    prices = histories.map { |h| h.price.to_f }
    current = product.price.to_f

    {
      current_price: current,
      old_price: product.old_price&.to_f,
      discount: product.discount&.to_f || 0,
      history_count: prices.size,
      lowest_90d: prices.any? ? prices.min.round(2) : current,
      highest_90d: prices.any? ? prices.max.round(2) : current,
      avg_90d: prices.any? ? (prices.sum / prices.size).round(2) : current,
      is_lowest_ever: prices.any? ? current <= prices.min : false,
      price_drop_count: count_drops(histories),
      history_points: histories.last(15).reverse.map { |h|
        { date: h.recorded_at.strftime('%d %b'), price: h.price.to_f }
      }
    }
  end

  def count_drops(histories)
    return 0 if histories.size < 2

    drops = 0
    histories.each_cons(2) do |newer, older|
      drops += 1 if newer.price.to_f < older.price.to_f
    end
    drops
  end

  def build_prompt(s)
    history_text = if s[:history_points].any?
      s[:history_points].map { |p| "  #{p[:date]}: $#{p[:price]}" }.join("\n")
    else
      "  No price history yet (first crawl)"
    end

    discount_text = s[:discount] > 0 ? " (#{s[:discount].to_i}% off RRP $#{s[:old_price]})" : ""

    <<~PROMPT
      You are a smart shopping analyst for Australian consumers. Analyze this deal and give a clear buying recommendation.

      PRODUCT: #{product.name}
      STORE: #{product.store}
      BRAND: #{product.brand}
      CATEGORIES: #{product.categories.join(', ')}

      CURRENT PRICE: $#{s[:current_price]}#{discount_text}

      PRICE STATISTICS (last 90 days):
        Average price:  $#{s[:avg_90d]}
        Lowest price:   $#{s[:lowest_90d]}
        Highest price:  $#{s[:highest_90d]}
        At all-time low: #{s[:is_lowest_ever] ? 'YES ✓' : 'No'}
        Price drops recorded: #{s[:price_drop_count]}

      PRICE HISTORY (recent):
      #{history_text}

      Based on this data, respond with a JSON object ONLY (no markdown, no explanation outside JSON):
      {
        "recommendation": "BUY_NOW" | "GOOD_DEAL" | "WAIT" | "OVERPRICED",
        "confidence": "HIGH" | "MEDIUM" | "LOW",
        "reasoning": "2-3 sentence explanation for Australian shoppers",
        "best_time_to_buy": "brief tip on when to buy if not now",
        "savings_vs_avg": number (how much cheaper/more expensive vs avg, negative means expensive)
      }

      Rules:
      - BUY_NOW: price is at or near historical low, strong discount, act fast
      - GOOD_DEAL: decent discount but may drop further
      - WAIT: price likely to drop based on history
      - OVERPRICED: current price is above average, not worth buying now
    PROMPT
  end

  def query_openai(prompt)
    client = Anthropic::Client.new(api_key: ENV.fetch('ANTHROPIC_API_KEY'))
    response = client.messages(
      model: 'claude-haiku-4-5',
      max_tokens: 400,
      messages: [{ role: 'user', content: prompt }]
    )

    raw = response.dig('content', 0, 'text')&.strip
    return nil if raw.blank?

    # Strip markdown code fences if present
    raw = raw.gsub(/```json\s*|\s*```/, '').strip
    JSON.parse(raw)
  rescue JSON::ParserError => e
    Rails.logger.error "AiAnalysisService JSON parse error: #{e.message} | raw: #{raw}"
    nil
  end

  def upsert_analysis(result, stats)
    analysis = product.ai_deal_analysis || product.build_ai_deal_analysis
    analysis.assign_attributes(
      recommendation: result['recommendation'],
      confidence:     result['confidence'],
      reasoning:      result['reasoning'],
      lowest_90d:     stats[:lowest_90d],
      avg_90d:        stats[:avg_90d],
      highest_90d:    stats[:highest_90d],
      price_drop_count: stats[:price_drop_count],
      is_lowest_ever: stats[:is_lowest_ever],
      analysed_at:    Time.current
    )
    analysis.save!
    analysis
  end
end
