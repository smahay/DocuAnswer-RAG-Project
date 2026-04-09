class DocumentLoader
  def loadDocument(fileName)
    text = ""
    extension = File.extname(fileName)
    if extension == ".txt"
      text = File.read(fileName)
    elsif extension == ".pdf"
      # Still need to read the text off pdf using PDF-reader gem to text variable
    end
    return text
  end
end

# Testing out class
puts "Starting documentLoader..."
docLoader = DocumentLoader.new
puts "Loading document 'a.txt'..."
puts "Text found:\n---------------------------------------------------------------------"
puts docLoader.loadDocument("a.txt")
puts "---------------------------------------------------------------------\nFinished reading document."