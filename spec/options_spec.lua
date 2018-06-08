local options = require "luacheck.options"

describe("options", function()
   describe("validate", function()
      it("returns true if options are empty", function()
         assert.is_true(options.validate(options.config_options))
      end)

      it("returns true if options are valid", function()
         assert.is_true(options.validate(options.config_options, {
            globals = {"foo"},
            compat = false,
            unrelated = function() end
         }))
      end)

      it("returns false if options are invalid", function()
         assert.is_false(options.validate(options.config_options, {
            globals = 3,
            redefined = false
         }))

         assert.is_false(options.validate(options.config_options, {
            globals = {3}
         }))

         assert.is_false(options.validate(options.config_options, function() end))

         assert.is_false(options.validate(options.config_options, {
            unused = 0
         }))
      end)

      it("additionally returns name of the problematic field", function()
         assert.equal("globals", select(2, options.validate(options.config_options, {
            globals = 3,
            redefined = false
         })))

         assert.equal("globals", select(2, options.validate(options.config_options, {
            globals = {3}
         })))

         assert.equal("unused", select(2, options.validate(options.config_options, {
            unused = 0
         })))
      end)
   end)

   describe("normalize", function()
      it("applies default values", function()
         opts = options.normalize({})
         assert.same(opts, options.normalize({{}}))

         assert.is_true(opts.unused_secondaries)
         assert.is_false(opts.module)
         assert.is_false(opts.allow_defined)
         assert.is_false(opts.allow_defined_top)
         assert.is_table(opts.globals)
         assert.same({}, opts.rules)
      end)

      it("considers simple boolean options", function()
         local opts = options.normalize({
            {
               module = false,
               unused_secondaries = true
            }, {
               module = true,
               allow_defined = false
            }
         })

         assert.is_true(opts.module)
         assert.is_true(opts.unused_secondaries)
         assert.is_false(opts.allow_defined)
      end)

      it("considers opts.std and opts.compat", function()
         assert.same({baz = true}, options.normalize({
            {
               std = "none"
            }, {
               globals = {"foo", "bar"},
               compat = true
            }, {
               new_globals = {"baz"},
               compat = false
            }
         }).globals)
      end)

      it("considers read-only and regular globals", function()
         local opts = options.normalize({
            {
               std = "lua52",
               globals = {"foo", "bar"},
               read_globals = {"baz"}
            }, {
               new_read_globals = {"quux"},
            }
         })
         local globals = opts.globals
         local read_globals = opts.read_globals
         assert.is_true(globals.foo)
         assert.is_true(globals.bar)
         assert.is_nil(globals.baz)
         assert.is_true(globals.quux)
         assert.is_true(read_globals.quux)
         assert.is_true(read_globals.string)
         assert.is_nil(read_globals._ENV)
         assert.is_true(globals.string)
         assert.is_true(globals._ENV)
      end)

      it("considers macros, ignore, enable and only", function()
         assert.same({
               {{{nil, "^foo$"}}, "only"},
               {{{"^31", nil}}, "disable"},
               {{{"^[23]", nil}}, "enable"},
               {{{"^511", nil}}, "enable"},
               {{{"^412", nil}, {"1$", "^bar$"}}, "disable"}
            }, options.normalize({
            {
               unused = false
            }, {
               ignore = {"412", "1$/bar"}
            }, {
               unused = true,
               unused_values = false,
               enable = {"511"}
            }, {
               only = {"foo"}
            }
         }).rules)
      end)
   end)
end)
