Backbone = require('backbone')
$ = Backbone.$
_ = require('underscore')

Policies = require('../Policies')

module.exports = class QuestionView extends Backbone.View
  className: 'question'
  template: _.template('''
    <button class="choice" data-policy-id="<%- policy1.id %>" data-other-policy-id="<%- policy2.id %>">
      <span class="inner">
        <%- policy1.en %>
      </a>
    </button>
    <button class="choice" data-policy-id="<%- policy2.id %>" data-other-policy-id="<%- policy1.id %>">
      <span class="inner">
        <%- policy2.en %>
      </span>
    </button>
  ''')

  events:
    'click button': '_onClickButton'

  initialize: (options) ->
    throw 'Must pass options.province, the user\'s Province' if 'province' not of options

    @province = options.province
    @unseenPolicies = []

  _policyAppliesInProvince: (policy) ->
    for party in policy.parties
      return true if !party.onlyInProvince? || party.onlyInProvince == @province
    false

  pick2: ->
    if @unseenPolicies.length < 2
      # More policies!
      @unseenPolicies = @unseenPolicies.concat(_.shuffle(
        Policies.all.slice()
          .filter((p) => @_policyAppliesInProvince(p))
      ))
    [ @unseenPolicies.pop(), @unseenPolicies.pop() ]

  render: ->
    [ policy1, policy2 ] = @pick2()
    @$el.html(@template(policy1: policy1, policy2: policy2))

  _onClickButton: (e) ->
    policyId = $(e.currentTarget).attr('data-policy-id')
    otherPolicyId = $(e.currentTarget).attr('data-other-policy-id')
    @trigger('user-prefers-policy', Policies.byId[policyId], Policies.byId[otherPolicyId])
