_ = require('underscore')
Backbone = require('backbone')
qs = require('querystring')

Url = qs.parse(window.location.search.slice(1))['share-url']

# Shows social-media share buttons.
#
# It looks to the query parameters to find out what URL to share it. So when
# loading the iframe, add `?share-url=http%3a...`. Otherwise, this will be
# empty.
module.exports = class ShareView extends Backbone.View
  tagName: 'ul'
  className: 'share'

  template: _.template('''
    <li class="twitter">
      <a target="_blank" href="https://twitter.com/intent/tweet?status=<%= encodeURIComponent(text + ' ' + url) %>">
        <i class="icon icon-twitter"></i>
        Tweet
      </a>
    </li>
    <li class="facebook">
      <a target="_blank" href="https://www.facebook.com/sharer/sharer.php?u=<%= encodeURIComponent(url) %>">
        <i class="icon icon-facebook"></i>
        Share
      </a>
    </li>
    <li class="google-plus">
      <a target="_blank" href="https://plus.google.com/share?url=<%= encodeURIComponent(url) %>">
        <i class="icon icon-google-plus"></i>
        Share
      </a>
    </li>
  ''')

  render: ->
    if Url
      html = @template(text: 'Tweet', url: Url)
      @$el.html(html)
    @
