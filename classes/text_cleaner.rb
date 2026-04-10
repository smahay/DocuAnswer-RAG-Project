class TextCleaner
  def cleanText(text)
    puts "Text length before cleaning: #{text.length}"
    # Replace all groups of spaces with a single space
    text = text.gsub(/\s+/, " ")
    puts "Text length after cleaning: #{text.length}"

    return text
  end
end