Backbone = require('backbone')
$ = Backbone.$
_ = require('underscore')

module.exports = class QuestionView extends Backbone.View
  className: 'question'
  template: _.template('''
    <button class="choice" data-policy-id="<%- policy1.id %>" data-other-policy-id="<%- policy2.id %>">
      <span class="inner">
        <%- policy1.get('en') %>
      </a>
    </button>
    <button class="choice" data-policy-id="<%- policy2.id %>" data-other-policy-id="<%- policy1.id %>">
      <span class="inner">
        <%- policy2.get('en') %>
      </span>
    </button>
  ''')

  events:
    'click button': '_onClickButton'

  initialize: (options) ->
    throw new Error('Must pass options.policies, a Policies') if !options.policies?

    @policies = options.policies
    @unseenPolicies = @policies.shuffle()

  pick2: ->
    [ @unseenPolicies.pop(), @unseenPolicies.pop() ]

  render: ->
    [ policy1, policy2 ] = @pick2()
    @$el.html(@template(policy1: policy1, policy2: policy2))

  _onClickButton: (e) ->
    policyId = $(e.currentTarget).attr('data-policy-id')
    otherPolicyId = $(e.currentTarget).attr('data-other-policy-id')
    @trigger('user-prefers-policy', @policies.get(policyId), @policies.get(otherPolicyId))
