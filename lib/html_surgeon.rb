require 'oj_mimic_json'
require 'nokogiri'
require 'active_support/all'
require 'html_surgeon/version'
require 'html_surgeon/abstract_method_error'
require 'html_surgeon/service'
require 'html_surgeon/change_set'
require 'html_surgeon/change'
require 'html_surgeon/changes/add_css_class'
require 'html_surgeon/changes/replace_tag_name'

module HtmlSurgeon
  def self.for(html_string, **options)
    Service.new html_string, **options
  end
end
