class ShortenerUrlsController < ApplicationController
  SHORT_CODE_LENGTHS = [ 6 ]

  def encode
    result = ShortenerUrls::Encode.new(
      original_url: params[:url]
    ).call

    if result.success
      render_success({ short_code: result.url.short_code })
    else
      render_error(422, result.error[:code], result.error[:message])
    end
  end

  def decode
    if params[:short_code].blank? || !SHORT_CODE_LENGTHS.include?(params[:short_code].length)
      return render_error(
        422,
        Errors::ErrorCodes::VALIDATION_ERROR,
        Errors::ErrorMessages::SHORT_CODE_INVALID
      )
    end

    url = ShortenedUrl.find_by(short_code: params[:short_code])
    if url.nil?
      return render_error(
        404,
        Errors::ErrorCodes::RECORD_NOT_FOUND,
        Errors::ErrorMessages::SHORT_CODE_NOT_FOUND
      )
    end

    render_success({ url: url.original_url })
  end
end
