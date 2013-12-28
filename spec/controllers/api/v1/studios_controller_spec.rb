require 'spec_helper'

describe Api::V1::StudiosController do
  describe :show do
    let!(:studio) { create :studio }
    before { get :index }

    it { should respond_with :success }
    it { should respond_with_content_type :json }
  end
end
