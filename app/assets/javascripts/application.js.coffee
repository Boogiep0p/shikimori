#= require pages/p-users-index
#= require pages/p-animes
#= require pages/p-animes_collection-index
#= require pages/p-recommendations-index

$ ->
  $(document).trigger 'page:load', true
  if IS_LOGGED_IN && !window.faye_loader
    window.faye_loader = new FayeLoader()
    faye_loader.apply()
  $('.b-comment .appear-marker').appear()

  $.form_navigate
    size: 250
    message: "Вы написали и не сохранили какой-то комментарий! Уверены, что хотите покинуть страницу?"

$(document).on 'page:restore', (e, is_dom_content_loaded) ->
  process_current_dom()

$(document).on 'page:load', (e, is_dom_content_loaded) ->
  unless is_dom_content_loaded
    turbolinks_compatibility()

  # отображение flash сообщений от рельс
  $('p.flash-notice').each (k, v) ->
    $.flash notice: v.innerHTML if v.innerHTML.length

  $('p.flash-alert').each (k, v) ->
    $.flash alert: v.innerHTML if v.innerHTML.length

  process_current_dom()

$(document).on 'page:fetch', ->
  $ajax = $('.ajax')
  (if $ajax.length then $ajax else $('.l-content')).css opacity: 0.3

$(document).on 'page:restore', ->
  turbolinks_compatibility()
  $('.ajax, .l-content').css opacity: 1

# для совместимости с турболинками
turbolinks_compatibility = ->
  $('#fancybox-wrap').remove()
  $.fancybox.init()

# обработка элементов страницы (инициализация галерей, шрифтов, ссылок)
@process_current_dom = (root = document.body) ->
  # нормализуем ширину всех огромных картинок
  $('img.check-width', root).normalize_image
    class: 'check-width'
    fancybox: $.galleryOptions

  # стена картинок
  $('.wall', root).shiki_wall()
  #$('.b-shiki_editor.unprocessed', root).shiki_editor()
  $('.b-comment.unprocessed', root).shiki_comment()
  $('.b-topic.unprocessed', root).shiki_topic()

  # то, что должно превратиться в ссылки
  $('.linkeable', root).wrap ->
    $this = $(@)
    $this.removeClass('linkeable').addClass 'linkeable-processed'
    "<a href='#{$this.data 'href'}' title='#{$this.data("title") || $this.html()}' />"

  # блоки, загружаемые аяксом
  $('.postloaded[data-href]', root).each ->
    $this = $(@)
    return unless $this.is(':visible')
    $this.load $this.data('href'), ->
      $this.removeClass('postloaded')
      process_current_dom $this

    $this.attr 'data-href', null

  # инициализация подгружаемых тултипов
  $('.anime-tooltip', root)
    .tooltip(ANIME_TOOLTIP_OPTIONS)
    .removeClass('anime-tooltip')
  $('.bubbled', root)
    .addClass('bubbled-processed')
    .removeClass('bubbled')
    .tooltip $.extend(
      offset: [
        -35
        10
      ]
    , tooltip_options)

  $('.b-video.unprocessed', root)
    .removeClass('unprocessed')
    .on 'click', (e) ->
      # если это спан, то мы жмём на кнопочки
      return if in_new_tab(e) || $(e.target).tagName() == 'span'
      unless $(@).data('fancybox')
        $(@)
          .fancybox(if $(@).hasClass('vk') then $.vkOptions else $.youtubeOptions)
          .trigger('click')
        false

  $('.b-image.unprocessed img', root)
    .normalize_image
      class: 'unprocessed'
      append_marker: true
      fancybox: $.galleryOptions

  # сворачиваение всех нужных блоков "свернуть"
  _.each ($.cookie('collapses') || '').replace(/;$/, '').split(';'), (v, k) ->
    $("#collapse-#{v}", root).trigger 'click', true
