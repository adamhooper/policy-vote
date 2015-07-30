_ = require('underscore')
Backbone = require('backbone')

Provinces = require('../../lib/Provinces')

M = global.Messages.UserProfileView

module.exports = class UserProfileView extends Backbone.View
  tagName: 'form'
  className: 'user-profile'

  template: _.template("""
    <fieldset class="province-code">
      <legend>#{M.whereYouLive}</legend>

      <select id="province-code" name="province-code" value="">
        <option value="-">#{M.selectProvince}</option>
        <% provinces.forEach(function(province) { %>
          <option value="<%- province.code %>"><%- province.name %></option>
        <% }); %>
        <option value="">#{M.preferNotToSay}</option>
      </select>
    </fieldset>
    <fieldset class="actions">
      <button disabled="disabled" type="submit" class="submit">#{M.ready}</button>
    </fieldset>
  """)

  events:
    'submit': '_onSubmit'
    'change [name=province-code]': '_onChangeProvince'

  render: ->
    provinces = Provinces.all.slice()
    provinces.sort((a, b) -> a.name.localeCompare(b.name))
    @$el.html(@template(provinces: provinces))
    @

  _onChangeLanguageCode: ->
    @$('fieldset').prop('disabled', false)
    @trigger('user-clicked')

  _onSubmit: (e) ->
    return if @$('[name="province-code"]').val() == '-'

    e.preventDefault()

    @trigger 'user-set-profile',
      provinceCode: @$('[name="province-code"]').val() || null

  _onChangeProvince: ->
    @$('button').prop('disabled', @$('[name="province-code"]').val() == '-')
