// http://www.drdobbs.com/open-source/currying-and-partial-functions-in-javasc/231001821?pgno=2

function schonfinkelize(fn) {
     var slice = Array.prototype.slice,
        stored_args = slice.call(arguments, 1);
     return function () {
        var new_args = slice.call(arguments),
              args = stored_args.concat(new_args);
        return fn.apply(null, args);
     };
}
