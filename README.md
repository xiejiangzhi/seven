# Seven

Define and verify Permissions.

[![Build Status](https://travis-ci.org/xiejiangzhi/seven.svg?branch=master)](https://travis-ci.org/xiejiangzhi/seven)
[![Gem Version](https://badge.fury.io/rb/sevencan.svg)](https://badge.fury.io/rb/sevencan)

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

### Create your manager

```
$abilities_manager = Seven::Manager.new
```

Use your store(TODO)

```
manager = Seven::Manager.new # save dynamic abilities to memory store
# or
manager = Seven::Manager.new(store: {redis: Redis.current}) # save dynamic abilities to Redis
# or
manager = Seven::Manager.new(store: {activerecord: UserAbility}) # save dynamic abilities to DB 
```

### Define your rules

On Rails, we can save these rules as app/abilities/*_abilities.rb

A simple example

```
# Topic and Topic instances
class TopicAbilities
  include Seven::Abilities

  # it has some instance methods:
  #   current_user: a user instance of nil
  #   target: verify current_user permissions with this target


  # we will define some abilities for any user(user instance or nil) in this block
  abilities do
    can(:read_topic)
    can_manager_topic if target_topic.user_id == current_user.id

    cannot_manager_topic if target_topic.is_lock
  end

  # if current user(current_user isn't nil) and %i{admin editor}.include?(current_user.role)
  # we will define some abilities for the user
  abilities check: :role, in: %i{admin editor} do
    can_manager_topic
  end

  # current_user.role is :reviewer
  abilities check: :role, equal: :reviewer do
    can :review_topic
  end

  # Of course, you also can use your rule.
  # For example, we will give current_user some abilities if our proc doesn't return a false or nil value
  abilities pass: Proc.new { current_user && target.user_id.nil? } do
    can_manager_topic
  end

  # And you can move that proc to a instance method
  abilities pass: :my_filter do
  end

  def can_manager_topic
    can :edit_topic, :destroy_topic
  end

  def cannot_manager_topic
    cannot :edit_topic, :destroy_topic
  end

  def my_filter
    current_user && target.user_id.nil?
  end
end

# Last, we will use TopicAbilities for Topic and all Topic instances
# It will verify permissions use TopicAbilities if that target is a Topic or instance of Topic
$abilities_manager.define_rules(Topic, TopicAbilities)
```

For all objects

```
# for all objects, they're global rules
$abilities_manager.define_rules(Object, YourAbilities)
```

Use a block to define some abilities 

```
manager.define_rules(User) do
  can(:read_user)
  if current_user
    can(:edit_user) if target.id == current_user.id
    can(:destroy_user) if current_user.is_admin?
  end
end
```

Define some dynamic rules(TODO)

```
manager.add_dynamic_rule(user, :edit_user)
manager.list_dynamic_rules(user)
manager.del_dynamic_rules(user, :edit_user)
```

### Verify your abilities

No target

```
manager.define_rules(Object) { can :read_topics }
manager.can?(current_user, :read_topics, nil) # true, target is nil
manager.can?(nil, :read_topics) # true, anyone can read_topics

manager.can?(current_user, :read_user) # false, we didn't define this abilities
manager.can?(current_user, :edit_user) # false

# TODO
manager.add_dynamic_rule(user, :edit_user)
manager.can?(current_user, :edit_user) # true
manager.can?(nil, :edit_user) # true
```

Verify abilities for a class and its instances

```
manager.define_rules(Topic) { can :read_topics }
manager.can?(nil, :read_topics, Topic) # true, for Topic class
manager.can?(nil, :read_topics, Topic.first) # true, for instance of Topic
manager.can?(current_user, :read_topics, Topic.first) # true
manager.can?(current_user, :read_topics) # false
manager.can?(nil, :read_topics) # false, it's target is nil, it isn't a topic

# TODO
manager.add_dynamic_rule(user, :edit_user, User)
manager.can?(current_user, :edit_user, User) # true
manager.can?(current_user, :edit_user, User.first) # true
manager.can?(current_user, :edit_user) # false
manager.can?(nil, :edit_user) # false
```

Define and verify abilities for a instance

```
manager.define_rules(Topic.first) { can :read_topics }
manager.can?(nil, :read_topics, Topic) # false
manager.can?(nil, :read_topics, Topic.first) # true
manager.can?(current_user, :read_topics, Topic.first) # true
manager.can?(current_user, :read_topics, Topic.last) # false
manager.can?(current_user, :read_topics) # false
manager.can?(nil, :read_topics) # false

# TODO
manager.add_dynamic_rule(user, :edit_user, User.first)
manager.can?(current_user, :edit_user, User) # false
manager.can?(current_user, :edit_user, User.first) # true
manager.can?(current_user, :edit_user, User.last) # false
manager.can?(current_user, :edit_user) # false
manager.can?(nil, :edit_user) # false
```


## Rails

### Init your manager

in `config/initializers/seven_abilities.rb`

```
$abilities_manager = Seven::Manager.new
Dir[Rails.root.join('app/abilities/**/*.rb')].each do |file|
  require file
  filename = File.basename(file).split('.').first
  abilities_name = filename.camelize
  resource_name = abilities_name.gsub(/Abilities$/, '')
  $abilities_manager.define_rules(resource_name.constantize, abilities_name.constantize)
end
```

Define some rules in `app/abilities/*.rb`

```
class UserAbilities
  include Seven::Abilities

  # define some rules
end"
```



### ControllerHelpers

We need these methods of controller

* `current_user`: return current user
* `abilities_manager`: return `Seven::Manager` instance
* `ability_check_callback`: call the method after verifying


For example:

```
class ApplicationController < ActionController::Base
  # when you include `Seven::Rails::ControllerHelpers` module, it will do something below
  #   define `can?` instance method and `seven_ability_check` methods for your controller
  #   define `seven_ability_check_filter` instance method, it's callback of before_action for Seven 
  #   define `seven_ability_check` class methods, it will call `before_action :seven_ability_check_filter` and store some your options
  include Seven::Rails::ControllerHelpers

  def abilities_manager
    $abilities_manager
  end

  def ability_check_callback(is_allowed, ability, target)
    # is_allowed: true or false, is_allowed is true when user can access this action
    # ability: ability of this action, like :read_topic
    # target: resource object of this action
    redirect_to root_path notice: 'Permission denied' unless is_allowed
  end
end
```

Verify permissions for default actions, we will get a ability name according to controller name.

Some mapping examples: 

* TopicController#index =>  :read_topics
* TopicController#show =>  :read_topic
* UserController#new =>  :create_user
* UserController#create =>  :create_user
* UserController#edit =>  :edit_user
* UserController#update =>  :edit_user
* UserController#destory =>  :delete_user


```
class TopicController < ApplicationController
  before_action :find_topic

  # if exists @topic, target is @topic, else use the result of proc, use Topic if the proc return nil 
  seven_ability_check [:@topic, Proc.new { nil }, Topic]

  # Seven will automitically checks current_user has read_topics of Topic
  # We have no @topic and proc is nil, the Topic is our target
  def index
  end

  # check current_user can read_topic of @topic
  def show
  end

  private

  def find_topic
    @topic = Topic.find(params[:id])
  end
end
```

Set a customized ability for actions

```
class TopicController < ApplicationController
  before_action :find_topic

  # if exist @topic, target is @topic, else use Topic
  seven_ability_check(
    [:@topic, Topic], # default targets
    my_action1: {ability: :custom_ability}, # check :custom_ability and use default targets
    my_action2: {ability: :custom_ability, target: [:@my_target]} # check :custom_ability and use :@my_target
  )
  # or 
  # seven_ability_check(
  #   index: {ability: :read_my_ability, target: SuperTopic},
  #   my_action1: {ability: :custom_ability1}, 
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

Use a customize resource name, we will get ability according to this suffix

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


Manually check, don't call `ability_check_callback`

```
class TopicController < ApplicationController
  before_action :find_topic
  skip_before_action :seven_ability_check_filter

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

Skip some actions

```
class TopicController < ApplicationController
  before_action :find_topic
  skip_before_filter :seven_ability_check_filter, only: :index

  def index
    if page_no > 1
      ability_check_callback(can?(:read_something, @topic), :read_something, @topic)
    end
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

Write some abilities testing

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

Bug reports and pull requests are welcome on GitHub at https://github.com/xiejiangzhi/seven. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](contributor-covenant.org) code of conduct.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

