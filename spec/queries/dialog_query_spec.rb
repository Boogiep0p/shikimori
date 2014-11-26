describe DialogQuery do
  before { Message.antispam = false }

  let(:user) { create :user }
  let(:target_user) { create :user }
  let(:user_3) { create :user }
  let(:query) { DialogQuery.new user, target_user }

  let!(:message_to_1) { create :message, from: target_user, to: user }
  let!(:message_from_1) { create :message, from: user, to: target_user }
  let!(:message_to_2) { create :message, from: user, to: user_3 }

  describe '#fetch' do
    subject(:fetch) { query.fetch 1, 1 }
    it { should eq [message_to_1, message_from_1] }
  end

  describe '#postload' do
    let!(:message_to_2) { create :message, from: target_user, to: user }
    let!(:message_from_2) { create :message, from: user, to: target_user }

    subject(:postload) { query.postload 1, 15 }

    its(:first) { should eq [message_to_1, message_from_1, message_to_2] }
    its(:second) { should be_truthy }
  end
end
