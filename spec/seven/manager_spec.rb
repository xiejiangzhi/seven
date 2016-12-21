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
      it 'should add rules with warpped proc' do
        p = Proc.new { 'hello' }
        cls = Class.new { include Seven::Abilities }

        expect(Seven::Abilities).to receive(:warp_proc).with(p).and_return(cls)
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
  end

  describe '#add_dynamic_rule' do
  end

  describe '#del_dynamic_rule' do
  end

  describe '#list_dynamic_rules' do
  end
end

