# frozen_string_literal: true

class SendOfferService < ApplicationService
  option :offer
  option :sent_by

  def call
    yield validate_offer
    yield send_offer
    yield notify_candidate
    Success(offer)
  end

  private

  def validate_offer
    unless offer.approved?
      return Failure(errors: ["Offer must be approved before sending"])
    end

    unless offer.candidate.email.present?
      return Failure(errors: ["Candidate does not have an email address"])
    end

    Success()
  end

  def send_offer
    offer.send_to_candidate!
    Success()
  rescue StandardError => e
    Failure(errors: [e.message])
  end

  def notify_candidate
    # TODO: Send email to candidate with offer details
    # OfferMailer.offer_sent(offer).deliver_later
    Success()
  end
end
