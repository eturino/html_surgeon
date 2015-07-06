require 'spec_helper'

describe HtmlSurgeon do
  it 'has a version number' do
    expect(HtmlSurgeon::VERSION).not_to be nil
  end

  let(:lookup_css_class) { 'my-class' }

  let(:html) do
    <<-HTML
    <h3>Show tickets</h3> <p class="#{lookup_css_class}">Your show/event ticket(s) will be given to you by your Newmarket Tour Manager on the day.</p> <h3>Coach seating arrangements</h3> <p>Your Tour Manager will have allocated seats for you on the main coach in advance, taking into consideration any special requests wherever possible, and will advise you where to sit as you board the coach. This will be your seat for the duration of the tour. (Seats are not allocated on any connecting services to and from the main coach).</p> <h3>Joining your holiday</h3> <p>Your final travel documents, including the exact time and place of departure, will be sent to you approximately ten days prior to departure, providing all payments have been made. We are unable to give exact departure times before this.</p> <h3>Meal arrangements</h3> <p>Where meals are not included, your Tour Manager will ensure there are suitable stops made for you to purchase and enjoy lunch and/or dinner each day.</p> <h3>Special requirements</h3> <p>If you have notified us of any special requirements, please check that they have been noted and acknowledged. This is especially important with any dietary needs you may have.</p> <h3>Disabled access</h3> <p>The majority of our tours involve a certain amount of walking, including a short walk from the coach stop to the town, attraction or venue you're visiting. If you are bringing a wheelchair or electric scooter, please let us know as soon as possible so that appropriate arrangements can be made.</p>
    HTML
  end

  let(:options) { {}.merge audit_options }
  let(:audit_options) { {} }

  subject { described_class.for html, **options }

  let(:surgeon) { subject }

  describe '.for' do
    it 'returns a Service instance with given data' do
      expect(subject).to be_a HtmlSurgeon::Service
      expect(subject.html).to eq html
    end
  end

  describe '.node_has_css_class?' do
    it 'returns true if the given nokogiri node has the given css_class' do
      node = subject.css(".#{lookup_css_class}").node_set.first
      expect(described_class.node_has_css_class? node, lookup_css_class).to be_truthy
      expect(described_class.node_has_css_class? node, 'not-me').to be_falsey
    end
  end

  describe '#given_html' do
    it 'returns the given html string unmodified, the same object as the init param' do
      expect(subject.given_html).to eq html
      expect(subject.given_html.object_id).to eq html.object_id
    end
  end

  describe '#html' do
    it 'returns a copy of the given html string, to be modified by the service' do
      expect(subject.html).to eq html
      expect(subject.html.object_id).not_to eq html.object_id
    end
  end

  describe '#audit?' do
    context 'with audit option enabled' do
      let(:audit_options) { { audit: true } }
      it { expect(subject.audit?).to be_truthy }
    end

    context 'with audit option disabled' do
      let(:audit_options) { { audit: false } }
      it { expect(subject.audit?).to be_falsey }
    end

    context 'without audit option' do
      let(:audit_options) { {} }
      it { expect(subject.audit?).to be_falsey }
    end
  end

  describe 'change all h3 for h4' do
    let(:css_selector) { "#{old_tag_name}" }
    let(:xpath_selector) { "#{old_tag_name}" }
    let(:old_tag_name) { 'h3' }
    let(:new_tag_name) { 'h4' }
    let(:added_css_class) { 'my-added-css-class' }

    describe 'ChangeSet' do
      describe 'service#css' do
        it 'returns a ChangeSet where we can chain call different changes. Exposes the Nokogiri with #node_set and delegates to the service the modified html with #html' do
          change_set = subject.css(css_selector)
          expect(change_set.node_set.size).to eq 6 # amount of h3 tags
          expect(change_set.html).to eq subject.html
        end
      end

      describe 'service#xpath' do
        it 'returns a ChangeSet where we can chain call different changes. Exposes the Nokogiri with #node_set and delegates to the service the modified html with #html' do
          change_set     = subject.xpath(xpath_selector)
          css_change_set = subject.css(css_selector)
          expect(change_set.node_set.size).to eq 6 # amount of h3 tags
          expect(change_set.html).to eq subject.html

          expect(change_set.node_set.map(&:to_html)).to eq(css_change_set.node_set.map(&:to_html))
        end
      end

      describe '#id' do
        let(:change_set) { subject.css(css_selector) }
        context 'with argument' do
          it 'sets the change set ID and returns the same changeset' do
            id = 'myid'

            expect(change_set.id).not_to eq id
            expect(change_set.id id).to eq change_set
            expect(change_set.id).to eq id
          end
        end

        context 'without argument' do
          let(:id) { 'paco' }

          before do
            expect(SecureRandom).to receive(:uuid).and_return(id)
          end

          it 'returns the changeset ID' do
            expect(change_set.id).to eq id
          end
        end

      end

      context 'callbacks' do
        let(:html) do
          <<-HTML
