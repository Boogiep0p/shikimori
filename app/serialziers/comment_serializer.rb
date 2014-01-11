class CommentSerializer < ActiveModel::Serializer
  attributes :id, :user_id, :commentable_id, :commentable_type
  attributes :body, :html_body, :created_at, :updated_at
  attributes :offtopic, :review

  has_one :user
end
