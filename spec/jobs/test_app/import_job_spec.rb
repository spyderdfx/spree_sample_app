require 'spec_helper'

RSpec.describe TestApp::ImportJob, type: :job do
  include ActiveJob::TestHelper

  describe '.perform' do
    let(:import) { instance_double('TestApp::Import', id: 123) }

    let(:service) { instance_double('TestApp::ImportService') }

    subject { described_class.perform_later(import.id) }

    before do
      allow(TestApp::ImportService).to receive(:new).with(import.id).and_return(service)
      allow(service).to receive(:call)

      perform_enqueued_jobs { subject }
    end

    after do
      clear_enqueued_jobs
      clear_performed_jobs
    end

    it 'calls service' do
      expect(service).to have_received(:call)
    end
  end
end
