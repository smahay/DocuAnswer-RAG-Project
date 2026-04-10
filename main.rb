require_relative "classes/document_loader"
require_relative "classes/text_cleaner"
require_relative "classes/text_chunker"
require_relative "classes/embedding_generator"
require_relative "classes/vector_store"

# Initialize the components of the RAG system
docLoader = DocumentLoader.new
textCleaner = TextCleaner.new
textChunker = TextChunker.new(100, 20)
embedGen = EmbeddingGenerator.new
vectorStore = VectorStore.new

puts "DocuAnswer RAG 1.0"
puts "Enter q to quit."

# Start input loop
input = ""
while true
  print "Filepath: "
  input = gets.chomp
  if input == "q"
    abort "Quitting..."
    break
  end

  if !File.exist?(input)
    puts "#{input} is not a valid filepath."
    next
  end

  extension = File.extname(input)
  if extension != ".txt" && extension != ".pdf"
    puts "#{input} is not of the .txt or .pdf file type."
    next
  end

  # input has been verified as a valid filepath, now we process the document
  text = docLoader.loadDocument(input)
  text = textCleaner.cleanText(text)
  chunks = textChunker.chunk_text(text)
end