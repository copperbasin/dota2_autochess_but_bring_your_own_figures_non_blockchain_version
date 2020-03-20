window.rel_mouse_coords = (event) ->
  totalOffsetX = 0
  totalOffsetY = 0
  # react only patch
  # currentElement = event.currentTarget
  currentElement = event.target
  loop
    totalOffsetX += currentElement.offsetLeft - currentElement.scrollLeft
    totalOffsetY += currentElement.offsetTop - currentElement.scrollTop
    break if !(currentElement = currentElement.offsetParent)
  return {
    x:event.pageX - totalOffsetX
    y:event.pageY - totalOffsetY
  }