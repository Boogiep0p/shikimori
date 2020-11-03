class Api::V1::CharactersController < Api::V1Controller
  before_action :fetch_resource, except: [:search]

  # AUTO GENERATED LINE: REMOVE THIS TO PREVENT REGENARATING
  api :GET, '/characters/:id', 'Show a character'
  def show
    respond_with @resource,
      serializer: CharacterProfileSerializer,
      scope: view_context
  end

  api :GET, '/characters/search', 'Search characters'
  param :search, String, required: false
  def search
    @collection = Autocomplete::Character.call(
      scope: Character.all,
      phrase: params[:search] || params[:q]
    )
    respond_with @collection, each_serializer: CharacterSerializer
  end

private

  def fetch_resource
    @resource = Character.find(
      CopyrightedIds.instance.restore_id(params[:id])
    ).decorate
  end
end
