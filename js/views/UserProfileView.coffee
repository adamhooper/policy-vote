_ = require('underscore')
Backbone = require('backbone')

Provinces = require('../../lib/Provinces')

module.exports = class UserProfileView extends Backbone.View
  tagName: 'form'
  className: 'user-profile'

  template: _.template("""
    <fieldset class="province-code">
      <legend>Where you live</legend>

      <select id="province-code" name="provinceCode" value="">
        <option value="">I prefer not to say</option>
        <% provinces.forEach(function(province) { %>
          <option value="<%- province.code %>"><%- province.name %></option>
        <% }); %>
      </select>
    </fieldset>
    <fieldset class="actions">
      <button type="submit" class="submit">I'm ready</button>
    </fieldset>
  """)

  events:
    'click button.submit': '_onSubmit'

  render: ->
    provinces = Provinces.all.slice()
    provinces.sort((a, b) -> a.name.localeCompare(b.name))
    @$el.html(@template(provinces: provinces))
    @

  _onChangeLanguageCode: ->
    @$('fieldset').prop('disabled', false)
    @trigger('user-clicked')

  _onSubmit: (e) ->
    e.preventDefault()

    @trigger 'user-set-profile',
      provinceCode: @$('input[name="provinceCode"]').val() || null
