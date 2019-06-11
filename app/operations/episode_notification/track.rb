class EpisodeNotification::Track
  method_object %i[
    anime_id!
    episode!
    aired_at
    is_raw
    is_subtitles
    is_fandub
  ]

  def call
    model = find_or_initialize

    if @is_raw || @is_subtitles || @is_fandub
      assign model
      save model
    end

    model
  end

private

  def find_or_initialize
    EpisodeNotification.find_or_initialize_by(
      anime_id: @anime_id,
      episode: @episode
    )
  end

  def assign model
    model.is_raw = true if @is_raw
    model.is_subtitles = true if @is_subtitles
    model.is_fandub = true if @is_fandub

    if model.new_record? && @aired_at.present?
      model.created_at = @aired_at
    end
  end

  def save model
    model.save!
  end
end
