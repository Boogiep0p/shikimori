class CollectionTitle
  include Translation
  prepend ActiveCacher.instance

  instance_cache :fancy?

  def initialize klass:, user:, season:, type:, status:, genres:, studios:, publishers:
    @klass = klass
    @user = user

    @statuses = (status || '').split(',')
    @types = (type || '').gsub(/-/, ' ').split(',').select { |v| !v.starts_with? '!' }
    @studios = Array studios
    @publishers = Array publishers
    @genres = Array genres
    @seasons = (season || '').split(',')
  end

  def title
    if fancy?
      fancy_title
    else
      composite_title
    end.first_upcase
  end

  def fancy_title
    if genres.present?
      genres.first.title user: user
    else
      composite_title
    end
  end

  def composite_title
    title = [
      statuses_text || types_text,
      studios_text,
      publishers_text,
      genres_text,
      seasons_text
    ].compact.join(' ')

    if title == Anime.model_name.human && user.nil?
      i18n_i('Best_anime', :other)
    else
      title
    end
  end

private

  attr_reader :klass, :user
  attr_reader :seasons, :types, :statuses, :genres, :studios, :publishers

  def fancy?
    (seasons + types + statuses + genres + studios + publishers).one?
  end

  def statuses_text
    return if statuses.empty?

    statuses
      .map { |status| status_text status }
      .to_sentence
  end

  def status_text status
    klass_key = klass.name.downcase
    type_count_key = types.one? ? 'one_type' : 'many_types'

    i18n_t "status.#{klass_key}.#{type_count_key}.#{status}",
      type: type_text(types.first)
  end

  def types_text
    return klass.model_name.human if types.empty?

    types
      .map { |type| type_text type }
      .to_sentence
  end

  def studios_text
    return if studios.empty?

    list = studios.map(&:name).to_sentence
    "#{i18n_i 'studio', studios.count, :genitive} #{list}"
  end

  def publishers_text
    return if publishers.empty?

    publishers_list = publishers.map(&:name).to_sentence
    "#{i18n_i 'publisher', publishers.count, :genitive} #{publishers_list}"
  end

  def genres_text
    return unless genres.many?

    list = genres
      .map { |genre| UsersHelper.localized_name genre, user }
      .to_sentence
    "#{i18n_i 'genre', genres.count, :genitive} #{list}"
  end

  def seasons_text
    return unless seasons.one?
    "#{AniMangaSeason.title_for seasons.first, klass}"
  end

  def type_text type
    if type.present?
      I18n.t "enumerize.#{klass.name.downcase}.kind.plural.#{type}"
    else
      klass.model_name.human
    end.downcase
  end
end
