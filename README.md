# Seven

Permission manage center

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'seven'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install seven

## Usage

New manager

```
manager = Seven.new(store: {redis: Redis.current})
manager = Seven.new(store: {activerecord: UserAbility})
```

Define system rules

```
# all objects
manager.define_rules(Object, [:read_topics])

# Topic and Topic instances
class MyTopicAbilities
  include Seven::Abilities

  def abilities(current_user, target_topic)
    add_rules(:read_topic)
    add_rules(:edit_topic, :destroy_topic) if target_topic.user_id == current_user.id

    # remove user_role rules and abilities rules
    del_rules(:edit_topic, :destroy_topic) if target_topic.is_lock
  end

  # require user.role
  user_role_abilities :admin, :editor do
    add_rules :edit_topic
  end

  user_role_abilities :reviewer do
    add_rules :review_topic
  end
end

manager.define_rules(User, MyUserAbilities)

# with block
manager.define_rules(User) do |current_user, target|
  add_rules(:read_user)
  add_rules(:edit_user) if target.id == current_user.id
  add_rules(:destroy_user) if current_user.is_admin?
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
manager.define_rules(Object, [:read_topics])
manager.can?(user, :read_topics) # true
manager.can?(nil, :read_topics) # true
manager.can?(user, :read_user) # false

manager.can?(user, :edit_user) # false

manager.add_dynamic_rule(user, :edit_user)
manager.can?(user, :edit_user) # true
manager.can?(nil, :edit_user) # true
```

Specify target class

```
manager.define_rules(Topic, [:read_topics])
manager.can?(nil, :read_topics, Topic) # true
manager.can?(nil, :read_topics, Topic.first) # true
manager.can?(user, :read_topics, Topic.first) # true
manager.can?(user, :read_topics) # false
manager.can?(nil, :read_topics) # false

manager.add_dynamic_rule(user, :edit_user, User)
manager.can?(user, :edit_user, User) # true
manager.can?(user, :edit_user, User.first) # true
manager.can?(user, :edit_user) # false
manager.can?(nil, :edit_user) # false
```

Specify instance

```
manager.define_rules(Topic.first, [:read_topics])
manager.can?(nil, :read_topics, Topic) # false
manager.can?(nil, :read_topics, Topic.first) # true
manager.can?(user, :read_topics, Topic.first) # true
manager.can?(user, :read_topics, Topic.last) # false
manager.can?(user, :read_topics) # false
manager.can?(nil, :read_topics) # false

manager.add_dynamic_rule(user, :edit_user, User.first)
manager.can?(user, :edit_user, User) # false
manager.can?(user, :edit_user, User.first) # true
manager.can?(user, :edit_user, User.last) # false
manager.can?(user, :edit_user) # false
manager.can?(nil, :edit_user) # false
```


## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/seven. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](contributor-covenant.org) code of conduct.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

