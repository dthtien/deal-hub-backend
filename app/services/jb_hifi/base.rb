module JbHifi
  class Base < ApplicationService
    private

    def crawler
      @crawler ||= JbHifiCrawler.new
    end
  end
end
