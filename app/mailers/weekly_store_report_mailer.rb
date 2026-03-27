# frozen_string_literal: true

class WeeklyStoreReportMailer < ApplicationMailer
  default from: ENV.fetch('MAILER_FROM', 'deals@ozvfy.com')

  def weekly_report(email, top_stores:, zero_new_stores:, total_deal_count:)
    @top_stores = top_stores
    @zero_new_stores = zero_new_stores
    @total_deal_count = total_deal_count
    @site_url = ENV.fetch('SITE_URL', 'https://www.ozvfy.com')
    @generated_at = Time.current.strftime('%d %b %Y')

    mail(
      to: email,
      subject: "OzVFY Weekly Store Report - #{@generated_at}"
    )
  end
end
