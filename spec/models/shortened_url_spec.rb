# == Schema Information
#
# Table name: shortened_urls
#
#  id              :integer          not null, primary key
#  original_url    :string           not null
#  idempotency_key :string
#  short_code      :string
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#
# Indexes
#
#  index_shortened_urls_on_idempotency_key  (idempotency_key) UNIQUE
#  index_shortened_urls_on_original_url     (original_url)
#  index_shortened_urls_on_short_code       (short_code) UNIQUE
#

require 'rails_helper'

RSpec.describe ShortenedUrl, type: :model do
  it 'valid original_url' do
    url = described_class.new(original_url: 'https://google.com')
    expect(url.valid?).to be(true)
  end

  context 'invalid original_url' do
    it 'empty url' do
      url = described_class.new(original_url: '')
      expect(url.valid?).to be(false)
      expect(url.errors['original_url'].to_sentence).to include('can\'t be blank')
    end

    it 'invalid url without http or https' do
      url = described_class.new(original_url: 'google.com')
      expect(url.valid?).to be(false)
      expect(url.errors['original_url'].to_sentence).to include('is invalid')
    end

    it 'url length > 2000' do
      url = described_class.new(original_url: 'https://' + 'a' * 2001)
      expect(url.valid?).to be(false)
      expect(url.errors['original_url'].to_sentence).to include('is too long')
    end
  end
end
