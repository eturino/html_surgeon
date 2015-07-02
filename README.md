# HtmlSurgeon


[![Gem Version](https://badge.fury.io/rb/html_surgeon.svg)](http://badge.fury.io/rb/html_surgeon)
[![Build Status](https://travis-ci.org/eturino/html_surgeon.svg?branch=master)](https://travis-ci.org/eturino/html_surgeon)
[![Code Climate](https://codeclimate.com/github/eturino/html_surgeon.png)](https://codeclimate.com/github/eturino/html_surgeon)
[![Code Climate Coverage](https://codeclimate.com/github/eturino/html_surgeon/coverage.png)](https://codeclimate.com/github/eturino/html_surgeon)

Make specific changes in a HTML string, optionally adding html attributes with the audit trail of the changes. Uses [Nokogiri](http://www.nokogiri.org/).

## Basic Usage

First, you create a HtmlSurgeon service instance for the given html fragment

```ruby
GIVEN_HTML = <<-HTML
<div>
    <h1>Something</h1>
    <div id="1" class="lol to-be-changed">1</div>
    <span>Other</span>
    <div id="2" class="another to-be-changed">
        <ul>
            <li>1</li>
            <li>2</li>
        </ul>
    </div>
</div>
HTML

surgeon = HtmlSurgeon.for(GIVEN_HTML) 
```

if you want to add audit attributes in the HTML tags changed, pass the option in the surgeon service creation

```ruby
surgeon = HtmlSurgeon.for(GIVEN_HTML, audit: true)
```

with the surgeon service, you can prepare several change sets. A change set is defined by a node set and a list of changes to be applied on each selected node.

```ruby
change_set = surgeon.css('div.to-be-changed') # => will return a change_set

change_set.node_set # => will return a Nokogiri's Node Set with the selected nodes (right now it'll get us div ID 1 and div ID 2.

# to prepare a change replace the tag name 'div' for 'article'
change_set.replace_tag_name('article') 
    
# to prepare another change to add a css class in the selected nodes
change_set.add_css_class('added-class')

# we can add a second one
change_set.add_css_class('another-added-class') 

```

The changes are not made yet. In order to do it, we call `run` on the change set

```ruby
change_set.run

surgeon.html # => html with the changes applied
# =>
# <div>
#     <h1>Something</h1>
#     <article id="1" class="lol to-be-changed added-class another-added-class">1</div>
#     <span>Other</span>
#     <article id="2" class="another to-be-changed added-class another-added-class">
#         <ul>
#             <li>1</li>
#             <li>2</li>
#         </ul>
#     </div>
# </div>


# original html still in
surgeon.given_html == GIVEN_HTML # => true
```

We can also chain call the changes in a changeset

```ruby
surgeon = HtmlService.for(GIVEN_HTML)
surgeon.css('.lol').replace_tag_name('span').add_css_class('hey').run
surgeon.html # =>
# <div>
#     <h1>Something</h1>
#     <span id="1" class="lol to-be-changed hey">1</span>
#     <span>Other</span>
#     <div id="2" class="another to-be-changed">
#         <ul>
#             <li>1</li>
#             <li>2</li>
#         </ul>
#     </div>
# </div>
```

## Selecting the Node Set

we use Nokogiri's selections.

### using css

```ruby
change_set = surgeon.css('div.to-be-changed')
```

### using xpath

not implemented yet.


## Available Changes

### Replace Tag Name

```ruby
surgeon.css('div.to-be-changed').replace_name_tag('article')
```

### Add CSS Class

```ruby
surgeon.css('div.to-be-changed').add_css_class('applied-some-stuff')
```



## Installation

Add this line to your application's Gemfile:

```ruby
gem 'html_surgeon'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install html_surgeon

## Usage

TODO: Write usage instructions here

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake rspec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/eturino/html_surgeon.

