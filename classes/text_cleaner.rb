class TextCleaner
  def clean_text(text)
    puts "Text length before cleaning: #{text.length}"

    # Remove all special characters
    text = text.gsub(/[^a-zA-Z0-9\s\+\-\*\/'"\.,!@%?<>=;:()$]/, "")

    # Replace all groups of spaces with a single space
    text = text.gsub(/\s+/, " ")

    # Remove any remaining whitespace at start and end
    text = text.strip

    puts "Text length after cleaning: #{text.length}"

    # puts text
    return text
  end
end