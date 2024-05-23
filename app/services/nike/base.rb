module Nike
  class Base < ApplicationService
    private

    def crawler
      @crawler ||= NikeCrawler.new
    end
  end
end
