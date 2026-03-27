# frozen_string_literal: true

class ReferralsController < ApplicationController
  def redirect
    referral = Referral.find_by(code: params[:code])
    if referral
      referral.increment!(:click_count)
    end
    redirect_to '/', allow_other_host: false
  end
end
