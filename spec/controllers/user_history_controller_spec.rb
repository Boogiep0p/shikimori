describe UserHistoryController do
  let!(:user) { create :user }

  describe '#index' do
    let!(:history) { create :user_history, user: user, target: create(:anime) }
    let(:make_request) { get :index, params: { profile_id: user.to_param } }

    context 'has access to list' do
      subject! { make_request }
      it { expect(response).to have_http_status :success }
    end

    context 'has no access to list' do
      let(:user) { create :user, preferences: create(:user_preferences, list_privacy: :owner) }
      before { sign_out user }
      it { expect { make_request }.to raise_error CanCan::AccessDenied }
    end
  end

  describe '#logs' do
    let!(:user_rate_log) { create :user_rate_log, user: user }
    let(:make_request) { get :logs, params: { profile_id: user.to_param } }

    context 'has access to list' do
      subject! { make_request }
      it { expect(response).to have_http_status :success }
    end

    context 'has no access to list' do
      let(:user) { create :user, preferences: create(:user_preferences, list_privacy: :owner) }
      before { sign_out user }
      it { expect { make_request }.to raise_error CanCan::AccessDenied }
    end
  end

  describe '#reset' do
    let!(:user_history) { create :user_history, user: user, target: entry }
    let(:type) { entry.class.name.downcase }
    let(:make_request) { delete :reset, params: { profile_id: user.to_param, type: type } }

    context 'has no access' do
      let(:entry) { create :anime }
      it { expect { make_request }.to raise_error CanCan::AccessDenied }
    end

    context 'has access' do
      before { sign_in user }

      context 'anime' do
        let(:entry) { create :anime }
        subject! { make_request }

        it do
          expect(user.history).to have(1).item
          expect(user.history.first.action).to eq UserHistoryAction::AnimeHistoryClear
          expect(response).to have_http_status :success
        end
      end

      context 'manga' do
        let(:entry) { create :manga }
        subject! { make_request }

        it do
          expect(user.history).to have(1).item
          expect(user.history.first.action).to eq UserHistoryAction::MangaHistoryClear
          expect(response).to have_http_status :success
        end
      end
    end
  end
end
