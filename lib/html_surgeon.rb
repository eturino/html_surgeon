require 'naught'
require 'oj'
require 'oj_mimic_json'
require 'nokogiri'
require 'active_support/all'
require 'html_surgeon/version'
require 'html_surgeon/abstract_method_error'
require 'html_surgeon/auditor'
require 'html_surgeon/node_reverser'
require 'html_surgeon/node_audit_cleaner'
require 'html_surgeon/service'
require 'html_surgeon/change_set'
require 'html_surgeon/change'
require 'html_surgeon/changes'
require 'html_surgeon/changes/add_css_class'
require 'html_surgeon/changes/replace_tag_name'

module HtmlSurgeon
  DATA_CHANGE_AUDIT_ATTRIBUTE = 'data-surgeon-audit'.freeze

  def self.for(html_string, **options)
    Service.new html_string, **options
  end

  # helper methods
  def self.node_has_css_class?(nokogiri_node, css_class)
    Changes::AddCssClass.has_class? nokogiri_node, css_class
  end

end
