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
    render json: { short_url: 'test' }
  end
end
