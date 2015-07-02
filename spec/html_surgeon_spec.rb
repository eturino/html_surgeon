require 'spec_helper'

describe HtmlSurgeon do
  it 'has a version number' do
    expect(HtmlSurgeon::VERSION).not_to be nil
  end

  let(:html) do
    <<-HTML
    <h3>Show tickets</h3> <p>Your show/event ticket(s) will be given to you by your Newmarket Tour Manager on the day.</p> <h3>Coach seating arrangements</h3> <p>Your Tour Manager will have allocated seats for you on the main coach in advance, taking into consideration any special requests wherever possible, and will advise you where to sit as you board the coach. This will be your seat for the duration of the tour. (Seats are not allocated on any connecting services to and from the main coach).</p> <h3>Joining your holiday</h3> <p>Your final travel documents, including the exact time and place of departure, will be sent to you approximately ten days prior to departure, providing all payments have been made. We are unable to give exact departure times before this.</p> <h3>Meal arrangements</h3> <p>Where meals are not included, your Tour Manager will ensure there are suitable stops made for you to purchase and enjoy lunch and/or dinner each day.</p> <h3>Special requirements</h3> <p>If you have notified us of any special requirements, please check that they have been noted and acknowledged. This is especially important with any dietary needs you may have.</p> <h3>Disabled access</h3> <p>The majority of our tours involve a certain amount of walking, including a short walk from the coach stop to the town, attraction or venue you're visiting. If you are bringing a wheelchair or electric scooter, please let us know as soon as possible so that appropriate arrangements can be made.</p>
    HTML
  end

  let(:options) { {}.merge audit_options }
  let(:audit_options) { {} }

  subject { described_class.for html, **options }

  describe '.for' do
    it 'returns a Service instance with given data' do
      expect(subject).to be_a HtmlSurgeon::Service
      expect(subject.html).to eq html
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
    let(:old_tag_name) { 'h3' }
    let(:new_tag_name) { 'h4' }
    let(:added_css_class) { 'my-added-css-class' }

    describe 'ChangeSet' do
      describe 'service#css' do
        it 'returns a ChangeSet where we can chain call different changes, and apply them at the end, exposing the Nokogiri node_set' do
          change_set = subject.css(css_selector)
          expect(change_set.node_set.size).to eq 6 # amount of h3 tags
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
        let(:run_changes) { subject.css(css_selector).replace_tag_name(new_tag_name).add_css_class(added_css_class).run
        }

        it 'applies the changes in the css selected node set on the final run chained call' do
          run_changes
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
                type: :replace_tag_name,
                old:  old_tag_name,
                new:  new_tag_name
              },
              {
                type: :add_css_class,
                existed_before:  false,
                class: added_css_class
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
end
