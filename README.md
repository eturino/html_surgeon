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

# you can review what was changed in the change set
change_set.changes
# =>
# [
#   "replace tag name with article",
#   "add css class added-class",
#   "add css class another-added-class",
# ]
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

If we have enabled audit, we'll get the changes applied to an element in an data attribute.
It will store, in JSON, an array with all the changes.

```ruby
surgeon = HtmlService.for(GIVEN_HTML, audit: true)
surgeon.css('.lol').replace_tag_name('span').add_css_class('hey').run
surgeon.html # =>
# <div>
#     <h1>Something</h1>
#     <span id="1" class="lol to-be-changed hey" data-surgeon-audit='[{"change_set":"830e96dc-fa07-40ce-8968-ea5c55ec4b84","changed_at":"2015-07-02T12:52:43.874Z","type":"replace_tag_name","old":"div","new":"span"},{"change_set":"830e96dc-fa07-40ce-8968-ea5c55ec4b84","changed_at":"2015-07-02T12:52:43.874Z","type":"add_css_class","existed_before":false,"class":"hey"}]'>1</span>
#     <span>Other</span>
#     <div id="2" class="another to-be-changed">
#         <ul>
#             <li>1</li>
#             <li>2</li>
#         </ul>
#     </div>
# </div>
```

the attribute's value (formatted) is:

```json
[
  {
    "change_set":"830e96dc-fa07-40ce-8968-ea5c55ec4b84",
    "changed_at":"2015-07-02T12:52:43.874Z",
    "type":"replace_tag_name",
    "old":"div",
    "new":"span"
  },
  {
    "change_set":"830e96dc-fa07-40ce-8968-ea5c55ec4b84",
    "changed_at":"2015-07-02T12:52:43.874Z",
    "type":"add_css_class",
    "existed_before":false,
    "class":"hey"
  }
]
```

it has a `change_set` with the ID of the change set, `changed_at` with the moment it was applied, and the rest define the change.

## Selecting the Node Set

we use Nokogiri's selections.

### using css

```ruby
change_set = surgeon.css('div.to-be-changed')
```

### using xpath

```ruby
change_set = surgeon.xpath("span") # note that we use Nokogiri's HTML Fragment and the use of self is special.
```

### Refining the selection

we can skip some nodes based on callbacks added to the Change Set using `select` and `reject` methods.

```ruby
change_set = surgeon.css('.to-be-changed')
change_set.reject { |node| node.name == 'div' }.select { |node| node.get_attribute('class').to_s.split(' ').include? 'yeah-do-it' }
change_set.run # => nodes skipped if reject callback return truthy or if select callback return falsey 
```

## Available Changes

### Replace Tag Name

```ruby
surgeon.css('div.to-be-changed').replace_tag_name('article')
```

### Add CSS Class

```ruby
surgeon.css('div.to-be-changed').add_css_class('applied-some-stuff')
```

## Rollback

the surgeon can be used to revert any audited rollback. We can select what changes to rollback based on:

- `change_set`: The change_set UUID
- `changed_at`: The change timestamp
- `changed_from`: All changes which timestamp is more recent than the given time

We can also revert all audited changes.

```ruby
surgeon = HtmlSurgeon.for(GIVEN_HTML) 

surgeon.rollback.html # => returns the html with all events reverted 
surgeon.rollback(change_set: uuid).html # => returns the html with only the given change set reverted
surgeon.rollback(changed_at: changed_at).html  # => returns the html with only the change set with timestamp reverted
surgeon.rollback(changed_from: changed_from).html # => returns the html with any change sets with a timestamp more recent than `changed_from` reverted 
```

## Clear Audit trail

we can clear all audit from the given html with the `clear_audit` method. 

```ruby
surgeon = HtmlSurgeon.for(GIVEN_HTML)
surgeon.clear_audit.html # => returns the html with all audit html attributes removed
```

## Helper Methods

### `HtmlSurgeon.node_has_css_class?(nokogiri_node, css_class)`

it will return true if the given nokogiri node has that css_class

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'html_surgeon'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install html_surgeon


## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake rspec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/eturino/html_surgeon.


## CHANGESET

### v0.5.0

- added `node_has_css_class?` helper method to `HtmlSurgeon`
- added `clear_audit` to surgeon 

### v0.4.0

- added `select` and `reject` callbacks to Change Set, based on blocks with `node` as single argument

### v0.3.0

- added fluid ChangeSet ID setter
- added change_set xpath support

### v0.2.0
- added rollback support
