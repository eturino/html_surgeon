module HtmlSurgeon
  class Service
    attr_reader :given_html, :options

    def initialize(html_string, audit: false, **extra_options)
      @given_html = html_string.to_s
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

    def xpath(xpath_selector)
      node_set = doc.xpath(xpath_selector)
      ChangeSet.create(node_set, self)
    end

    # returns the number of changes performed
    def rollback(change_set: nil, changed_at: nil, changed_from: nil)
      doc.css("[#{DATA_CHANGE_AUDIT_ATTRIBUTE}]").reduce(0) do |sum, node|
        reverser = NodeServices::Reverser.new node:         node,
                                    change_set:   change_set,
                                    changed_at:   changed_at,
                                    changed_from: changed_from
        sum + reverser.call
      end
    end

    def clear_audit
      doc.css("[#{DATA_CHANGE_AUDIT_ATTRIBUTE}]").reduce(0) do |sum, node|
        cleaner = NodeServices::AuditCleaner.new node: node
        sum + cleaner.call
      end
    end

    private
    def doc
      @doc ||= Nokogiri::HTML.fragment @given_html.dup
    end
  end
end
