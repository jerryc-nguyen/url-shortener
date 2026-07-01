class ShortenerUrlsController < ApplicationController
  def encode
    result = ShortenerUrls::Encode.new(
      original_url: params[:url]
    ).call

    if result.success
      render json: {
        id: result.url.id,
        short_code: result.url.short_code
      }
    else
      render_error(
        422,
        result.error[:code],
        result.error[:message]
      )
    end
  end

  def decode
    url = ShortenedUrl.find_by(short_code: params[:short_code])
    if url.nil?
      return render_error(
        404,
        Errors::ErrorCodes::RECORD_NOT_FOUND,
        'Short code not found'
      )
    end

    render_success({ url: url.original_url })
  end
end
