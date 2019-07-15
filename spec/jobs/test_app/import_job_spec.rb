require 'spec_helper'

RSpec.describe TestApp::ImportJob do
  describe '.perform' do
    let(:path) { Rails.root.join('public', 'files', 'import', 'some_file') }

    let(:service) { instance_double('TestApp::ImportService') }

    subject { described_class.perform(path) }

    before do
      allow(TestApp::ImportService).to receive(:new).with(path).and_return(service)
      allow(service).to receive(:call)

      subject
    end

    it do
      expect(service).to have_received(:call)
    end
  end
end
