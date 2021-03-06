# frozen_string_literal: true

# views for topics to be shown in sticky topics forum section:
# all of them belong to offtopic forum
class StickyClubView < Dry::Struct
  extend Translation

  attribute :url, Types::Strict::String
  attribute :title, Types::Strict::String
  attribute :description, Types::Strict::String

  CLUB_IDS = {
    faq: { ru: 1_093, en: nil }
  }

  CLUB_IDS.keys.each do |club_name|
    define_singleton_method club_name do |locale|
      club_id = CLUB_IDS[club_name][locale.to_sym]
      next unless club_id

      instance_variable_get(:"@#{club_name}_#{locale}") ||
        instance_variable_set(
          :"@#{club_name}_#{locale}",
          new(
            url: club_url(club_id),
            title: club_name(club_id),
            description: description(club_name, locale)
          )
        )
    end
  end

  private_class_method

  def self.club_url club_id
    Rails.cache.fetch("sticky_club_url_#{club_id}") do
      UrlGenerator.instance.club_url clubs[club_id]
    end
  end

  def self.club_name club_id
    clubs[club_id].name
  end

  def self.description club_name, locale
    i18n_t "#{club_name}.description", locale: locale
  end

  def self.clubs
    @clubs ||= Hash.new do |cache, club_id|
      cache[club_id] = Club.find club_id
    end
  end
end
