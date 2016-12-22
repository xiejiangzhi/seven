RSpec.describe Seven::Rails::ControllerHelpers do
  let(:my_controller) do
    Class.new(Support::AppController) do
      attr_accessor :topic

      def self.name
        'TopicsController'
      end

      def initialize
        @topic = Topic.new(user_id: 1)
      end
    end
  end

  describe '#can?' do
    let(:ctrl) { my_controller.new }

    it 'should proxy manager#can?' do
      expect(ctrl.abilities_manager).to \
        receive(:can?).with(ctrl.current_user, :read_topic, ctrl.topic)
      ctrl.can?(:read_topic, ctrl.topic)

      expect(ctrl.abilities_manager).to \
        receive(:can?).with(ctrl.current_user, :read_topic, nil)
      ctrl.can?(:read_topic)
    end
  end

  describe '.seven_ability_check' do
    describe 'initialize' do
      it 'should create filter by before_action' do
        expect(my_controller).to receive(:before_action).with(:seven_ability_check_filter)

        expect {
          my_controller.seven_ability_check [:@topic, Topic]
        }.to change(my_controller, :seven_ability_checker).to({
          index: {ability: :read_topics, target: [:@topic, Topic]},
          show: {ability: :read_topic, target: [:@topic, Topic]},
          new: {ability: :create_topic, target: [:@topic, Topic]},
          edit: {ability: :edit_topic, target: [:@topic, Topic]},
          create: {ability: :create_topic, target: [:@topic, Topic]},
          update: {ability: :edit_topic, target: [:@topic, Topic]},
          destroy: {ability: :delete_topic, target: [:@topic, Topic]}
        })
      end

      it 'should support default + custom checker' do
        expect(my_controller).to receive(:before_action).with(:seven_ability_check_filter)

        expect {
          my_controller.seven_ability_check(
            [:@topic, Topic],
            index: {ability: :read_xyz, target: [1, 2, 3]},
            other: {ability: :read_other, target: [3, 4]}
          )
        }.to change(my_controller, :seven_ability_checker).to({
          index: {ability: :read_xyz, target: [1, 2, 3]},
          show: {ability: :read_topic, target: [:@topic, Topic]},
          new: {ability: :create_topic, target: [:@topic, Topic]},
          edit: {ability: :edit_topic, target: [:@topic, Topic]},
          create: {ability: :create_topic, target: [:@topic, Topic]},
          update: {ability: :edit_topic, target: [:@topic, Topic]},
          destroy: {ability: :delete_topic, target: [:@topic, Topic]},
          other: {ability: :read_other, target: [3, 4]}
        })
      end

      it 'should support custom only checker' do
        expect(my_controller).to receive(:before_action).with(:seven_ability_check_filter)

        expect {
          my_controller.seven_ability_check(
            index: {ability: :read_xyz, target: [1, 2, 3]},
            other: {ability: :read_other, target: [3, 4]}
          )
        }.to change(my_controller, :seven_ability_checker).to({
          index: {ability: :read_xyz, target: [1, 2, 3]},
          other: {ability: :read_other, target: [3, 4]}
        })
      end

      it 'should support custom resource name' do
        expect(my_controller).to receive(:before_action).with(:seven_ability_check_filter)

        expect {
          my_controller.seven_ability_check(
            [:@topic, Topic],
            {
              index: {ability: :read_xyz, target: [1, 2, 3]},
              other: {ability: :read_other, target: [3, 4]}
            },
            resource_name: :comments
          )
        }.to change(my_controller, :seven_ability_checker).to({
          index: {ability: :read_xyz, target: [1, 2, 3]},
          show: {ability: :read_comment, target: [:@topic, Topic]},
          new: {ability: :create_comment, target: [:@topic, Topic]},
          edit: {ability: :edit_comment, target: [:@topic, Topic]},
          create: {ability: :create_comment, target: [:@topic, Topic]},
          update: {ability: :edit_comment, target: [:@topic, Topic]},
          destroy: {ability: :delete_comment, target: [:@topic, Topic]},
          other: {ability: :read_other, target: [3, 4]}
        })
      end
    end

    describe '#seven_ability_check_filter' do
      let(:ctrl) { my_controller.new }
      let(:abilities_manager) { Seven::Manager.new }

      before :each do
        my_controller.seven_ability_check(
          [:@topic, Topic],
          index: {ability: :read_xyz, target: [:@topic, Topic]},
          other: {ability: :read_other, target: []},
          proc_target: {ability: :read_proc, target: [Proc.new { 'proc' }]}
        )
        ctrl.abilities_manager = abilities_manager
      end

      it 'should check ability and run callback' do
        expect(abilities_manager).to receive(:can?) \
          .with(ctrl.current_user, :read_xyz, ctrl.topic).and_return(true)
        expect(ctrl).to receive(:ability_check_callback).with(true, :read_xyz, ctrl.topic)
        ctrl.run(:topics, :index)

        expect(abilities_manager).to receive(:can?) \
          .with(ctrl.current_user, :read_topic, ctrl.topic).and_return(false)
        expect(ctrl).to receive(:ability_check_callback).with(false, :read_topic, ctrl.topic)
        ctrl.run(:topics, :show)

        expect(abilities_manager).to receive(:can?) \
          .with(ctrl.current_user, :read_other, nil).and_return(false)
        expect(ctrl).to receive(:ability_check_callback).with(false, :read_other, nil)
        ctrl.run(:topics, :other)


        expect(abilities_manager).to receive(:can?) \
          .with(ctrl.current_user, :read_xyz, Topic).and_return(false)
        expect(ctrl).to receive(:ability_check_callback).with(false, :read_xyz, Topic)
        ctrl.topic = nil
        ctrl.run(:topics, :index)
      end

      it 'should check new ability if action ability change' do
        expect(abilities_manager).to receive(:can?) \
          .with(ctrl.current_user, :create_topic, nil).and_return(false)
        expect(ctrl).to receive(:ability_check_callback).with(false, :create_topic, nil)
        my_controller.seven_ability_checker[:other][:ability] = :create_topic
        ctrl.run(:topics, :other)
      end

      it 'should call calback with false when not found action checker' do
        expect(abilities_manager).to_not receive(:can?)
        expect(ctrl).to receive(:ability_check_callback).with(false, nil, nil)
        ctrl.run(:topics, :other_action)
      end

      it 'should support proc target' do
        expect(abilities_manager).to receive(:can?) \
          .with(ctrl.current_user, :read_proc, 'proc').and_return(false)
        expect(ctrl).to receive(:ability_check_callback).with(false, :read_proc, 'proc')
        ctrl.run(:topics, :proc_target)
      end
    end
  end
end