<div>
    <h1>Something</h1>
    <div id="1" class="lol to-be-changed">1</div>
    <span>Other</span>
    <div id="2" class="another to-be-changed skip-me">
        <ul>
            <li>1</li>
            <li>2</li>
        </ul>
    </div>
</div>
          HTML
        end

        let(:expected_html) do
          <<-HTML
<div>
    <h1>Something</h1>
    <span id="1" class="lol to-be-changed">1</span>
    <span>Other</span>
    <div id="2" class="another to-be-changed skip-me">
        <ul>
            <li>1</li>
            <li>2</li>
        </ul>
    </div>
</div>
          HTML
        end

        let(:css_selector) { 'div.to-be-changed' }
        let(:change_set) { subject.css(css_selector) }

        describe '#reject' do
          it 'returns self after adding a callback to the given block, passing the node as first argument, that will skip any action on the Node if returns truthy' do
            res = change_set.reject { |node| node.get_attribute('class').to_s.split(' ').include? 'skip-me' }
            expect(res).to eq change_set
            change_set.replace_tag_name('span').run
            expect(change_set.html).to eq expected_html

            expect(change_set.node_set.size).to eq 2
            expect(change_set.changed_nodes.size).to eq 1
            expect(change_set.changed_nodes_size).to eq 1
          end
        end

        describe '#select' do
          it 'returns self after adding a callback to the given block, passing the node as first argument, that will skip any action on the Node unless returns truthy' do
            res = change_set.select { |node| !node.get_attribute('class').to_s.split(' ').include? 'skip-me' }
            expect(res).to eq change_set
            change_set.replace_tag_name('span').run
            expect(change_set.html).to eq expected_html

            expect(change_set.node_set.size).to eq 2
            expect(change_set.changed_nodes.size).to eq 1
            expect(change_set.changed_nodes_size).to eq 1
          end
        end
      end

      describe '#replace_tag_name' do
        it 'adds a ReplaceTagName change: prepares the change, but does not apply anything yet' do
          change_set = subject.css(css_selector)
          x          = change_set.replace_tag_name(new_tag_name)
          expect(x).to eq change_set
          expect(change_set.changes).to eq ["replace tag name with #{new_tag_name}"]

          expect(subject.html).to eq html
        end
      end

      describe '#add_css_class' do
        it 'adds a AddCssClass change: prepares the change, but does not apply anything yet' do
          change_set = subject.css(css_selector)
          x          = change_set.add_css_class(added_css_class)
          expect(x).to eq change_set
          expect(change_set.changes).to eq ["add css class #{added_css_class}"]

          expect(subject.html).to eq html
        end
      end

      describe '#run' do
        let(:change_set) { subject.css(css_selector) }
        let(:run_changes) { change_set.replace_tag_name(new_tag_name).add_css_class(added_css_class).run
        }

        it 'applies the changes in the css selected node set on the final run chained call (returns the change set)' do
          run_changes
          expect(run_changes).to eq change_set
          expect(subject.html).not_to include old_tag_name
          expect(subject.html).to include new_tag_name

          expect(subject.given_html).to eq html
        end

        context 'with audit on' do
          let(:audit_options) { { audit: true } }

          it 'adds to each node a data-surgeon-audit attribute with an array with a json representation of the change' do
            run_changes

            audit_changes = [
              {
                change_set: change_set.id,
                changed_at: change_set.run_time,
                type:       :replace_tag_name,
                old:        old_tag_name,
                new:        new_tag_name
              },
              {
                change_set:     change_set.id,
                changed_at:     change_set.run_time,
                type:           :add_css_class,
                existed_before: false,
                class:          added_css_class
              }
            ]

            audit_changes_json = Oj.dump audit_changes

            expect(subject.html).to include "<#{new_tag_name} data-surgeon-audit='#{audit_changes_json}' class=\"#{added_css_class}\">"
          end
        end

        context 'with audit off' do
          let(:audit_options) { { audit: false } }

          it 'does not add any data-surgeon-audit attribute' do
            run_changes
            expect(subject.html).not_to include 'data-surgeon-audit'
          end
        end
      end
    end

    describe 'Change' do
      it 'should not be used directly but as an abstract class' do
        change = HtmlSurgeon::Change.new change_set: nil
        expect { change.send :log }.to raise_error HtmlSurgeon::AbstractMethodError
        expect { change.send :audit_data, nil }.to raise_error HtmlSurgeon::AbstractMethodError
        expect { change.send :apply_in, nil }.to raise_error HtmlSurgeon::AbstractMethodError
      end
    end
  end

  describe 'with README data' do
    let(:html) do
      <<-HTML
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
    end

    let(:audit_options) { { audit: true } }

    let(:expected_html) do
      <<-HTML
