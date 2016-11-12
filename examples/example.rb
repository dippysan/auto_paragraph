require 'auto_paragraph'

autop = AutoParagraph.new(insert_line_breaks: true)
input_text = "text from database\nwith carriage returns\n instead of paragraph tags.\n\nNew paragraph."
formatted_text = autop.execute(input_text)

puts formatted_text
# <p>text from database<br />
# with carriage returns<br />
#  instead of paragraph tags.</p>
# <p>New paragraph.</p>
