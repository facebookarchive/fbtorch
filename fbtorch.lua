-- Copyright 2004-present Facebook. All Rights Reserved.

-- Always line-buffer stdout because we want our logs not to be slow, even
-- if they are redirected.
io.stdout:setvbuf('line')

local pl = require('pl.import_into')()
local util = require('fb.util')

-- Compatibility stuff, LuaJIT in 5.2 compat mode has renamed string.gfind
-- to string.gmatch
if string.gfind == nil then
    string.gfind = string.gmatch
end

-- sys.clock is broken, broken, broken!
local sys = require('sys')
sys.clock = util.time

local timer_start
local function tic()
    timer_start = util.monotonic_clock()
end
sys.tic = tic

local function toc(verbose)
    local duration = util.monotonic_clock() - timer_start
    if verbose then print(duration) end
    return duration
end
sys.toc = toc

-- Load C extension which loads torch and sets up error handlers
local torch = require('fbtorch_ext')

if LuaUnit then
    -- modify torch.Tester to use our own flavor of LuaUnit

    torch.Tester.assert_sub = function(self, condition, message)
        if not condition then
            error(message)
        end
    end

    torch.Tester.run = function(self, run_tests)
        local tests, testnames

        tests = self.tests
        testnames = self.testnames
        if type(run_tests) == 'string' then
            run_tests = {run_tests}
        end
        if type(run_tests) == 'table' then
            tests = {}
            testnames = {}
            for i,fun in ipairs(self.tests) do
                for j,name in ipairs(run_tests) do
                    if self.testnames[i] == name then
                        tests[#tests+1] = self.tests[i]
                        testnames[#testnames+1] = self.testnames[i]
                    end
                end
            end
        end

        -- global
        TestTorch = {}

        for i,fun in ipairs(tests) do
            local name = testnames[i]
            TestTorch['test_' .. name] = fun
        end

        -- LuaUnit will run tests (functions whose names start with 'test')
        -- from all globals whose names start with 'test'
        LuaUnit:run()
    end
end


if os.getenv('LUA_DEBUG') then
    require('fb.debugger').enter()
end

-- reload: unload a module and re-require it
local function reload(mod, ...)
    package.loaded[mod] = nil
    return require(mod, ...)
end
torch.reload = reload

return torch
