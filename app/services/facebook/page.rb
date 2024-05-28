module Facebook
  class Page < Base
    FB_API_URL = "#{FB_GRAPH_API_URL}/#{ENV['FB_PAGE_ID']}".freeze

    def post_with_images!(content, images)
      image_ids = upload_images!(images)
      request_url = "#{FB_API_URL}/feed"
      http_client.post(request_url) do |req|
        req.body = {
          access_token: page_token,
          message: content,
          attached_media: image_ids.map { |id| { media_fbid: id } }
        }
      end
    end

    def post!(content, options = {})
      request_url = "#{FB_API_URL}/feed"
      http_client.post(request_url) do |req|
        req.body = {
          access_token: page_token,
          message: content
        }.merge(options)
      end
    end

    def upload_images!(images)
      images.map do |image|
        upload_image!(image)
      end
    end

    def upload_image!(image, published: false)
      request_url = "#{FB_API_URL}/photos"
      response = http_client.post(request_url) do |req|
        req.body = {
          access_token: page_token,
          url: image,
          published:
        }
      end

      parsed_body = JSON.parse(response.body)
      parsed_body['id']
    end

    def delete_post!(post_id)
      request_url = "#{FB_GRAPH_API_URL}/#{post_id}"
      http_client.delete(request_url) do |req|
        req.body = { access_token: page_token }
      end
    end

    private

    def page_token
      @page_token ||= Facebook::User.new.page_token
    end
  end
end
