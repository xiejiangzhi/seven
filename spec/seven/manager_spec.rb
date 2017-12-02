RSpec.describe Seven::Manager do
  let(:user1) { User.new(role: :admin) }
  let(:user2) { User.new(role: :normal) }
  let(:topic1) { Topic.new(user_id: user1.id, is_lock: false) }
  let(:topic2) { TOpic.new(user_id: user2.id, is_lock: true) }
  let(:manager) { Seven::Manager.new }

  describe '#define_rules' do
    describe 'with rule class' do
      it 'should add rule class' do
        cls = Class.new { include Seven::Abilities }

        manager.define_rules(Topic, cls)
        expect(manager.rules).to eql([[Topic, cls]])
      end

      it 'should raise error if rule class is invalid' do
        cls = Class.new
        expect {
          manager.define_rules(Topic, cls)
        }.to raise_error(Seven::ArgsError)

        expect(manager.rules).to eql([])
      end
    end

    describe 'with proc' do
      it 'should add rules with wrapped proc' do
        p = Proc.new { 'hello' }
        cls = Class.new { include Seven::Abilities }

        expect(Seven::Abilities).to receive(:wrap_proc).with(p).and_return(cls)
        manager.define_rules(User, &p)
        expect(manager.rules).to eql([[User, cls]])
      end
    end

    it 'should raise error if not rule_class and rule_proc' do
      expect {
        manager.define_rules(Topic)
      }.to raise_error(Seven::ArgsError)
      expect(manager.rules).to eql([])
    end
  end

  describe '#can?' do
    let(:user) { user1 }

    before :each do
      manager.define_rules(Object) { can :read_home }
      manager.define_rules(Topic) { can :read_topic }
      manager.define_rules(ChildTopic) { can :read_child_topic }
      manager.define_rules(User) { can :read_user }
      manager.define_rules('Other') { can :read_something }
    end

    it 'should new rule class with user and target' do
      rule_cls = manager.rules.find {|m, rc| m == Topic }.last
      rule_instance = double(abilities: [])

      expect(rule_cls).to receive(:new).with(user, Topic).and_return(rule_instance)
      manager.can?(user, :read_home, Topic)

      expect(rule_cls).to receive(:new).with(123, Topic).and_return(rule_instance)
      manager.can?(123, :read_home, Topic)

      rule_cls = manager.rules.find {|m, rc| m == Object }.last
      expect(rule_cls).to receive(:new).with(123, nil).and_return(rule_instance)
      manager.can?(123, :read_home)
    end

    it 'should can read_home' do
      expect(manager.can?(user, :read_home)).to eql(true)
      expect(manager.can?(user, :read_home, nil)).to eql(true)
      expect(manager.can?(user, :read_home, 'hello')).to eql(true)
    end

    it 'should can read_topic if target eql topic' do
      expect(manager.can?(user, :read_topic, Topic)).to eql(true)
      expect(manager.can?(user, :read_topic, User)).to eql(false)
      expect(manager.can?(user, :read_topic, ChildTopic)).to eql(false)
      expect(manager.can?(user, :read_child_topic, Topic)).to eql(false)
      expect(manager.can?(user, :read_child_topic, ChildTopic)).to eql(true)
    end

    it 'should support instance match' do
      expect(manager.can?(user, :read_topic, topic1)).to eql(true)
      expect(manager.can?(user, :read_topic, Topic.new)).to eql(true)
      expect(manager.can?(user, :read_topic, ChildTopic.new)).to eql(false)
      expect(manager.can?(user, :read_child_topic, ChildTopic)).to eql(true)
    end
  end

  describe '#add_dynamic_rule' do
  end

  describe '#del_dynamic_rule' do
  end

  describe '#list_dynamic_rules' do
  end
end

