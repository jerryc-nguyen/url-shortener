require 'rails_helper'

RSpec.describe ShortenerUrls::Encode do
  describe "#call" do
    let(:original_url) { 'https://google.com' }
    subject(:result) do
      described_class.new(original_url: original_url).call
    end

    it 'return validation error when original url is empty' do
      result = described_class.new(original_url: '').call
      expect(result.success).to be(false)
      expect(result.error[:code]).to eq(Errors::ErrorCodes::VALIDATION_ERROR)
      expect(result.error[:message]).to eq(Errors::ErrorMessages::URL_REQUIRED)
    end

    context 'when original url is shortened' do
       let!(:shortened_url) do
        ShortenedUrl.create!(
          original_url: original_url,
          short_code: 'abc123',
          idempotency_key: Digest::SHA256.hexdigest(original_url)
        )
      end
      it 'return existed short code' do
        expect(result.success).to be(true)
        expect(result.url.short_code).to eq(shortened_url.short_code)
      end
    end

    context 'when original url have not been shortened' do
      let(:original_url) { 'https://google.com/2' }
      it 'shorten url success' do
        expect(result.success).to be(true)
        expect(result.url.original_url).to eq(original_url)
        expect(result.url.short_code).to be_present
      end
    end

    context 'when duplicate idempotency key' do
      let!(:shortened_url) do
        ShortenedUrl.create!(
          original_url: original_url,
          short_code: 'abc123',
          idempotency_key: Digest::SHA256.hexdigest(original_url)
        )
      end

      before do
        allow(ShortenedUrl).to receive(:create!).and_raise(ActiveRecord::RecordNotUnique.new('duplicate idempotency_key'))
      end

      it 'return existed short code' do
        expect(result.success).to be(true)
        expect(result.url.short_code).to eq(shortened_url.short_code)
      end
    end

    context 'when create url failed validation' do
      let(:original_url) { 'invalid-url' }

      it 'return validation failed when create failed validation' do
        expect(result.success).to be(false)
        expect(result.error[:code]).to eq(Errors::ErrorCodes::VALIDATION_ERROR)
        expect(result.error[:message]).to be_present
      end
    end

    context 'when reach all retries' do
      before do
        allow(ShortenedUrl).to receive(:create!).and_raise(ActiveRecord::RecordNotUnique.new('duplicate short_code'))
      end
      it 'return default error' do
        expect(result.success).to be(false)
        expect(result.error[:code]).to eq(Errors::ErrorCodes::INTERNAL_SERVER_ERROR)
        expect(result.error[:message]).to eq('Unable to generate unique short code')
      end
    end
  end
end
