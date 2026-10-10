# Check config/app.yml at boot. An invalid name or theme fails here, including
# during the production image build (assets:precompile boots the app), rather
# than going live with a broken look. See AppConfig.
Rails.application.config.after_initialize { AppConfig.current }
