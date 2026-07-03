require 'rails_helper'

RSpec.describe 'ShortenerUrls API', type: :request do
  describe 'POST /encode' do
    let(:original_url) { 'https://example.com/some/path' }

    context 'with empty url' do
      it 'returns validation error' do
        post '/encode', params: { url: '' }
        expect(response).to have_http_status(:unprocessable_entity)

        json = JSON.parse(response.body)

        expect(json['error']['code']).to eq(Errors::ErrorCodes::VALIDATION_ERROR)
        expect(json['error']['message']).to eq(Errors::ErrorMessages::URL_REQUIRED)
      end
    end

    context 'with valid url' do
      it 'create shorted url and return short code' do
        post '/encode', params: { url: original_url }
        expect(response).to have_http_status(:ok)

        json = JSON.parse(response.body)

        expect(json['short_code']).to be_present
        shortened_url = ShortenedUrl.find_by(short_code: json['short_code'])

        expect(shortened_url.original_url).to eq(original_url)
        expect(shortened_url.short_code).to eq(json['short_code'])
      end
    end

    context 'with invalid url' do
      it 'returns validation error' do
        post '/encode', params: { url: 'invalid_url' }
        expect(response).to have_http_status(:unprocessable_entity)

        json = JSON.parse(response.body)
        expect(json['error']['code']).to eq(Errors::ErrorCodes::VALIDATION_ERROR)
      end
    end
  end

  describe 'POST /decode' do
    let!(:shortened_url) do
      ShortenedUrl.create!(
        original_url: 'https://google.com',
        short_code: 'abc123',
        idempotency_key: 'abc'
      )
    end

    context 'when the short code exists' do
      it 'returns the original url' do
        post '/decode', params: { short_code: shortened_url.short_code }
        expect(response).to have_http_status(:ok)

        json = JSON.parse(response.body)
        expect(json['url']).to eq(shortened_url.original_url)
      end
    end

    context 'when the short code does not exist' do
      it 'returns not found error' do
        post '/decode', params: { short_code: '404cod' }
        expect(response).to have_http_status(:not_found)

        json = JSON.parse(response.body)
        expect(json['error']['code']).to eq(Errors::ErrorCodes::RECORD_NOT_FOUND)
        expect(json['error']['message']).to eq(Errors::ErrorMessages::SHORT_CODE_NOT_FOUND)
      end
    end

    context 'when the short code invalid' do
      it 'returns invalid message' do
        post '/decode', params: { short_code: 'invalid-code' }
        expect(response).to have_http_status(:unprocessable_entity)

        json = JSON.parse(response.body)
        expect(json['error']['code']).to eq(Errors::ErrorCodes::VALIDATION_ERROR)
        expect(json['error']['message']).to eq(Errors::ErrorMessages::SHORT_CODE_INVALID)
      end
    end
  end
end
