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

class ShortenedUrl < ApplicationRecord
  validates :original_url, presence: true, format: URI.regexp(%w[http https])
  validates :original_url, length: { maximum: 2000 }
end
