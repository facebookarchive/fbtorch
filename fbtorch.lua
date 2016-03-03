-- Copyright 2004-present Facebook. All Rights Reserved.

-- Always line-buffer stdout because we want our logs not to be slow, even
-- if they are redirected.
io.stdout:setvbuf('line')

local pl = require('pl.import_into')()
local util = require('fb.util')
require 'totem'

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

-- OMP tends to badly hurt performance on our multi-die multi-core NUMA
-- machines, so it's off by default.  Turn it on with extreme care, and
-- benchmark, benchmark, benchmark -- check "user time", not just "wall
-- time", since you might be inadvertently wasting a ton of CPU for a
-- negligible wall-clock speedup. For context, read this thread:
-- https://fb.facebook.com/groups/709562465759038/874071175974832
local env_threads = os.getenv('OMP_NUM_THREADS')
if env_threads == nil or env_threads == '' then
   torch.setnumthreads(1)
end

if LuaUnit then
    -- modify torch.Tester and totem.Tester to use our own flavor of LuaUnit

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
        -- from all globals whose names start with 'Test'
        LuaUnit:run()
    end

    totem.Tester._assert_sub = torch.Tester.assert_sub
    totem.Tester._success = function() end
    totem.Tester._failure = function() end

    totem.Tester.run = function(self, run_tests)
        local tests = self.tests
        if type(run_tests) == 'string' then
            run_tests = {run_tests}
        end
        if type(run_tests) == 'table' then
            tests = {}
            for j, name in ipairs(run_tests) do
                if self.tests[name] then
                    tests[name] = self.tests[name]
                end
            end
        end

        -- global
        TestTotem = tests

        -- LuaUnit will run tests (functions whose names start with 'test')
        -- from all globals whose names start with 'Test'
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
