require 'spec_helper'

RSpec.describe TestApp::ImportJob do
  describe '.perform' do
    let(:import) { create :import }

    let(:service) { instance_double('TestApp::ImportService') }

    subject { described_class.perform(import.id) }

    before do
      allow(TestApp::ImportService).to receive(:new).with(import.id).and_return(service)
      allow(service).to receive(:call)

      subject
    end

    it do
      expect(service).to have_received(:call)
    end
  end
end
