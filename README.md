# Seven

Permission manage center

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'sevencan'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install sevencan

## Usage

New manager

```
manager = Seven::Manager.new # save dynamic abilities to memory store
manager = Seven::Manager.new(store: {redis: Redis.current}) # redis store
manager = Seven::Manager.new(store: {activerecord: UserAbility}) # db store
```

Define system rules

```
# all objects, global rules
manager.define_rules(Object) do
  can :read_home, :read_topics
end

# Topic and Topic instances
class MyTopicAbilities
  include Seven::Abilities

  # Instance methods:
  #   current_user:
  #   target:
  abilities do
    can(:read_topic)
    can_manager_topic if target_topic.user_id == current_user.id

    cannot_manager_topic if target_topic.is_lock
  end

  # if [:admin, :editor].include?(current_user.role)
  abilities :role, [:admin, :editor] do
    can_manager_topic
  end

  abilities :role, [:reviewer] do
    can :review_topic
  end


  def can_manager_topic
    can :edit_topic, :destroy_topic
  end

  def cannot_manager_topic
    cannot :edit_topic, :destroy_topic
  end
end

manager.define_rules(Topic, MyTopicAbilities)

# with block
manager.define_rules(User) do
  can(:read_user)
  can(:edit_user) if target.id == current_user.id
  can(:destroy_user) if current_user.is_admin?
end
```

Manage dynamic rules

```
manager.add_dynamic_rule(user, :edit_user)
manager.list_dynamic_rules(user)
manager.del_dynamic_rules(user, :edit_user)
```

Check abilities

Target is nil

```
manager.define_rules(Object) { can :read_topics }
manager.can?(current_user, :read_topics) # true
manager.can?(nil, :read_topics) # true
manager.can?(current_user, :read_user) # false

manager.can?(current_user, :edit_user) # false

manager.add_dynamic_rule(user, :edit_user)
manager.can?(current_user, :edit_user) # true
manager.can?(nil, :edit_user) # true
```

Specify target class

```
manager.define_rules(Topic) { can :read_topics }
manager.can?(nil, :read_topics, Topic) # true
manager.can?(nil, :read_topics, Topic.first) # true
manager.can?(current_user, :read_topics, Topic.first) # true
manager.can?(current_user, :read_topics) # false
manager.can?(nil, :read_topics) # false

manager.add_dynamic_rule(user, :edit_user, User)
manager.can?(current_user, :edit_user, User) # true
manager.can?(current_user, :edit_user, User.first) # true
manager.can?(current_user, :edit_user) # false
manager.can?(nil, :edit_user) # false
```

Specify instance

```
manager.define_rules(Topic.first) { can :read_topics }
manager.can?(nil, :read_topics, Topic) # false
manager.can?(nil, :read_topics, Topic.first) # true
manager.can?(current_user, :read_topics, Topic.first) # true
manager.can?(current_user, :read_topics, Topic.last) # false
manager.can?(current_user, :read_topics) # false
manager.can?(nil, :read_topics) # false

manager.add_dynamic_rule(user, :edit_user, User.first)
manager.can?(current_user, :edit_user, User) # false
manager.can?(current_user, :edit_user, User.first) # true
manager.can?(current_user, :edit_user, User.last) # false
manager.can?(current_user, :edit_user) # false
manager.can?(nil, :edit_user) # false
```


## Rails


### Init manager

in `config/initializers/seven_abilities.rb`

```
$abilities_manager = Seven::Manager.new
Dir[Rails.root.join('app/abilities/**/*.rb')].each {|file| require file }
```

Define rules in `app/abilities/*.rb`

```
class UserAbilities
  include Seven::Abilities

  $abilities_manager.define_rules(User, self)

  # define rules
end"
```

### Require methods

* `current_user`: return current user
* `abilities_manager`: return `Seven::Manager` instance
* `ability_check_callback`: call the method after check


### ControllerHelpers

```
class ApplicationController < ActionController::Base
  # define `can?` method and `seven_ability_check` methods
  # define `seven_ability_check_filter` method
  # `seven_ability_check` call `before_action :seven_ability_check_filter`
  include Seven::Rails::ControllerHelpers

  def abilities_manager
    $my_abilities_manager
  end

  def ability_check_callback(allowed, ability, target)
    # allowed: true or false, allowed is true when can access
    # ability: checked ability, like :read_topic
    # target: checked target object
  end
end
```

Default actions

```
class TopicController < ApplicationController
  before_action :find_topic

  # if exist @topic, target is @topic, else use Proc result or Topic
  seven_ability_check [:@topic, Proc.new { fetch_check_target }, Topic]

  # auto check current_user allow read_topics of Topic
  def index
  end

  # auto check current_user allow read_topic of @topic
  def show
  end

  # Other actions:
  #  new: create_topic of Topic
  #  create: create_topic of Topic
  #  edit: edit_topic of @topic
  #  update: edit_topic of @topic
  #  destory: delete_topic of @topic


  private

  def find_topic
    @topic = Topic.find(params[:id])
  end
end
```

Custom require ability for actions

```
class TopicController < ApplicationController
  before_action :find_topic

  # if exist @topic, target is @topic, else use Topic
  seven_ability_check(
    [:@topic, Topic], # default targets
    my_action1: {ability: :custom_ability}, # use default targets
    my_action2: {ability: :custom_ability, target: [:@my_target]}
  )
  # or 
  # seven_ability_check(
  #   index: {ability: read_my_ability, target: SuperTopic},
  #   my_action1: {ability: :custom_ability1}, # use default targets
  #   my_action2: {ability: :custom_ability2, target: [:@my_target]}
  # )

  def index
  end

  def my_action1
  end

  def my_action2
  end


  private

  def find_topic
    @topic = Topic.find(params[:id])
  end
end
```

Custom resource name

```
class TopicController < ApplicationController
  before_action :find_topic

  seven_ability_check [:@topic, Topic], nil, resource_name: :comment

  # auto check current_user allow read_comments of Topic
  def index
  end

  # auto check current_user allow read_comment of @topic
  def show
  end

  # Other actions:
  #  new: create_comment of Topic
  #  create: create_comment of Topic
  #  edit: edit_comment of @topic
  #  update: edit_comment of @topic
  #  destory: delete_comment of @topic


  private

  def find_topic
    @topic = Topic.find(params[:id])
  end
end
```


Manual check, cannot call `ability_check_callback`

```
class TopicController < ApplicationController
  before_action :find_topic

  def my_action1
    raise 'no permission' unless can?(:read_something, @topic)
    # my codes
  end


  private

  def find_topic
    @topic = Topic.find(params[:id])
  end
end
```

## RSpec Testing

in `spec/rails_helper.rb` or `spec/spec_helper.rb`

```
require 'seven/rspec'
```

Write abilities testing

```
RSpec.describe UserAbilities do
  it 'should can read topic' do
    # expect([current_user, target]).to abilities_eql([:read_topic])
    expect([user, topic]).to abilities_eql([:read_topic])
  end

  it 'should can manager topic' do
    expect([admin_user, topic]).to abilities_eql([:read_topic, :edit_topic, :destroy_topic])
  end
end
```


## TODO

* [x] Rails Helpers
* [ ] Dynamic rule


## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/seven. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](contributor-covenant.org) code of conduct.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