<div>
    <h1>Something</h1>
    <span id="1" class="lol to-be-changed hey" data-surgeon-audit='[{"change_set":"#{id}","changed_at":#{changed_at},"type":"replace_tag_name","old":"div","new":"span"},{"change_set":"#{id}","changed_at":#{changed_at},"type":"add_css_class","existed_before":false,"class":"hey"}]'>1</span>
    <span>Other</span>
    <div id="2" class="another to-be-changed">
        <ul>
            <li>1</li>
            <li>2</li>
        </ul>
    </div>
</div>
      HTML
    end

    let(:change_set) { surgeon.css('.lol') }
    let(:id) { change_set.id }
    let(:changed_at) { Oj.dump change_set.run_time }

    let(:run_change) { change_set.replace_tag_name('span').add_css_class('hey').run }

    it 'works' do
      run_change
      expect(surgeon.html).to eq expected_html
    end

    context 'rollback and clean up' do
      let(:rolledback_html) do
        <<-HTML
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
      end

      let(:partially_rolledback_html) do
        <<-HTML
<div>
    <h1>Something</h1>
    <div id="1" class="lol to-be-changed">1</div>
    <span>Other</span>
    <div id="2" class="another to-be-changed">
        <ul class="yeah" data-surgeon-audit='[{"change_set":"#{id2}","changed_at":"#{changed_at2}","type":"add_css_class","existed_before":false,"class":"yeah"}]'>
            <li>1</li>
            <li>2</li>
        </ul>
    </div>
</div>
        HTML
      end

      let(:html) do
        <<-HTML
<div>
    <h1>Something</h1>
    <span id="1" class="lol to-be-changed hey" data-surgeon-audit='[{"change_set":"#{id}","changed_at":"#{changed_at}","type":"replace_tag_name","old":"div","new":"span"},{"change_set":"#{id}","changed_at":"#{changed_at}","type":"add_css_class","existed_before":false,"class":"hey"}]'>1</span>
    <span>Other</span>
    <div id="2" class="another to-be-changed">
        <ul class="yeah" data-surgeon-audit='[{"change_set":"#{id2}","changed_at":"#{changed_at2}","type":"add_css_class","existed_before":false,"class":"yeah"}]'>
            <li>1</li>
            <li>2</li>
        </ul>
    </div>
</div>
        HTML
      end

      let(:clear_audit_html) do
        <<-HTML
<div>
    <h1>Something</h1>
    <span id="1" class="lol to-be-changed hey">1</span>
    <span>Other</span>
    <div id="2" class="another to-be-changed">
        <ul class="yeah">
            <li>1</li>
            <li>2</li>
        </ul>
    </div>
</div>
        HTML
      end

      let(:id) { '830e96dc-fa07-40ce-8968-ea5c55ec4b84' }
      let(:id2) { SecureRandom.uuid }
      let(:changed_at) { '2015-07-02T12:52:43.874Z' }
      let(:changed_at2) { '2015-06-01T10:10:10.123Z' }
      let(:changed_from) { '2015-07-01'.to_date }

      describe '#rollback' do
        context 'all' do
          let(:rollback_options) { {} }

          it 'reverts all audited changes; returns number of changes' do
            res = subject.rollback **rollback_options
            expect(res).to eq 3
            expect(subject.html).to eq rolledback_html
          end
        end

        context 'with change_set id' do
          let(:rollback_options) { { change_set: id } }

          it 'reverts all audited changes; returns number of changes' do
            res = subject.rollback **rollback_options
            expect(res).to eq 2
            expect(subject.html).to eq partially_rolledback_html
          end
        end

        context 'with changed_at timestamp' do
          let(:rollback_options) { { changed_at: changed_at } }

          it 'reverts all audited changes; returns number of changes' do
            res = subject.rollback **rollback_options
            expect(res).to eq 2
            expect(subject.html).to eq partially_rolledback_html
          end
        end

        context 'with changed_from (rollback all changes from that moment onwards)' do
          let(:rollback_options) { { changed_from: changed_from } }

          it 'reverts all audited changes; returns number of changes' do
            res = subject.rollback **rollback_options
            expect(res).to eq 2
            expect(subject.html).to eq partially_rolledback_html
          end
        end
      end

      describe '#clear_audit' do
        it 'will remove from html all the audit attributes, without performing any rollback; returns number of changes' do
          res = subject.clear_audit
          expect(res).to eq 2
          expect(subject.html).to eq clear_audit_html
        end
      end

      context 'empty change set (search resulting in an empty node set)' do
        it 'does not do anything and works' do
          expect(subject.css('article').replace_tag_name('section').run.html).to eq html
        end
      end

      context 'with nil given html' do
        let(:html) { nil }

        it 'does not do anything and works' do
          expect(subject.css('article').replace_tag_name('section').run.html).to eq ''
        end
      end
    end
  end
end
