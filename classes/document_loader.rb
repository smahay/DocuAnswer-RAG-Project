require "pdf-reader"

class DocumentLoader
  def load_document(file_name)
    if file_name.nil? || file_name.strip.empty?
      raise "Please provide a file name."
    end

    extension = File.extname(file_name).downcase
    if !File.exist?(file_name)
      raise "File not found: #{file_name}"
    end

    if extension == ".txt"
      text = File.read(file_name)
    elsif extension == ".pdf"
      reader = PDF::Reader.new(file_name)
      text = reader.pages.map(&:text).join("\n")
    else
      raise "Only .txt and .pdf files are supported."
    end

    text = text.strip
    if text.empty?
      raise "DocumentLoader could not find text in '#{file_name}'."
    end

    text
  end
end