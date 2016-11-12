require 'auto_paragraph'

shared_context "input helper" do
  subject(:helper) do
    AutoParagraph.new
  end

  let(:method) { :undefined }

  def execute(input, *params)
    helper.send(:input_hook=, input) # Set instance variable
    Array(method).to_a.each do |single_method|
      helper.send(single_method, *params)            # Run test
    end
    helper.send(:input_hook)       # return new copy of variable
  end
end

describe "Auto Paragraph" do

  describe ".execute" do
    include_context "input helper"

    describe "space checks" do

      it "removes spaces from string with only spaces" do
        expect(helper.execute("  ")).to eq("")
      end

      it "removes spaces from empty string" do
        expect(helper.execute("")).to eq("")
      end
    end

    describe ".multiple_brs_into_two_line_breaks" do

      let(:method) { :multiple_brs_into_two_line_breaks }

      it "converts two line breaks to two newlines" do
        expect(execute("<br />   <br>")).to eq("\n\n")
        expect(execute("abc<br /><br >def")).to eq("abc\n\ndef")
        expect(execute("<br>not converted<br/>")).to eq("<br>not converted<br/>")
      end

    end

    describe "break before opening tags and after closing tags" do

      let(:method) { [:add_double_break_below_block_level_closing_tags, :add_single_line_break_above_block_level_opening_tags] }

      it ".add_single_line_break_above_block_level_opening_tags" do
        expect(execute("<table>")).to eq("\n<table>")
      end

      it ".add_double_break_below_block_level_closing_tags" do
        expect(execute("</table>")).to eq("</table>\n\n")
      end

      it "both tags in same string" do
        text = "<h1>heading 1</h1> whitespace <h2>heading 2</h2>"
        expect(execute(text)).to eq("\n<h1>heading 1</h1>\n\n whitespace \n<h2>heading 2</h2>\n\n")
        text = "text <math options='x'>inside</math>"
        expect(execute(text)).to eq("text \n<math options='x'>inside</math>\n\n")
      end

    end

    describe ".standardize_newline_to_backslash_n" do

      let(:method) { :standardize_newline_to_backslash_n }

      # X's added around because .strip removes cr and lf
      it "convert \\r\\n to \\n" do
        expect(execute("x\r\nx")).to eq("x\nx")
      end

      it "convert \\r to \\n" do
        expect(execute("x\rx")).to eq("x\nx")
      end

      it "works on multiples" do
        expect(execute("x\r\n\r\r\n\nx")).to eq("x\n\n\n\nx")
      end

    end

    describe ".replace_newlines_in_elements_with_placeholders" do
      let(:method) { :replace_newlines_in_elements_with_placeholders }

      it "replaces in elements" do
        expect(execute("<tag\n>")).to eq("<tag <!-- wpnl --> >")
      end

      it "leaves outside elements" do
        expect(execute("x\nx")).to eq("x\nx")
      end

      it "works with both inside and outside" do
        expect(execute("x<tag\n>y\nz")).to eq("x<tag <!-- wpnl --> >y\nz")
      end

    end

    describe ".collapse_line_breaks_around_option_elements" do
      let(:method) { :collapse_line_breaks_around_option_elements }

      it "removes whitespace before <option" do
        expect(execute("abc \n <option>def")).to eq("abc<option>def")
      end

      it "removes whitespace after </option>" do
        expect(execute("<option>abc</option> \n\n def")).to eq("<option>abc</option>def")
      end

      it "removes all around" do
        expect(execute("abc \n\n <option>\ndef</option> \n ghi")).to eq("abc<option>\ndef</option>ghi")
      end

    end

    describe ".collapse_line_breaks_inside_object_before_param_or_embed" do
      let(:method) { :collapse_line_breaks_inside_object_before_param_or_embed }

      it "ignores lines without </object>" do
        expect(execute("regular \nstring")).to eq("regular \nstring")
      end

      it "removes whitespace between <object> and <param>" do
        expect(execute("<object>  \n abc \n <param></object>")).to eq("<object>abc<param></object>")
      end

      it "removes whitespace between <object> and <embed>" do
        expect(execute("<object>  \n abc \n <embed></object>")).to eq("<object>abc<embed></object>")
      end

    end

    describe ".collapse_line_breaks_inside_audio_video_around_source_track" do
      let(:method) { :collapse_line_breaks_inside_audio_video_around_source_track }

      it "ignores lines without <source> or <track>" do
        expect(execute("regular \nstring")).to eq("regular \nstring")
      end

      it "removes whitespace after <audio> or [audio]" do
        expect(execute("<audio> \n abc<source></audio> [audio] \n [/audio]")).to eq("<audio>abc<source></audio> [audio][/audio]")
      end

      it "removes whitespace before </audio> or [/audio]" do
        expect(execute("abc<audio>def<source> \n </audio>[audio]  \n [/audio]")).to eq("abc<audio>def<source></audio>[audio][/audio]")
      end

      it "removes whitespace after <video> or [video]" do
        expect(execute("<video> \n abc<source></video> [video] \n [/video]")).to eq("<video>abc<source></video> [video][/video]")
      end

      it "removes whitespace before </video> or [/video]" do
        expect(execute("abc<video>def<source> \n </video>[video]  \n [/video]")).to eq("abc<video>def<source></video>[video][/video]")
      end

      it "removes whitespace around inside of <source> and <track>" do
        expect(execute("abc<video>def \n <source> \n <track> \n ghi</video>")).to eq("abc<video>def<source><track>ghi</video>")
      end

    end

    describe ".remove_more_than_two_contiguous_line_breaks" do
      let(:method) { :remove_more_than_two_contiguous_line_breaks }

      it "leaves 1 and 2 newlines alone" do
        expect(execute(" \n \n\n abc ")).to eq(" \n \n\n abc ")
      end

      it "removes more than two newline" do
        expect(execute(" \n \n\n\n abc \n\n\n\n\n\n\n\n\n ")).to eq(" \n \n\n abc \n\n ")
      end
    end

    describe ".replace_pre_with_placeholders" do
      let(:method) { :replace_pre_with_placeholders }

      it "no pre blocks" do
        text = "abc\ndef\n<h1>klm</h1>"
        expect(execute(text)).to eq("abc\ndef\n<h1>klm</h1>")
      end

      it "one pre block" do
        text = "abc<pre>\ndef\n</pre>ghi"
        expect(execute(text)).to eq("abc<pre wp-pre-tag-0></pre>ghi")
      end

      it "two pre blocks" do
        text = "abc<pre>\ndef\n</pre>ghi<pre>hij</pre> klm"
        expect(execute(text)).to eq("abc<pre wp-pre-tag-0></pre>ghi<pre wp-pre-tag-1></pre> klm")
      end

    end

    describe ".add_p_tags_at_doule_linebreaks" do
      let(:method) { :add_p_tags_at_doule_linebreaks }

      it "no double linebreaks" do
        text = "abc\ndef\n<h1>klm</h1>"
        expect(execute(text)).to eq("<p>abc\ndef\n<h1>klm</h1></p>\n")
      end

      it "one double linebreak block" do
        text = "abc\n\ndef\nghi"
        expect(execute(text)).to eq("<p>abc</p>\n<p>def\nghi</p>\n")
      end

      it "two double linebreak blocks" do
        text = "abc\n\ndef\n\nghi"
        expect(execute(text)).to eq("<p>abc</p>\n<p>def</p>\n<p>ghi</p>\n")
      end

    end


    describe ".remove_p_with_only_whitespace" do
      let(:method) { :remove_p_with_only_whitespace }

      it "no empty p blocks" do
        text = "abc\ndef\n<h1>klm</h1>"
        expect(execute(text)).to eq("abc\ndef\n<h1>klm</h1>")
      end

      it "one empty p block" do
        text = "<p>abc\n</p>\n<p> \n \t</p>\n<p>ghi</p>\n"
        expect(execute(text)).to eq("<p>abc\n</p>\n\n<p>ghi</p>\n")
      end

      it "two empty p blocks" do
        text = "<p></p>xx<p> </p>"
        expect(execute(text)).to eq("xx")
      end

    end

    describe ".add_closing_p_inside_div_address_form" do
      let(:method) { :add_closing_p_inside_div_address_form }

      it "no closing p needed" do
        text = "<p>abc\n</p>\n<p>ghi</p>\n"
        expect(execute(text)).to eq("<p>abc\n</p>\n<p>ghi</p>\n")
      end

      it "closing p missing from div, address, or form" do
        %w(div address form).each do |element|
          text = "<p>abc</#{element}>ghi</div>"
          expect(execute(text)).to eq("<p>abc</p></#{element}>ghi</div>")
        end
      end

    end

    describe ".unwrap_opening_closing_element_from_p" do
      let(:method) { :unwrap_opening_closing_element_from_p }

      it "no unwrap needed" do
        text = "<p><caption></caption></p>\n"
        expect(execute(text)).to eq("<p><caption></caption></p>\n")
      end

      it "opening tag wrapped" do
        text = "abc<p> <caption> </p>def\n"
        expect(execute(text)).to eq("abc<caption>def\n")
      end

      it "closing tag wrapped" do
        text = "abc<p> </caption> </p>def\n"
        expect(execute(text)).to eq("abc</caption>def\n")
      end
    end


    describe ".unwrap_li_from_p" do
      let(:method) { :unwrap_li_from_p }

      it "no unwrap needed" do
        text = "<li>abc</li>"
        expect(execute(text)).to eq("<li>abc</li>")
      end

      it "wrapped li" do
        text = "abc<p><li>ghi</li> </p>def\n"
        expect(execute(text)).to eq("abc<li>ghi</li> def\n")
      end
    end

    describe ".unwrap_blockquote_from_p" do
      let(:method) { :unwrap_blockquote_from_p }

      it "no unwrap needed" do
        text = "<blockquote><p>xxx</p></blockquote>"
        expect(execute(text)).to eq("<blockquote><p>xxx</p></blockquote>")
      end

      it "wrapped blockquote" do
        text = "abc<p><blockquote def>ghi</blockquote></p>"
        expect(execute(text)).to eq("abc<blockquote def><p>ghi</p></blockquote>")
      end
    end

    describe ".remove_preceeding_p_from_block_element_tag" do
      let(:method) { :remove_preceeding_p_from_block_element_tag }

      it "no preceeding p in block element" do
        text = "abc<form>xxx</form>"
        expect(execute(text)).to eq("abc<form>xxx</form>")
      end

      it "one preceeding p" do
        text = "abc<p>  <math>xyz</math>"
        expect(execute(text)).to eq("abc<math>xyz</math>")
      end

      it "two preceeding p" do
        text = "abc<p>  <math>xyz<p></math>"
        expect(execute(text)).to eq("abc<math>xyz</math>")
      end
    end


    describe ".remove_following_p_from_block_element_tag" do
      let(:method) { :remove_following_p_from_block_element_tag }

      it "no preceeding p in block element" do
        text = "abc<form>xxx</form>"
        expect(execute(text)).to eq("abc<form>xxx</form>")
      end

      it "one preceeding p" do
        text = "abc<figcaption></p>xyz</figcaption>"
        expect(execute(text)).to eq("abc<figcaption>xyz</figcaption>")
      end

      it "two preceeding p" do
        text = "abc<summary>  </p>xyz</summary></p>"
        expect(execute(text)).to eq("abc<summary>xyz</summary>")
      end
    end


    describe ".insert_line_breaks" do
      let(:method) { :insert_line_breaks }
      subject(:helper) do
        AutoParagraph.new(insert_line_breaks: false)
      end

      it "no effect when new(insert_line_breaks: false)" do
        text = "abc\ndef\n"
        expect(execute(text)).to eq("abc\ndef\n")
      end
    end

    describe ".insert_line_breaks" do
      let(:method) { :insert_line_breaks }

      it "replace newlines with <br>" do
        text = "abc\n<def>\nghi\n"
        expect(execute(text)).to eq("abc<br />\n<def><br />\nghi<br />\n")
      end

      it "normalizes <br> to <br />" do
        text = "abc<br>def<br/>ghi<br>x"
        expect(execute(text)).to eq("abc<br />def<br />ghi<br />x")
      end

      it "doesn't replace newlines if after <br />" do
        text = "abc\n<def><br />\nghi\n"
        expect(execute(text)).to eq("abc<br />\n<def><br />\nghi<br />\n")
      end

      it "ignores newlines inside <script> or <style>" do
        text = "abc\n<script xyz>\n\n</script>def\ng<style qrs>font\n</style>h"
        expect(execute(text)).to eq("abc<br />\n<script xyz>\n\n</script>def<br />\ng<style qrs>font\n</style>h")
      end
    end

    describe ".remove_br_after_opening_closing_block_tag" do
      let(:method) { :remove_br_after_opening_closing_block_tag }

      it "no preceeding br after block element" do
        text = "abc<form>xxx</form>"
        expect(execute(text)).to eq("abc<form>xxx</form>")
      end

      it "one following br" do
        text = "abc<math> \n <br />xyz</math>"
        expect(execute(text)).to eq("abc<math>xyz</math>")
      end

      it "two following br" do
        text = "abc<math> \n <br />xyz</math><br />z"
        expect(execute(text)).to eq("abc<math>xyz</math>z")
      end
    end

    describe ".remove_br_before_some_block_tags" do
      let(:method) { :remove_br_before_some_block_tags }

      it "no br before block element" do
        text = "abc<pre>xxx</pre>"
        expect(execute(text)).to eq("abc<pre>xxx</pre>")
      end

      it "one br before block element" do
        text = "abc<br /> <td>def"
        expect(execute(text)).to eq("abc <td>def")
      end

      it "two br before block element" do
        text = "abc<br /> <td>def <br /></dd>"
        expect(execute(text)).to eq("abc <td>def </dd>")
      end

      it "also remove \n before </p> at end of line" do
        text = "abc\n</p> def\n</p>"
        expect(execute(text)).to eq("abc\n</p> def</p>")
      end
    end

    describe ".restore_pre_with_placeholders" do
      let(:method) { :restore_pre_with_placeholders }

      it "no pre blocks" do
        text = "abc\ndef\n<h1>klm</h1>"
        expect(execute(text)).to eq("abc\ndef\n<h1>klm</h1>")
      end

      it "one pre block" do

        text = "abc<pre>\ndef\n</pre>ghi"

        # Setup pre_tags
        helper.send(:input_hook=, text) # Set instance variable
        helper.send(:replace_pre_with_placeholders)            # Run test
        expect(helper.send(:input_hook)).to eq("abc<pre wp-pre-tag-0></pre>ghi")

        helper.send(:restore_pre_with_placeholders)            # Run test
        expect(helper.send(:input_hook)).to eq(text)
      end

      it "two pre blocks" do
        text = "abc<pre>\ndef\n</pre>ghi<pre>hij</pre> klm"

        # Setup pre_tags
        helper.send(:input_hook=, text) # Set instance variable
        helper.send(:replace_pre_with_placeholders)            # Run test
        expect(helper.send(:input_hook)).to eq("abc<pre wp-pre-tag-0></pre>ghi<pre wp-pre-tag-1></pre> klm")

        helper.send(:restore_pre_with_placeholders)            # Run test
        expect(helper.send(:input_hook)).to eq(text)

      end

    end


    describe ".restore_newlines_in_elements_with_placeholders" do
      let(:method) { :restore_newlines_in_elements_with_placeholders }

      it "replaces with spaces around" do
        text = "<tag <!-- wpnl --> >"
        expect(execute(text)).to eq("<tag\n>")
      end

      it "replaces without spaces around" do
        text = "<tag<!-- wpnl -->>"
        expect(execute(text)).to eq("<tag\n>")
      end

    end

    describe ".replace_more_with_clear_both" do
      let(:method) { :replace_more_with_clear_both }

      it "replaces <!--more--> in text with clear-both " do
        text = "abc<!--more ignored -->def"
        expect(execute(text)).to eq('abc<div class="clear-both"></div>def')
      end

    end



















    # Tests on private routines


    describe ".split_html_elements_regex" do
      # Feel free to delete if fails

      subject(:regex) do
        helper.send(:split_html_elements_regex)
      end


      it "splits tags from text" do
        text = "xx<h1>wf<h2>goh"
        expect(text.split(regex)).to eq(["", "xx", "<h1>", "", "wf", "<h2>", "", "goh"])
      end

      it "handles missing end tag" do
        text = "xx<h1>wf<h2>goh<no ending"
        expect(text.split(regex)).to eq(["", "xx", "<h1>", "", "wf", "<h2>", "", "goh", "<no ending"])
      end

      it "handles <!-- --> comment" do
        text = "aa<!-- comment -->bb"
        expect(text.split(regex)).to eq(["", "aa", "<!-- comment -->", "", "bb"])
      end

      it "handles <![CDATA[xxx]]> comment" do
        text = "aa<![CDATA[comment]]>bb"
        expect(text.split(regex)).to eq(["", "aa", "<![CDATA[comment]]>", "", "bb"])
      end

      it "splits correctly with additional tags in comments" do
        text = "<h1><!-- comment<x>\n -->wso<![CDATA[wpo[ <x> \nefjpw]]>e"
        expect(text.split(regex)).to eq(["", "", "<h1>", "", "", "<!-- comment<x>\n -->", "", "wso", "<![CDATA[wpo[ <x>", "", " \nefjpw]]>e"])
      end

      it "splits on lots of different html tags" do
        text = "xx<h1>wf<h2>gohw</h1><!-- comment<x>\n -->wso<![CDATA[wpoefjpw]]>efj"
        expect(text.split(regex)).to eq(["", "xx", "<h1>", "", "wf", "<h2>", "", "gohw", "</h1>", "", "", "<!-- comment<x>\n -->", "", "wso", "<![CDATA[wpoefjpw]]>", "", "efj"])
      end

    end

    describe ".replace_in_html_tags" do
      # Feel free to delete if fails


      it "replaces nothing if no tags found" do
        text = "nothing will be replaced here"
        expect(helper.send(:replace_in_html_tags, text, {"\n" => "REPLACED"})).to eq("nothing will be replaced here")
      end

      it "replaces \\n only inside tags" do
        text = "xx\n<h1\n>wf<h2>go\nhw</h1\n>efj"
        expect(helper.send(:replace_in_html_tags, text, {"\n" => "REPLACED"})).to eq("xx\n<h1REPLACED>wf<h2>go\nhw</h1REPLACED>efj")
      end

      it "replaces \\n only inside comments" do
        text = "</h1><!-- comment<x>\n -->ws\no<![CDATA[wp\noefjpw]]>e\nfj"
        expect(helper.send(:replace_in_html_tags, text, {"\n" => "REPLACED"})).to eq("</h1><!-- comment<x>REPLACED -->ws\no<![CDATA[wpREPLACEDoefjpw]]>e\nfj")
      end

    end

  end

end
