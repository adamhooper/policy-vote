_ = require('underscore')
Backbone = require('backbone')

Provinces = require('../../lib/Provinces').all

module.exports = class UserProfileView extends Backbone.View
  tagName: 'form'
  className: 'user-profile'

  template: _.template("""
    <fieldset class="language-code">
      <legend>Your language / votre langue</legend>
      <ul class="language-code">
        <li>
          <input id="language-code-en" type="radio" name="languageCode" value="en">
          <label for="language-code-en">I prefer English</label>
        </li>
        <li>
          <input id="language-code-fr" type="radio" name="languageCode" value="en">
          <label for="language-code-fr">Je préfère le français</label>
        </li>
      </ul>
    </fieldset>
    <fieldset class="province-code" disabled>
      <legend>Where you live</legend>

      <select id="province-code" name="provinceCode" value="">
        <option value="">I prefer not to say</option>
        <% provinces.forEach(function(province) { %>
          <option value="<%- province.code %>"><%- province.en %></option>
        <% }); %>
      </select>
    </fieldset>
    <fieldset class="actions" disabled>
      <button type="submit" class="submit">I'm ready</button>
    </fieldset>
    <div class="spinner-overlay">
      <div class="spinner-loader">
      </div>
    </div>
  """)

  events:
    'change input[name="languageCode"]': '_onChangeLanguageCode'
    'click button.submit': '_onSubmit'

  render: ->
    @$el.html(@template(provinces: Provinces))
    @

  _onChangeLanguageCode: ->
    @$('fieldset').prop('disabled', false)
    @trigger('user-clicked')

  _onSubmit: (e) ->
    e.preventDefault()

    @trigger 'user-set-profile',
      languageCode: @$('input[name="languageCode"]:checked').val()
      provinceCode: @$('input[name="provinceCode"]').val() || null
