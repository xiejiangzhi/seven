require 'rspec'

# expect([current_user, target]).to abilities_eql([:a, :b])

RSpec::Matchers.define :abilities_eql do |expect_abilities|
  match do |abilities_class_args|
    abilities_instance = described_class.new(*abilities_class_args)
    abilities_instance.abilities.uniq.sort == expect_abilities.sort
  end

  failure_message do |abilities_class_args|
    args_string = abilities_class_args.map(&:inspect).join(', ')
    abilities_instance = described_class.new(*abilities_class_args)
    abilities = abilities_instance.abilities.uniq.sort

    "Expected abilities #{abilities} == #{expect_abilities.sort} But not\n" +
    "Abilities generator #{described_class}.new(#{args_string}).abilities"
  end
end


