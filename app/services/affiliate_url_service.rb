class AffiliateUrlService < ApplicationService
  STORE_CONFIGS = {
    'asos' => {
      network: :awin,
      mid: -> { ENV.fetch('AWIN_ASOS_MID', 'YOUR_AWIN_MID') },
      affid: -> { ENV.fetch('AWIN_AFFID', 'YOUR_AWIN_AFFID') }
    },
    'culture_kings' => {
      network: :commission_factory,
      aid: -> { ENV.fetch('CF_AID', 'YOUR_CF_AID') },
      mid: -> { ENV.fetch('CF_CULTURE_KINGS_MID', 'YOUR_CF_MID') }
    },
    'foot_locker' => {
      network: :commission_factory,
      aid: -> { ENV.fetch('CF_AID', 'YOUR_CF_AID') },
      mid: -> { ENV.fetch('CF_FOOT_LOCKER_MID', 'YOUR_CF_MID') }
    },
    'jd_sports' => {
      network: :commission_factory,
      aid: -> { ENV.fetch('CF_AID', 'YOUR_CF_AID') },
      mid: -> { ENV.fetch('CF_JD_SPORTS_MID', 'YOUR_CF_MID') }
    },
    'the_iconic' => {
      network: :commission_factory,
      aid: -> { ENV.fetch('CF_AID', 'YOUR_CF_AID') },
      mid: -> { ENV.fetch('CF_THE_ICONIC_MID', 'YOUR_CF_MID') }
    },
    'myer' => {
      network: :commission_factory,
      aid: -> { ENV.fetch('CF_AID', 'YOUR_CF_AID') },
      mid: -> { ENV.fetch('CF_MYER_MID', 'YOUR_CF_MID') }
    },
    'nike' => {
      network: :commission_factory,
      aid: -> { ENV.fetch('CF_AID', 'YOUR_CF_AID') },
      mid: -> { ENV.fetch('CF_NIKE_MID', 'YOUR_CF_MID') }
    }
  }.freeze

  def initialize(product)
    @product = product
    @store = product.store&.downcase
    @store_path = product.store_path
  end

  def call
    build_affiliate_url
  end

  private

  attr_reader :product, :store, :store_path

  def build_affiliate_url
    config = STORE_CONFIGS[store]
    return store_path if config.nil? || store_path.blank?

    case config[:network]
    when :awin
      build_awin_url(config)
    when :commission_factory
      build_commission_factory_url(config)
    else
      store_path
    end
  end

  def build_awin_url(config)
    mid = config[:mid].call
    affid = config[:affid].call
    encoded_url = CGI.escape(store_path)
    "https://www.awin1.com/cread.php?awinmid=#{mid}&awinaffid=#{affid}&ued=#{encoded_url}"
  end

  def build_commission_factory_url(config)
    aid = config[:aid].call
    mid = config[:mid].call
    encoded_url = CGI.escape(store_path)
    "https://t.cfjump.com/click?a=#{aid}&m=#{mid}&url=#{encoded_url}"
  end
end
