RSpec.describe Seven::Abilities do
  let(:cls) { Class.new { include Seven::Abilities } }
  let(:rule_proc) { Proc.new { } }

  describe '.warp_proc' do
    it 'should return abilities class' do
      cls = Seven::Abilities.warp_proc(rule_proc)
      expect(cls).to be_a(Class)
      expect(cls.included_modules).to be_include(Seven::Abilities)
      expect(cls.rule_procs).to eql([[nil, nil, rule_proc]])
    end
  end

  describe '.abilities' do
    it 'should add rule proc' do
      expect {
        cls.abilities(&rule_proc)
      }.to change(cls, :rule_procs).to([[nil, nil, rule_proc]])
    end

    it 'should add rule proc with scope' do
      expect {
        cls.abilities(:role, [:admin], &rule_proc)
      }.to change(cls, :rule_procs).to([[:role, [:admin], rule_proc]])
    end

    it 'should not add rule proc if invalid scope' do
      expect {
        expect {
          cls.abilities(:role, &rule_proc)
        }.to raise_error(Seven::ArgsError)
      }.to_not change(cls, :rule_procs)

      expect {
        expect {
          cls.abilities(:role, nil, &rule_proc)
        }.to raise_error(Seven::ArgsError)
      }.to_not change(cls, :rule_procs)
    end
  end

  describe '#abilities' do
    let(:admin_user) { User.new(role: :admin) }
    let(:normal_user) { User.new(role: :normal) }
    let(:lock_topic) { Topic.new(user_id: admin_user.id, is_lock: true) }
    let(:normal_topic) { Topic.new(user_id: normal_user.id, is_lock: false) }

    describe 'use base rule' do
      it 'should return correct abilities' do
        rule_cls = create_base_rule_class

        expect(rule_cls.new(admin_user, normal_topic).abilities).to \
          eql([:read_topics, :create_topic, :edit_topic, :destroy_topic])

        expect(rule_cls.new(normal_user, normal_topic).abilities).to \
          eql([:read_topics, :create_topic, :edit_topic, :destroy_topic])

        admin_user.role = :normal
        expect(rule_cls.new(admin_user, normal_topic).abilities).to \
          eql([:read_topics, :create_topic])
      end

      it 'should return correct abilities when user is nil' do
        rule_cls = create_base_rule_class
        expect(rule_cls.new(nil, normal_topic).abilities).to eql([:read_topics])
      end
    end

    describe 'use scope rule' do
      it 'should return correct abilities' do
        rule_cls = create_role_rule_class

        expect(rule_cls.new(admin_user, normal_topic).abilities.sort).to \
          eql([:read_topics, :create_topic, :edit_topic, :destroy_topic].sort)

        expect(rule_cls.new(admin_user, lock_topic).abilities.sort).to \
          eql([:read_topics, :create_topic].sort)

        expect(rule_cls.new(normal_user, normal_topic).abilities.sort).to \
          eql([:read_topics, :create_topic, :edit_topic, :destroy_topic].sort)

        admin_user.role = :normal
        expect(rule_cls.new(admin_user, normal_topic).abilities.sort).to \
          eql([:read_topics, :create_topic].sort)
      end

      it 'should return correct abilities user is nil' do
        rule_cls = create_role_rule_class
        expect(rule_cls.new(nil, normal_topic).abilities).to eql([:read_topics])
      end
    end
  end
end

