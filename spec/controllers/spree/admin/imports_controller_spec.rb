require 'spec_helper'

RSpec.describe Spree::Admin::ImportsController, type: :controller do
  include ActiveJob::TestHelper

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

    let(:request) { post :upload, params: {import: {file: file}} }

    before do
      Aws.config[:s3] = {
        stub_responses: {
          list_buckets: {
            buckets: [name: 'test']
          },
          list_objects: {
            contents: [{key: 'test'}]
          },
          get_object: {
            body: File.read(File.join(Rails.root, 'spec', 'fixtures', 'sample.csv'))
          }
        }
      }
    end

    after do
      Aws.config[:s3] = {}
      Thread.current[:paperclip_s3_instances] = {}

      clear_enqueued_jobs
      clear_performed_jobs
    end

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
        expect(Paperclip.io_adapters.for(TestApp::Import.last.file).read.split("\r\n").first).
          to start_with ';name;description;price;' # checking some csv headers
        expect(ActiveJob::Base.queue_adapter.enqueued_jobs.size).to eq 1 # job enqueued
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
        expect(ActiveJob::Base.queue_adapter.enqueued_jobs.size).to eq 0 # job not enqueued
        expect(response.status).to eq 302
      end
    end

    context 'when not authorized' do
      before { request }

      it 'redirects to login page' do
        expect(ActiveJob::Base.queue_adapter.enqueued_jobs.size).to eq 0 # job not enqueued
        expect(response.status).to eq 302
      end
    end
  end
end
