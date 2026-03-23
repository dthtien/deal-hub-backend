module GoodBuyz
  class Base < ApplicationService
    private

    def crawler
      @crawler ||= GoodBuyzCrawler.new
    end
  end
end
