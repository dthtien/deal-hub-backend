class RobotsController < ApplicationController
  def index
    respond_to do |format|
      format.text { render plain: robots_content, content_type: 'text/plain' }
      format.any  { render plain: robots_content, content_type: 'text/plain' }
    end
  end

  private

  def robots_content
    <<~ROBOTS
      User-agent: *
      Disallow: /admin
      Disallow: /admin/
      Disallow: /api/v1/auth/
      Disallow: /auth/

      Sitemap: https://www.ozvfy.com/sitemap.xml
    ROBOTS
  end
end
