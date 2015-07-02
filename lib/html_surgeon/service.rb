module HtmlSurgeon
  class Service
    attr_reader :given_html, :options

    def initialize(html_string, audit: false, **extra_options)
      @given_html = html_string
      @audit      = audit
      @options    = extra_options.merge audit: audit
    end

    def html
      @html ||= doc.to_html
    end

    def audit?
      !!@audit
    end

    def css(css_selector)
      node_set = doc.css(css_selector)
      ChangeSet.new(node_set, self)
    end

    private
    def doc
      @doc ||= Nokogiri::HTML.fragment @given_html.dup
    end
  end
end
