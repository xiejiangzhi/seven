RSpec.shared_examples 'store describe' do |store|
  before :each do
    store.clear_all!
  end

  let(:u1) { double('user 1', id: 1) }
  let(:u2) { double('user 2', id: 2) }
  let(:u3) { double('user 3', id: 3) }
  let(:ustr) { double('user str', id: 'asdf') }
  let(:ustr2) { double('user str2', id: 'aaa') }

  describe '#set and #list' do
    it 'allow list a empty user' do
      expect(store.list(u1)).to eql({})
      expect(store.list(ustr)).to eql({})
    end

    it 'should set ability' do
      expect {
        store.set(u1, :read_user, true)
      }.to change { store.list(u1) }.to({read_user: true})
    end

    it 'should over write ability' do
      store.set(u1, :read_user, true)
      expect {
        store.set(u1, :read_user, false)
      }.to change { store.list(u1) }.to({read_user: false})
    end

    it 'should store different user_id' do
      expect {
        store.set(ustr, :read_user, false)
      }.to change { store.list(ustr) }.to({read_user: false})

      expect {
        store.set(ustr2, :read_user, true)
      }.to change { store.list(ustr2) }.to({read_user: true})
      expect(store.list(ustr)).to eql({read_user: false})
    end

    it 'should list ability by different user_id' do
      abs = {read_user: true}
      store.set(u1, :read_user, true)

      allow(u1).to receive(:id).and_return(u1.id.to_s)
      expect(store.list(u1)).to eql(abs)

      allow(u1).to receive(:id).and_return(u1.id.to_s.to_sym)
      expect(store.list(u1)).to eql(abs)
    end

    it 'should store multiple user abilities' do
      store.set(u1, :edit_user, true)
      store.set(u2, :delete_user, true)
      store.set(u3, :custom_user, false)

      expect(store.list(u1)).to eql({edit_user: true})
      expect(store.list(u2)).to eql({delete_user: true})
      expect(store.list(u3)).to eql({custom_user: false})
    end

    it 'should convert ability value to true or false' do
      store.set(u1, :a, 1)
      expect(store.list(u1)).to eql({a: true})
      store.set(u1, :a, 2)
      expect(store.list(u1)).to eql({a: true})
      store.set(u1, :a, 'asdf')
      expect(store.list(u1)).to eql({a: true})
      store.set(u1, :a, 0)
      expect(store.list(u1)).to eql({a: true})
      store.set(u1, :a, nil)
      expect(store.list(u1)).to eql({a: false})
      store.set(u1, :a, false)
      expect(store.list(u1)).to eql({a: false})
    end

    it 'should store abilities with scope' do
      store.set(u1, :a, 1, :s1)
      store.set(u1, :b, 1, :s2)
      store.set(u1, :c, false, :s2)
      store.set(u1, :d, 1)

      store.set(u2, :a, false, :s1)
      store.set(u2, :b, false, :s1)

      store.set(u3, :e, false)

      expect(store.list(u1)).to eql({d: true})
      expect(store.list(u1, :s1)).to eql({a: true, d: true})
      expect(store.list(u1, :s2)).to eql({b: true, c: false, d: true})
      expect(store.list(u1, :invalid_asdf)).to eql({d: true})

      expect(store.list(u2)).to eql({})
      expect(store.list(u2, :s1)).to eql({a: false, b: false})

      expect(store.list(u3)).to eql({e: false})
    end

    it 'should return parent abilities' do
      c = Class.new do
        attr_reader :id
        def initialize(id); @id = id; end
      end

      i1 = c.new 1
      i2 = c.new 2

      store.set(u1, :g, 1)
      store.set(u1, :a, 1, c)
      store.set(u1, :b, 1, c)
      store.set(u1, :a, false, i1)
      store.set(u1, :c, 1, i2)

      expect(store.list(u1)).to eql({g: true})
      expect(store.list(u1, c)).to eql({g: true, a: true, b: true})
      expect(store.list(u1, i1)).to eql({g: true, a: false, b: true})
      expect(store.list(u1, i2)).to eql({g: true, a: true, b: true, c: true})
    end
  end

  describe '#del' do
    it 'should del a ability' do
      store.set(u1, :edit_user, true)
      store.set(u1, :delete_user, true)
      store.set(u2, :edit_user, true)

      store.del(u1, :edit_user)

      expect(store.list(u1)).to eql({delete_user: true})
      expect(store.list(u2)).to eql({edit_user: true})
    end

    it 'should del a ability that belongs to a scope' do
      store.set(u1, :a, true)
      store.set(u1, :b, false)
      store.set(u1, :a, false, :s1)
      store.set(u1, :b, true, :s1)
      store.set(u1, :c, true)
      store.set(u2, :c, true)

      store.del(u1, :a)

      expect(store.list(u1)).to eql({b: false, c: true})
      expect(store.list(u1, :s1)).to eql({a: false, b: true, c: true})
      expect(store.list(u2)).to eql({c: true})

      store.del(u1, :a, :s1)

      expect(store.list(u1)).to eql({b: false, c: true})
      expect(store.list(u1, :s1)).to eql({b: true, c: true})
      expect(store.list(u2)).to eql({c: true})
    end

    it 'should not raise a error if del a invalid user, ability or scope' do
      store.del(u3, :invalid_abiltyxxx)
      store.del(u3, :asdf_invalid, :invalid_scopxyz)
    end
  end

  describe '#clear' do
    it 'should delete user data' do
      store.set(u1, :read_users, false)
      store.set(u1, :read_topics, true)

      store.set(u2, :read_topics, true)

      expect {
        expect {
          store.clear(u1)
        }.to change { store.list(u1) }.to({})
      }.to_not change { store.list(u2) }
    end

    it 'should delete a ability that belongs to a scope' do
      store.set(u1, :a, false)
      store.set(u1, :b, true)

      store.set(u1, :a, true, :s1)
      store.set(u1, :b, true, :s1)

      store.set(u1, :a, false, :s2)
      store.set(u1, :b, false, :s2)

      expect {
        expect {
          expect {
            store.clear(u1, :s1)
          }.to_not change { store.list(u1) }
        }.to_not change { store.list(u1, :s2) }
      }.to change { store.list(u1, :s1) }.to({a: false, b: true})

      expect {
        expect {
        store.clear(u1)
        }.to change { store.list(u1) }.to({})
      }.to_not change { store.list(u1, :s2) }
    end

    it 'should not change anything if give a invalid user or scope' do
      store.set(u1, :a, true)
      store.set(u1, :b, true, :s1)

      expect {
        expect {
          store.clear(u2)
        }.to_not change { store.list(u1) }
      }.to_not change { store.list(u1, :s1) }

      expect {
        expect {
          store.clear(u2, :invalid)
        }.to_not change { store.list(u1) }
      }.to_not change { store.list(u1, :s1) }
    end
  end

  describe '#clear_user_all' do
    it 'should remove all user abilities' do
      store.set(u1, :a, true)
      store.set(u1, :b, true, :s1)
      store.set(u2, :a, true)
      store.set(u2, :b, true, :s1)

      expect {
        expect {
          store.clear_user_all(u1)
        }.to change { store.list(u1).merge(store.list(u1, :s1)) }.to({})
      }.to_not change { store.list(u2).merge(store.list(u2, :s1)) }
    end
  end

  describe '#clear_all' do
    it 'should clear all abilities' do
      store.set(u1, :edit_user, true)
      store.set(u2, :delete_user, true)
      store.set(u3, :custom_user, false)

      store.clear_all!

      expect(store.list(u1)).to eql({})
      expect(store.list(u2)).to eql({})
      expect(store.list(u3)).to eql({})
    end
  end
end
