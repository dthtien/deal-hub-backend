class Facebook::Base
  FB_GRAPH_API_URL = 'https://graph.facebook.com/v20.0'.freeze

  private

  def http_client
    @http_client ||= Faraday.new(FB_GRAPH_API_URL) do |faraday|
      faraday.request :url_encoded
      faraday.adapter Faraday.default_adapter
    end
  end
end
