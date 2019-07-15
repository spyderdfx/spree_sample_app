module Spree
  module Admin
    class ImportsController < Spree::Admin::BaseController
      UPLOAD_PATH = Rails.root.join('public', 'files', 'import').freeze

      def show
      end

      def upload
        uploaded_csv = params[:csv]
        path = UPLOAD_PATH.join(uploaded_csv.original_filename)
        File.open(path, 'wb') do |file|
          file.write(uploaded_csv.read)
        end

        Resque.enqueue(TestApp::ImportJob, path)

        flash[:success] = I18n.t('controllers.admin.imports.success')
        redirect_back fallback_location: root_path
      end
    end
  end
end
