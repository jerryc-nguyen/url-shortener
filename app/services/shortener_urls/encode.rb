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

    if url.present?
      return success(url)
    end

    MAX_RETRIES.times do
      begin
        url = ShortenedUrl.create!(
                original_url: original_url,
                short_code: FriendlyCodeGenerator.generate,
                idempotency_key: idempotency_key
              )

        return success(url)
      rescue ActiveRecord::RecordNotUnique => e
        if e.message.include?('idempotency_key')
          return success(ShortenedUrl.find_by!(idempotency_key: idempotency_key))
        elsif e.message.include?('short_code')
          next
        else
          raise 'Unknown unique constraint violation: ' + e.message
        end
      rescue ActiveRecord::RecordInvalid => e
        error = { code: Errors::ErrorCodes::VALIDATION_ERROR, message: e.record.errors.full_messages.to_sentence }
        return Result.new(success: false, url: nil, error: error)
      end
    end

    Result.new(
      success: false,
      url: nil,
      error: {
        code: Errors::ErrorCodes::INTERNAL_SERVER_ERROR,
        message: 'Unable to generate unique short code'
      }
    )
  end

  private

  def success(url)
    Result.new(success: true, url: url, error: nil)
  end

  def idempotency_key
    @idempotency_key ||= Digest::SHA256.hexdigest(original_url)
  end
end
