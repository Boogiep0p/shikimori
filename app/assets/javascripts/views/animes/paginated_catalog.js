import Turbolinks from 'turbolinks';
import { flash } from 'shiki-utils';

import UserRatesTracker from 'services/user_rates/tracker';
import ajaxCacher from 'services/ajax_cacher';

import DynamicParser from 'dynamic_elements/_parser';
import CatalogFilters from 'views/animes/catalog_filters';

import inNewTab from 'helpers/in_new_tab';

export default class PaginatedCatalog {
  constructor(basePath) {
    this.$content = $('.l-content');
    this.$pagination = $('.pagination');

    this.$linkCurrent = this.$pagination.find('.link-current');
    this.$linkNext = this.$pagination.find('.link-next');
    this.$linkPrev = this.$pagination.find('.link-prev');
    this.$linkTotal = this.$pagination.find('.link-total');
    this.$linkTitle = this.$pagination.find('.link-title');

    if (this.$linkNext.hasClass('disabled') && this.$linkPrev.hasClass('disabled')) {
      this.$pagination.hide();
    }

    this.pageChange = {};

    this.$content.on(
      'postloader:before',
      (_e, $content, $data) => this._onPageLoadByScroll($content, $data)
    );
    this.$pagination
      .on('click', '.link', e => this._onPaginationLinkClick(e))
      .on('click', '.no-hover', e => this._onPaginationPageSelect(e));

    this.filters = new CatalogFilters(
      basePath,
      window.location.href,
      this.load.bind(this)
    );
  }

  load(url) {
    window.history.pushState({ turbolinks: true, url }, '', url);

    this.filters.parse(url);
    this._fetch(url);
  }

  // events
  _onPaginationLinkClick(e) {
    if (inNewTab(e)) { return; }

    e.preventDefault();

    const $link = $(e.target);
    if ($link.hasClass('disabled')) { return; }

    if ($(window).scrollTop() > 400) {
      $.scrollTo('.head');
    }

    this.load($link.attr('href'));
  }

  _onPaginationPageSelect({ currentTarget }) {
    const $link = $(currentTarget).find('.link-current');

    if ($link.has('input').length) { return; }

    this.pageChange.priorValue = parseInt($link.html());
    this.pageChange.maxValue = parseInt(this.$linkTotal.html());
    $link
      .addClass('active')
      .html(
        `<input type='number' min='1' max='${this.pageChange.maxValue}' value='${this.pageChange.priorValue}' />`
      );

    this.pageChange.$input = $link
      .children()
      .focus()
      .on('blur', () => this._changePage(false))
      .on('keydown', ({ keyCode }) => {
        if (keyCode === 27) {
          this._changePage(true);
        }
      })
      .on('keypress', ({ keyCode }) => {
        if (keyCode === 13) {
          this._changePage(false);
        }
      });
  }

  _onPageLoadByScroll($content, data) {
    const pages = this.$linkCurrent.html().split('-').map(parseInt);
    const currentPage = data.page;

    pages[1] = currentPage;

    const isLastPage = currentPage === data.pages_count;

    this.$linkCurrent.html(pages.join('-'));
    this.$linkTitle.html(this.$linkTitle.data('text'));
    this.$linkTotal.html(data.pages_count);

    this.$linkNext.attr(
      'href',
      isLastPage ? null : this.filters.compile(currentPage + 1)
    );
    this.$linkNext.toggleClass('disabled', isLastPage);

    // this.$content.process(data.JS_EXPORTS)
  }

  // private methods
  _changePage(isRollback) {
    const page = parseInt(this.pageChange.$input.val()) || 1;

    this.$linkCurrent.removeClass('active');

    if (isRollback || (page === this.pageChange.priorValue)) {
      this.$linkCurrent.html(this.pageChange.priorValue);
    } else {
      this.$linkCurrent.html(page);
      this.load(this.filters.compile(page));
    }

    this.pageChange.$input = null;
  }

  async _fetch(url) {
    let absoulteUrl = url;

    if (url.indexOf(`${window.location.protocol}//${window.location.host}`) === -1) {
      absoulteUrl = `${window.location.protocol}//${window.location.host}${url}`;
    }

    this._showAjax();
    const { data, status } = await ajaxCacher.fetch(absoulteUrl);
    this._hideAjax();

    if (status !== 200) {
      if (status === 451) {
        Turbolinks.visit(window.location.href);
      } else {
        flash.error(I18n.t('frontend.lib.please_try_again_later'));
      }
      return;
    }

    if (window.location.href === absoulteUrl) {
      this._processResponse(data, absoulteUrl);
    }
  }

  _processResponse(data, url) {
    document.title = `${data.title}`;
    const $content = $(data.content);

    // using Object.clone cause UserRatesTracker changes data in its its argument
    UserRatesTracker.track(Object.clone(data.JS_EXPORTS), $content);

    // for cutted_covers
    if (this.$content.data('dynamic')) {
      this.$content.addClass(DynamicParser.PENDING_CLASS);
    }
    this.$content.html($content).process();

    $('.head h1').html(data.title);
    if (data.notice) {
      $('.head .notice').html(data.notice);
    }

    this.$linkCurrent.html(data.page);
    this.$linkTotal.html(data.pages_count);

    this.$linkPrev.attr({ href: data.prev_page_url || '' });
    if (data.prev_page_url) {
      this.$linkPrev.removeClass('disabled');
    } else {
      this.$linkPrev.addClass('disabled');
    }

    this.$linkNext.attr({ href: data.next_page_url || '' });
    if (data.next_page_url) {
      this.$linkNext.removeClass('disabled');
    } else {
      this.$linkNext.addClass('disabled');
    }

    this.$pagination.toggle(
      !(this.$linkNext.hasClass('disabled') && this.$linkPrev.hasClass('disabled'))
    );

    this.$content.trigger('ajax:success');

    if (url) {
      // google analytics
      if ('_gaq' in window) {
        window._gaq.push(['_trackPageview', url]);
      }
      // yandex metrika
      if ('yaCounter7915231' in window) {
        window.yaCounter7915231.hit(url);
      }
    }
  }

  _showAjax() {
    this.$content.addClass('b-ajax');
  }

  _hideAjax() {
    this.$content.removeClass('b-ajax');
  }
}
