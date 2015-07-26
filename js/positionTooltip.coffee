Backbone = require('backbone')
$ = Backbone.$

# Positions the tooltip (which must already be visible) such that it is just
# above (or below) the target, centered.
module.exports = (targetEl, tooltipEl) ->
  $target = $(targetEl)
  $tooltip = $(tooltipEl)

  # Show tooltip _above_ the target, if possible -- nicer on mobile
  margin = 10 # 10px between item top and tooltip bottom

  targetOffset = $target.offset()
  targetSize = if targetEl.hasAttribute('r') # svg <circle>
    d = +targetEl.getAttribute('r') << 1
    width: d
    height: d
  else
    width: $target.width()
    height: $target.height()

  css = {}

  # Figure out vertical alignment
  #
  # Go above target if there's space; otherwise, below
  tooltipHeight = $tooltip.outerHeight()
  css.top = if targetOffset.top - $(window).scrollTop() > tooltipHeight
    targetOffset.top - margin - tooltipHeight
  else
    targetOffset.top + targetSize.height + margin

  # Align tooltip horizontally
  #
  # Center over target; ensure margin px from edges
  tooltipWidth = $tooltip.outerWidth()
  rightLimit = $(window).width()
  left = targetOffset.left + (targetSize.width / 2) - (tooltipWidth / 2)
  if left + tooltipWidth + margin > rightLimit
    left = rightLimit - tooltipWidth - margin
  else if left < margin
    left = margin
  css.left = left

  $tooltip.css(css)
