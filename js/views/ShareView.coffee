_ = require('underscore')
Backbone = require('backbone')
qs = require('querystring')

Url = qs.parse(window.location.search.slice(1))['share-url']

M = global.Messages.ShareView

# Shows social-media share buttons.
#
# It looks to the query parameters to find out what URL to share it. So when
# loading the iframe, add `?share-url=http%3a...`. Otherwise, this will be
# empty.
module.exports = class ShareView extends Backbone.View
  tagName: 'ul'
  className: 'share'

  # <li class="twitter">
  #   <a target="_blank" href="https://twitter.com/intent/tweet?status=<%= encodeURIComponent(text) %>">
  #     <i class="icon icon-twitter"></i>
  #     #{M.twitter}
  #   </a>
  # </li>
  template: _.template("""
    <li class="facebook">
      <a target="_blank" href="https://www.facebook.com/sharer/sharer.php?u=<%= encodeURIComponent(url) %>">
        <i class="icon icon-facebook"></i>
        #{M.facebook}
      </a>
    </li>
    <li class="google-plus">
      <a target="_blank" href="https://plus.google.com/share?url=<%= encodeURIComponent(url) %>">
        <i class="icon icon-google-plus"></i>
        #{M.googlePlus}
      </a>
    </li>
  """)

  render: ->
    if Url
      html = @template
        url: Url
        text: M.tweetText.replace('{}', Url)
      @$el.html(html)
    @
