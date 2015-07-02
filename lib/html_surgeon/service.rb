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
      ChangeSet.create(node_set, self)
    end

    def rollback(change_set: nil, changed_at: nil, changed_from: nil)
      doc.css("[#{DATA_CHANGE_AUDIT_ATTRIBUTE}]").each do |node|
        NodeReverser.new(node: node, change_set: change_set, changed_at: changed_at, changed_from: changed_from).call
      end

      self
    end

    private
    def doc
      @doc ||= Nokogiri::HTML.fragment @given_html.dup
    end
  end
end
