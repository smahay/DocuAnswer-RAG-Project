require "pdf-reader"

class DocumentLoader
  def load_document(fileName)
    puts "Loading document '#{fileName}'..."
    text = ""
    extension = File.extname(fileName)
    if extension == ".txt"
      text = File.read(fileName)
    elsif extension == ".pdf"
      reader = PDF::Reader.new(fileName)

      # Get text from each page as array, then join into single string
      text = reader.pages.map(&:text).join("\n") 
    end

    # Check to see if any content was read
    text = text.strip
    if text == ""
      throw "DocumentLoader failed to find text in '#{fileName}."
    end

    puts "Finished reading document."
    
    # puts "Text found: ---------------------------------------------------------"
    # puts text
    # puts "---------------------------------------------------------------------"
    
    return text
  end
end