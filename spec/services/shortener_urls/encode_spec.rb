require "rails_helper"

RSpec.describe ShortenerUrls::Encode do
  describe "#call" do
    let(:result) do
      described_class.new(original_url: original_url).call
    end

    context "when original_url is blank" do
      let(:original_url) { "" }

      it "returns a validation error" do
        expect(result.success).to be(false)
        expect(result.url).to be_nil

        expect(result.error).to eq(
          code: Errors::ErrorCodes::VALIDATION_ERROR,
          message: Errors::ErrorMessages::URL_REQUIRED
        )
      end
    end

    context "when original_url is valid" do
      let(:original_url) { "https://google.com" }

      it "created a shortened url" do
        expect { result }
          .to change(ShortenedUrl, :count).by(1)

        expect(result.success).to be(true)
        expect(result.error).to be_nil

        shortened_url = result.url

        expect(shortened_url).to be_persisted
        expect(shortened_url.original_url).to eq(original_url)
        expect(shortened_url.short_code).to be_present
      end
    end

    context "when the url cannot be saved" do
      let(:original_url) { "invalid-url" }

      it "returns validation errors" do
        expect(result.success).to be(false)
        expect(result.url).to be_nil

        expect(result.error[:code])
          .to eq(Errors::ErrorCodes::VALIDATION_ERROR)

        expect(result.error[:message]).to be_present
      end
    end
  end
end
