module GlueStore
  class Base < ApplicationService
    private

    def crawler
      @crawler ||= GlueStoreCrawler.new
    end
  end
end
