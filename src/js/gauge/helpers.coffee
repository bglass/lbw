

exports.filter = (table, keep) ->
  filtered = {}
  for key, value of table
    if key in keep then filtered[key] = value
  return filtered

exports.round = (v,n) ->
  d = Math.pow(10,n)
  Math.round(v*d)/d

exports.merge = merge = (basic, update) ->
  combined = merge_shallow basic, update
  for k, v of combined
    if typeof v == "object" and basic[k]? and update[k]?
      combined[k] = merge(basic[k], update[k])
  return combined
merge_shallow = (xs...) ->
  if xs?.length > 0
    tap {}, (m) -> m[k] = v for k, v of x for x in xs
tap = (o, fn) -> fn(o); o


exports.hasClass = (el, className) ->
  if el.classList
    el.classList.contains className
  else
    ! !el.className.match(new RegExp('(\\s|^)' + className + '(\\s|$)'))

exports.addClass = (el, className) ->
  if el.classList
    el.classList.add className
  else if !hasClass(el, className)
    el.className += ' ' + className
  return

exports.removeClass = (el, className) ->
  if el.classList
    el.classList.remove className
  else if hasClass(el, className)
    reg = new RegExp('(\\s|^)' + className + '(\\s|$)')
    el.className = el.className.replace(reg, ' ')
  return
