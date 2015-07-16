_ = require('underscore')
Backbone = require('backbone')

Provinces = require('../../app/provinces').all

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

      <ul class="province-code">
        <% provinces.forEach(function(province) { %>
          <li>
            <input id="province-code-<%- province.code %>" type="radio" name="provinceCode" value="<%- province.code %>">
            <label for="province-code-<%- province.code %>"><%- province.en %></label>
          </li>
        <% }); %>
        <li class="province-code-null">
          <input id="province-code-null" type="radio" name="provinceCode" value="">
          <label for="province-code-null">I'm not Canadian / I prefer not to say</label>
        </li>
      </ul>
      </label>
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
    'change input[name="provinceCode"]': '_onChangeProvinceCode'
    'click button.submit': '_onSubmit'

  render: ->
    @$el.html(@template(provinces: Provinces))
    @

  _onChangeLanguageCode: -> @$('fieldset.province-code').prop('disabled', false)
  _onChangeProvinceCode: -> @$('fieldset.actions').prop('disabled', false)
  _onSubmit: (e) ->
    e.preventDefault()
    @$el.addClass('saving')

    profile =
      languageCode: @$('input[name="languageCode"]:checked').val()
      provinceCode: @$('input[name="provinceCode"]:checked').val() || null
    Backbone.ajax
      type: 'POST'
      url: '/user'
      data: JSON.stringify(profile)
      contentType: 'application/json'
      success: => @trigger('user-set-profile', profile)
      error: (xhr, textStatus, errorThrown) -> console.log('Error saving profile', textStatus, errorThrown)
