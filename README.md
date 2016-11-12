AutoParagraph
=============

Formats Wordpress 'post' content in Ruby: Replaces double line breaks with paragraph elements.

Same as Wordpress' [wpautop()][wpautop] function

[wpautop]: https://github.com/WordPress/WordPress/blob/4.3-branch/wp-includes/formatting.php

Installation
------------

```ruby
gem install auto_paragraph
```

Usage
-----

```ruby
require 'auto_paragraph'

input_text = "text from database\nwith carriage returns\n instead of paragraph tags.\n\nNew paragraph."

autop = AutoParagraph.new(insert_line_breaks: true)
formatted_text = autop.execute(input_text)

puts formatted_text
# <p>text from database<br />
# with carriage returns<br />
#  instead of paragraph tags.</p>
# <p>New paragraph.</p>
```

Acknowledgements
----------------

The AutoParagraph design was copied from the php code for Wordpress 4.3, then ruby-ized.

Copyright
---------

Copyright © 2016 David Peterson
See LICENSE.txt for details.