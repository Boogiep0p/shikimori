class DialogQuery
  pattr_initialize :user, :target_user

  def fetch page, limit
    dynamic_limit = page > 1 ? limit : 3
    dynamic_offset = page > 1 ? limit - 3 : 0

    Message
      .where(kind: MessageType::Private)
      .where(
        "(from_id = :user_id and to_id = :target_user_id) or (from_id = :target_user_id and to_id = :user_id)",
        user_id: user.id, target_user_id: target_user.id)
      .includes(:linked, :from, :to)
      .order(id: :desc)
      .offset(dynamic_limit * (page-1) - dynamic_offset)
      .limit(dynamic_limit + 1)
      .reverse
  end

  def postload page, limit
    dynamic_limit = page > 1 ? limit : 3
    collection = fetch page, limit
    [collection.take(dynamic_limit), collection.size == dynamic_limit+1]
  end

private
  def dynamic page, limit
  end
end
