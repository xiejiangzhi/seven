require 'redis'

RSpec.describe Seven::RedisStore do
  let(:redis) { Redis.current }
  let(:store) { Seven::RedisStore.new(redis: Redis.current) }

  include_examples 'store describe', Seven::RedisStore.new(redis: Redis.current)

  describe '#clear_all!' do
    let(:u1) { double('user', id: 1) }

    before :each do
      redis.flushdb
    end

    it 'should clear other keys' do
      redis.set('asdf', 123)
      redis.set('seven_abilities', 321)
      store.set(u1, :read_user, true)

      expect {
        store.clear_all!
      }.to change { redis.keys.sort }.to(['asdf', 'seven_abilities'].sort)
    end
  end
end

