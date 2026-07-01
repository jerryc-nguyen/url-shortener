class CreateShortenedUrls < ActiveRecord::Migration[8.1]
  def change
    create_table :shortened_urls do |t|
      t.string :original_url, null: false
      t.string :idempotency_key
      t.string :short_code
      t.timestamps
    end

    add_index :shortened_urls, :original_url
    add_index :shortened_urls, :idempotency_key, unique: true
    add_index :shortened_urls, :short_code, unique: true
  end
end
