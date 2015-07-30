_ = require('underscore')
Backbone = require('backbone')

Parties = require('../../lib/Parties').all

M = global.Messages.DotColorLegend

module.exports = class DotColorLegend extends Backbone.View
  className: 'policy-color-legend'

  initialize: (options) ->
    throw 'must pass options.province, a Province' if 'province' not of options

    @province = options.province

  template: _.template("""
    <div class="multi-party-policy">
      <ul>
        <% parties.forEach(function(party) { %><li class="policy"></li><% }); %>
      </ul>
      <span class="label">#{M.multiPartyPolicy}</span>
    </div>
    <div class="one-party-policies">
      <ul>
        <% parties.forEach(function(party) { %><li class="policy" style="background: <%- party.color %>;"></li><% }); %>
      </ul>
      <span class="label">#{M.onePartyPolicy}</span>
    </div>
  """)

  render: ->
    parties = (p for p in Parties when !p.onlyInProvince || p.onlyInProvince == @province)
    @$el.html(@template(parties: parties))
    @
