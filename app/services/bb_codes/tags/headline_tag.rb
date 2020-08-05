class BbCodes::Tags::HeadlineTag
  include Singleton

  HEADLINES_REGEXP = /^(?<level>\#{1,5})\ (?<text>.*) (?:\n|$) /x

  def format text
    text.gsub(HEADLINES_REGEXP) do |match|
      case $LAST_MATCH_INFO[:level]
      when '#'
        h2_html $LAST_MATCH_INFO[:text]

      when '##'
        h3_html $LAST_MATCH_INFO[:text]

      when '###'
        h4_html $LAST_MATCH_INFO[:text]

      else
        match
      end
    end
  end

private

  def h2_html text
    "<h2>#{text}</h2>"
  end

  def h3_html text
    "<h3>#{text}</h3>"
  end

  def h4_html text
    "<h4>#{text}</h4>"
  end
end
