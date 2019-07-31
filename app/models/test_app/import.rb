module TestApp
  class Import < ActiveRecord::Base
    attachment_options = {}

    if Rails.env.production? || Rails.env.test?
      attachment_options.merge!(storage: :s3,
                                s3_region: ENV.fetch('S3_REGION'),
                                s3_credentials:
                                  {
                                    bucket: ENV.fetch('S3_BUCKET'),
                                    access_key_id: ENV.fetch('S3_ACCESS_KEY_ID'),
                                    secret_access_key: ENV.fetch('S3_SECRET_ACCESS_KEY')
                                  }
                                )
    end

    has_attached_file :file, attachment_options

    validates_attachment :file, content_type: {content_type: ['text/csv', 'text/plain']}
  end
end
