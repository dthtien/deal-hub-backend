module TheGoodGuys
  class Base < ApplicationService
    private

    def crawler
      @crawler ||= TheGoodGuysCrawler.new
    end
  end
end
