class ShortenerUrls::Encode
  attr_reader :original_url

  Result = Struct.new(:success, :url, :error)

  def initialize(original_url:)
    @original_url = original_url
  end

  def call
    if original_url.blank?
      error = { code: Errors::ErrorCodes::VALIDATION_ERROR, message: Errors::ErrorMessages::URL_REQUIRED }
      return Result.new(success: false, url: nil, error: error)
    end

    url = ShortenedUrl.find_or_create_by(
      idempotency_key: idempotency_key(original_url),
    )
    url.original_url ||= original_url
    url.short_code ||= unique_short_code

    if url.save
      Result.new(success: true, url: url, error: nil)
    else
      error = { code: Errors::ErrorCodes::VALIDATION_ERROR, message: url.errors.full_messages.to_sentence }
      Result.new(success: false, url: nil, error: error)
    end
  end

  def unique_short_code
    loop do
      code = FriendlyCodeGenerator.generate

      return code unless ShortenedUrl.exists?(short_code: code)
    end
  end

  def idempotency_key(original_url)
    Digest::SHA256.hexdigest(original_url)
  end
end
