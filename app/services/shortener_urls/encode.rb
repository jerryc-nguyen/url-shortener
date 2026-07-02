class ShortenerUrls::Encode
  attr_reader :original_url

  MAX_RETRIES = 5

  Result = Struct.new(:success, :url, :error)

  def initialize(original_url:)
    @original_url = original_url
  end

  def call
    if original_url.blank?
      error = { code: Errors::ErrorCodes::VALIDATION_ERROR, message: Errors::ErrorMessages::URL_REQUIRED }
      return Result.new(success: false, url: nil, error: error)
    end

    url = ShortenedUrl.find_by(
      idempotency_key: idempotency_key
    )

    return success(url) if url.present?

    MAX_RETRIES.times do
      begin
        return success(create_shortened_url)
      rescue ActiveRecord::RecordNotUnique => e
        if duplicate_idempotency_key?(e)
          return success(ShortenedUrl.find_by!(idempotency_key: idempotency_key))
        elsif duplicate_short_code?(e)
          next
        else
          raise e
        end
      rescue ActiveRecord::RecordInvalid => e
        return handle_validation_error(e)
      end
    end

    default_error_result
  end

  private

  def create_shortened_url
    ShortenedUrl.create!(
      original_url: original_url,
      short_code: FriendlyCodeGenerator.generate,
      idempotency_key: idempotency_key
    )
  end

  def duplicate_idempotency_key?(e)
    e.message.include?('idempotency_key')
  end

  def duplicate_short_code?(e)
    e.message.include?('short_code')
  end

  def handle_validation_error(e)
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
