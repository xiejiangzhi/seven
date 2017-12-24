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
  end

  describe '#clear' do
    it 'should delete user data' do
      store.set(u1, :read_users, false)
      expect {
        store.clear(u1)
      }.to change { store.list(u1) }.to({})
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
