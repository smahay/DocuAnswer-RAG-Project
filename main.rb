require_relative "classes/document_loader"
require_relative "classes/text_cleaner"
require_relative "classes/text_chunker"
require_relative "classes/embedding_generator"
require_relative "classes/vector_store"

docLoader = DocumentLoader.new
text = docLoader.loadDocument("C455_S26_Syllabus.pdf")

textCleaner = TextCleaner.new
text = textCleaner.cleanText(text)