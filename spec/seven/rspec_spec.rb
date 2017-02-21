require 'seven/rspec'

RSpec.describe 'seven/rspec test' do
  let(:user) { double('user', id: 1, role: :normal) }
  let(:user2) { double('user2', id: 2, role: :normal) }
  let(:topic) { double('topic', id: 1, user_id: 2) }

  let(:described_class) { create_base_rule_class }

  it 'should not raise error if abilities correct' do
    expect([nil, topic]).to abilities_eql([:read_topics])
    expect([user, topic]).to abilities_eql([:read_topics, :create_topic])
    expect([user, topic]).to abilities_eql([:create_topic, :read_topics])
    expect([user2, topic]).to abilities_eql([
      :read_topics, :create_topic, :edit_topic, :destroy_topic
    ])
  end

  it 'should raise error if abilities error' do
    expect {
      expect([nil, topic]).to abilities_eql([:read_topics, :other])
    }.to raise_error(RSpec::Expectations::ExpectationNotMetError)

    expect {
      expect([user, topic]).to abilities_eql([:read_topics, :create_xx])
    }.to raise_error(RSpec::Expectations::ExpectationNotMetError)
  end
end

