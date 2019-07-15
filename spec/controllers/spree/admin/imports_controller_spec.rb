require 'spec_helper'

RSpec.describe Spree::Admin::ImportsController, type: :controller do
  describe '#show' do
    let(:request) { get :show }

    context 'when admin' do
      let(:user) do
        create(:user).tap { |user| user.spree_roles << Spree::Role.find_or_create_by(name: 'admin') }
      end

      before do
        allow(controller).to receive(:spree_current_user).and_return(user)
        login_as(user, scope: :spree_user)

        request
      end

      it 'renders show' do
        expect(response.status).to eq 200
        expect(response).to render_template(:show)
      end
    end

    context 'when non admin' do
      let(:user) { create(:user) }

      before do
        allow(controller).to receive(:spree_current_user).and_return(user)
        login_as(user, scope: :spree_user)

        request
      end

      it 'redirects to login page' do
        expect(response.status).to eq 302
      end
    end

    context 'when not authorized' do
      before { request }

      it 'redirects to login page' do
        expect(response.status).to eq 302
      end
    end
  end

  describe '#upload' do
    let(:file) { fixture_file_upload(Rails.root.join('spec/fixtures/sample.csv')) }
    let(:path) { Rails.root.join('public', 'files', 'import', 'sample.csv') }

    let(:request) { post :upload, params: {csv: file} }

    before { allow(Resque).to receive(:enqueue) }

    context 'when admin' do
      let(:user) do
        create(:user).tap { |user| user.spree_roles << Spree::Role.find_or_create_by(name: 'admin') }
      end

      before do
        allow(controller).to receive(:spree_current_user).and_return(user)
        login_as(user, scope: :spree_user)

        request
      end

      it 'uploads file, enqueues backgroud job, and redirects back' do
        expect(File.open(path).first).to start_with ';name;description;price;' # checking some csv headers
        expect(Resque).to have_received(:enqueue).with(TestApp::ImportJob, path)
        expect(response.request.flash[:success]).to eq I18n.t('controllers.admin.imports.success')
        expect(response.status).to eq 302
      end
    end

    context 'when non admin' do
      let(:user) { create(:user) }

      before do
        allow(controller).to receive(:spree_current_user).and_return(user)
        login_as(user, scope: :spree_user)

        request
      end

      it 'redirects to login page' do
        expect(Resque).not_to receive(:enqueue)
        expect(response.status).to eq 302
      end
    end

    context 'when not authorized' do
      before { request }

      it 'redirects to login page' do
        expect(Resque).not_to receive(:enqueue)
        expect(response.status).to eq 302
      end
    end
  end
end
