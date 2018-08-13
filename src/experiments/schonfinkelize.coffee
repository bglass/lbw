schonfinkelize = (fn) ->
  slice = Array::slice
  stored_args = slice.call(arguments, 1)
  ->
    new_args = slice.call(arguments)
    args = stored_args.concat(new_args)
    fn.apply null, args
