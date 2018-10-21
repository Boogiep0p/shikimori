if defined? Bugsnag
  Bugsnag.configure do |config|
    config.api_key = 'efcce15b773498ef22d9cfb3877b8050'

    Shikimori::IGNORED_EXCEPTIONS
      .map { |v| v.constantize rescue NameError }
      .reject { |v| v == NameError }
      .each do |klass|
        config.ignore_classes << klass
      end
  end
end
