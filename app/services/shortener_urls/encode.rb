class ShortenerUrls::Encode
  attr_reader :original_url

  MAX_RETRIES = 5

  Result = Struct.new(:success, :url, :error)

  def initialize(original_url:)
    @original_url = original_url
  end

  def call
    return empty_url_error_result if original_url.blank?

    MAX_RETRIES.times do
      if (url = ShortenedUrl.find_by(idempotency_key: idempotency_key))
        return success(url)
      end

      begin
        return success(create_shortened_url)
      rescue ActiveRecord::RecordNotUnique => e
        next
      rescue ActiveRecord::RecordInvalid => e
        return validation_error_result(e)
      end
    end

    default_error_result
  end

  private

  def empty_url_error_result
    error = { code: Errors::ErrorCodes::VALIDATION_ERROR, message: Errors::ErrorMessages::URL_REQUIRED }
    Result.new(success: false, url: nil, error: error)
  end

  def create_shortened_url
    ShortenedUrl.create!(
      original_url: original_url,
      short_code: FriendlyCodeGenerator.generate,
      idempotency_key: idempotency_key
    )
  end

  def validation_error_result(e)
    error = { code: Errors::ErrorCodes::VALIDATION_ERROR, message: e.record.errors.full_messages.to_sentence }
    Result.new(success: false, url: nil, error: error)
  end

  def default_error_result
    Result.new(
      success: false,
      url: nil,
      error: {
        code: Errors::ErrorCodes::INTERNAL_SERVER_ERROR,
        message: 'Unable to generate unique short code'
      }
    )
  end

  def success(url)
    Result.new(success: true, url: url, error: nil)
  end

  def idempotency_key
    @idempotency_key ||= Digest::SHA256.hexdigest(original_url)
  end
end
