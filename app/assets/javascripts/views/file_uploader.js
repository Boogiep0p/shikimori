import ShikiFileUploader from 'shiki-utils/src/file_uploader';

import csrf from 'helpers/csrf';

export class FileUploader extends ShikiFileUploader {
  constructor(node, options = {}) {
    super({
      ...options,
      node,
      locale: I18n.locale,
      xhrEndpoint: node.getAttribute('data-upload_url'),
      xhrHeaders: () => csrf().headers
    });

    this.node.classList.remove('b-ajax');
    this._scheduleUnbind();
  }

  _scheduleUnbind() {
    $(document).one('turbolinks:before-cache', this.destroy);
  }
}