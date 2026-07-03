class FriendlyCodeGenerator
  CHARS = ('a'..'z').to_a + ('A'..'Z').to_a + ('0'..'9').to_a - [ 'O', '0', 'I', 'l' ]

  def self.generate(length = 6)
    length.times.map do
      CHARS[rand(CHARS.length)]
    end.join
  end
end
