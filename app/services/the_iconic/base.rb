module TheIconic
  class Base < ApplicationService
    private

    def crawler
      @crawler ||= TheIconicCrawler.new
    end
  end
end
