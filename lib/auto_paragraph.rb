class AutoParagraph
  # Same as Wordpress' wpautop
  # From https://github.com/WordPress/WordPress/blob/4.3-branch/wp-includes/formatting.php

  BLOCK_LEVEL_TAGS = '(?:table|thead|tfoot|caption|col|colgroup|tbody|tr|td|th|div|dl|dd|dt|ul|ol|li|pre|form|map|area|blockquote|address|math|style|p|h[1-6]|hr|fieldset|legend|section|article|aside|hgroup|header|footer|nav|figure|figcaption|details|menu|summary)'

  def initialize(insert_line_breaks: true)
    @pre_tags = {}
    @insert_line_breaks = insert_line_breaks
  end

  def execute(input)
    return '' if input.strip.empty?

    @input = input.to_s

    setup_input_string

    add_placeholders
    add_p_tags
    remove_extraneous_p_tags
    insert_and_cleanup_br_tags

    replace_more_with_clear_both

    restore_placeholders

    @input
  end

  private


  # For testing
  def input_hook
    @input
  end

  def input_hook=(input)
    @input = input
  end

  def add_placeholders
    pad_newline
    replace_pre_with_placeholders
  end


  def setup_input_string
    multiple_brs_into_two_line_breaks
    add_single_line_break_above_block_level_opening_tags
    add_double_break_below_block_level_closing_tags
    standardize_newline_to_backslash_n
    replace_newlines_in_elements_with_placeholders
    collapse_line_breaks_around_option_elements
    collapse_line_breaks_inside_object_before_param_or_embed
    collapse_line_breaks_inside_audio_video_around_source_track
    remove_more_than_two_contiguous_line_breaks
  end

  def add_p_tags
    add_p_tags_at_doule_linebreaks
  end

  def remove_extraneous_p_tags
    remove_p_with_only_whitespace
    add_closing_p_inside_div_address_form
    unwrap_opening_closing_element_from_p
    unwrap_li_from_p
    unwrap_blockquote_from_p
    remove_preceeding_p_from_block_element_tag
    remove_following_p_from_block_element_tag
  end

  def insert_and_cleanup_br_tags
    insert_line_breaks
    remove_br_after_opening_closing_block_tag
    remove_br_before_some_block_tags
  end

  def restore_placeholders
    restore_pre_with_placeholders
    restore_newlines_in_elements_with_placeholders
  end

  def pad_newline
    @input += "\n"
  end

  def replace_pre_with_placeholders
    # Pre tags shouldn't be touched by autop.
    # Replace pre tags with placeholders and bring them back after autop.
    if @input.match("<pre")
      @pre_tags = {}

      input_parts = @input.split '</pre>'
      last_input_part = input_parts.pop

      input = ''
      input_parts.each_with_index do |input_part,i|

        start_position = input_part.index('<pre')

        # Malformed html?
        if !start_position
          input += input_part
          next
        end

        placeholder_name = "<pre wp-pre-tag-#{i}></pre>";
        @pre_tags[placeholder_name] = input_part[start_position..-1]+'</pre>'

        input += input_part[0..start_position-1] + placeholder_name
      end
      @input = input + last_input_part
    end
    @input
  end


  def multiple_brs_into_two_line_breaks
    @input.gsub! %r{<br\s*/?>\s*<br\s*/?>}, "\n\n"
  end


  def add_single_line_break_above_block_level_opening_tags
    @input.gsub! %r{(<#{BLOCK_LEVEL_TAGS}[^>]*>)}, "\n\\1"
  end

  def add_double_break_below_block_level_closing_tags
  # input = preg_replace('!(</' . $allblocks . '>)!', "$1\n\n", input);
    @input.gsub! %r{(</#{BLOCK_LEVEL_TAGS}>)}, "\\1\n\n"
  end

  def standardize_newline_to_backslash_n
    ["\r\n","\r"].each do |from|
      @input.gsub! from, "\n"
    end
  end

  def replace_newlines_in_elements_with_placeholders
    @input = replace_in_html_tags(@input, { "\n" => " <!-- wpnl --> " })
  end

  def collapse_line_breaks_around_option_elements
    if @input.match("<option")
      @input.gsub!(/\s*<option/, '<option');
      @input.gsub!(/<\/option>\s*/, '</option>');
    end
  end

  def collapse_line_breaks_inside_object_before_param_or_embed
    # Collapse line breaks inside <object> elements, before <param> and <embed> elements
    if @input.match("</object>")
      @input.gsub!(/(<object[^>]*>)\s*/, "\\1")
      @input.gsub!(/\s*<\/object>/, '</object>')
      @input.gsub!(/\s*(<\/?(?:param|embed)[^>]*>)\s*/, "\\1")
    end
  end

  def collapse_line_breaks_inside_audio_video_around_source_track
    # Collapse line breaks inside <audio> and <video> elements,
    # before and after <source> and <track> elements.
    if @input.match("<source") || @input.match("<track")
      @input.gsub!(%r{([<\[](?:audio|video)[^>\]]*[>\]])\s*}, "\\1")
      @input.gsub!(%r{\s*([<\[]/(?:audio|video)[>\]])}, "\\1")
      @input.gsub!(%r{\s*(<(?:source|track)[^>]*>)\s*}, "\\1")
    end
  end


  def remove_more_than_two_contiguous_line_breaks
    @input.gsub!(/\n\n+/, "\n\n")
  end

  def add_p_tags_at_doule_linebreaks
    # Split up the contents into an array of strings, separated by double line breaks.
    @input = @input.split(/\n\s*\n/).map do |para|
        '<p>'+para.sub(/^\n+/,'').sub(/\n+$/,'')+"</p>\n"
    end.join("")
  end

  def remove_p_with_only_whitespace
    # Under certain strange conditions it could create a P of entirely whitespace.
    @input.gsub!(%r{<p>\s*</p>}, '')
  end

  def add_closing_p_inside_div_address_form
    #Add a closing <p> inside <div>, <address>, or <form> tag if missing.
    @input.gsub!(%r{<p>([^<]+)</(div|address|form)>}, "<p>\\1</p></\\2>")
  end

  def unwrap_opening_closing_element_from_p
    #  If an opening or closing block element tag is wrapped in a <p>, unwrap it.
    @input.gsub!(%r{<p>\s*(</?#{BLOCK_LEVEL_TAGS}[^>]*>)\s*</p>}, "\\1")
  end

  def unwrap_li_from_p
    # In some cases <li> may get wrapped in <p>, fix them.
    @input.gsub!(%r{<p>(<li.+?)</p>}, "\\1")
  end


  def unwrap_blockquote_from_p
    # If a <blockquote> is wrapped with a <p>, move it inside the <blockquote>.
    @input.gsub!(%r{<p><blockquote([^>]*)>}i, "<blockquote\\1><p>")
    @input.gsub!("</blockquote></p>", "</p></blockquote>")
  end

  def remove_preceeding_p_from_block_element_tag
    # If an opening or closing block element tag is preceded by an opening <p> tag, remove it.
    @input.gsub!(%r{<p>\s*(</?#{BLOCK_LEVEL_TAGS}[^>]*>)}, "\\1")
  end

  def remove_following_p_from_block_element_tag
    # If an opening or closing block element tag is followed by a closing <p> tag, remove it.
    @input.gsub!(%r{(</?#{BLOCK_LEVEL_TAGS}[^>]*>)\s*</p>}, "\\1")
  end

  def insert_line_breaks
    # Optionally insert line breaks.
    if @insert_line_breaks
      # Replace newlines that shouldn't be touched with a placeholder.
      @input.gsub!(%r{<(script|style).*?</\1>}m) do |match|
        match.gsub("\n", "<WPPreserveNewline />")
      end

      # Normalize <br>
      @input.gsub!(Regexp.union('<br>', '<br/>'), '<br />')

      # Replace any new line characters that aren't preceded by a <br /> with a <br />.
      @input.gsub!(%r{(?<!<br />)\s*\n}, "<br />\n")

      # Replace newline placeholders with newlines.
      @input.gsub!('<WPPreserveNewline />', "\n")
    end
  end

  def remove_br_after_opening_closing_block_tag
    # If a <br /> tag is after an opening or closing block tag, remove it.
    @input.gsub!(%r{(</?#{BLOCK_LEVEL_TAGS}[^>]*>)\s*<br />}, "\\1")
  end

  def remove_br_before_some_block_tags
    # If a <br /> tag is before a subset of opening or closing block tags, remove it.
    @input.gsub!(%r{<br />(\s*</?(?:p|li|div|dl|dd|dt|th|pre|td|ul|ol)[^>]*>)}, "\\1")
    @input.gsub!(%r{\n</p>$}, "</p>")
  end

  def replace_more_with_clear_both
    @input.gsub! %r{<!--more(.*?)?-->}, '<div class="clear-both"></div>'
  end

  def restore_pre_with_placeholders
    # Replace placeholder <pre> tags with their original content.
    @pre_tags.each do |key, val|
      @input.gsub!(key, val)
    end
  end

  def restore_newlines_in_elements_with_placeholders
    # Restore newlines in all elements.
    @input.gsub!(Regexp.union(' <!-- wpnl --> ', '<!-- wpnl -->'), "\n")
  end


  def split_html_elements_regex

    comments =
          '!'          + # Start of comment, after the <.
         '(?:'         + # Unroll the loop: Consume everything until --> is found.
             '-(?!->)' + # Dash not followed by end of comment.
             '[^\-]*+' + # Consume non-dashes.
         ')*+'         + # Loop possessively.
         '(?:-->)?'      # End of comment. If not found, match all input.

    cdata =
          '!\[CDATA\['  + # Start of comment, after the <.
         '[^\]]*+'      + # Consume non-].
         '(?:'          + # Unroll the loop: Consume everything until ]]> is found.
             '\](?!\]>)'  + # One ] not followed by end of comment.
             '[^\]]*+'  + # Consume non-].
         ')*+'          + # Loop possessively.
         '(?:\]\]>)?'       # End of comment. If not found, match all input.

    regex =
          '([^<]*)'                  + # Find from the start of the string
          '('                        + # Capture the tag
             '<'                     + # Find start of element.
             '(?:'                   + # (non-matching group)
                '(?=!--)'            + # Is this a comment?
                comments             + # Find end of comment
             ')'                     +
             '|'                     + # OR
             '(?:'                   + # (non-matching group)
               '(?=!\[CDATA\[)'      + # Is this a comment?
               cdata                 + # Find end of comment
             ')'                     +
             '|'                     + # OR
             '(?:'                   + # (non-matching group)
               '[^>]*'               + # Find end of element.
             ')'                     + #
             '>?'                    + # If not found, match all input.
         ')'

    Regexp.new(regex, Regexp::MULTILINE)
  end

  def split_html_elements(text)
    text.split(split_html_elements_regex)
  end

  def every_tag_only(source)
    # Returns every third element starting at 3:  ["","data","<tag>","","more data","</closetag>"] => ["<tag>","</closetag>"]
    source.drop(2).each_slice(3).map(&:first)
  end

  def replace_in_html_tags(haystack, replace_pairs)
    # find all elements
    tags_split = split_html_elements(haystack)
    changed = false

    # Loop through every third element (html tags only)
    keys = Regexp.new(replace_pairs.keys.join("|"))
    every_tag_only(tags_split).each do |tag|
      # Changes existing string, so replaces inside tags_split array
      changed = true if tag.gsub!(keys, replace_pairs)
    end

    haystack = tags_split.join("") if changed

    haystack
  end

end
