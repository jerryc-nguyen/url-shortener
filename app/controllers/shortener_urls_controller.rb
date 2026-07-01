class ShortenerUrlsController < ApplicationController
  def encode
    url = ShortenedUrl.find_or_create_by(
      idempotency_key: idempotency_key(params[:url]),
    )
    url.original_url ||= params[:url]
    url.short_code ||= unique_short_code
    if url.save
      render json: url
    else
      render json: { error: url.errors.full_messages.to_sentence }, status: :unprocessable_entity
    end
  end

  def unique_short_code
    loop do
      code = FriendlyCodeGenerator.generate

      return code unless ShortenedUrl.exists?(short_code: code)
    end
  end

  def idempotency_key(original_url)
    Digest::SHA256.hexdigest("#{original_url}")
  end

  def decode
    render json: { short_url: 'test' }
  end
end
