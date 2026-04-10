require_relative "classes/document_loader"
require_relative "classes/text_cleaner"
require_relative "classes/text_chunker"
require_relative "classes/embedding_generator"
require_relative "classes/vector_store"

# Initialize the components of the RAG system
doc_loader = DocumentLoader.new
text_cleaner = TextCleaner.new
text_chunker = TextChunker.new(100, 20)
embed_gen = EmbeddingGenerator.new("API Key")
vector_store = VectorStore.new("data/vector_store.json")

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
  text = doc_loader.load_document(input)
  text = text_cleaner.clean_text(text)
  chunks = text_chunker.chunk_text(text)
end