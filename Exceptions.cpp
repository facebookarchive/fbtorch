/**
 * Copyright 2014 Facebook
 * @author Tudor Bosman (tudorb@fb.com)
 */

#include <cstdio>
#include <dlfcn.h>
#include <exception>

#include <glog/logging.h>

#include <lua.hpp>

#include "folly/String.h"

namespace facebook { namespace deeplearning { namespace torch {

namespace {

int wrapExceptions(lua_State* L, lua_CFunction f) {
  try {
    return f(L);
  } catch (const std::exception& e) {
    lua_pushstring(L, folly::exceptionStr(e).c_str());
  }
  // Do not catch (...) as that ends up catching Lua errors, which
  // causes problems if wrapExceptions is on the stack multiple times.
  return lua_error(L);  // Rethrow as a Lua error
}

}  // namespace

// There is no way to hook on module unloading, but if the module containing
// wrapExceptions() gets unloaded (and dlclose()d) during Lua shutdown, all
// future calls to C library functions (from other finalizers) will segfault!
//
// This is a bug in LuaJIT 2.0.2.
//
// First, I (tudorb) tried to work around this by creating a global userdata
// object that we use as a sentinel. When that object gets GCed, we turn off
// wrapping. It didn't work; that ensures that future code generated
// by LuaJIT won't call the wrapper, but code that's already compiled
// still does.
//
// This is a horrible hack: we want to prevent unloading the current shared
// library. We'll reopen it to bump the reference count and leak the reference.

void initWrappedExceptions(lua_State* L) {
  Dl_info thisLib;
  int r = dladdr(reinterpret_cast<void*>(&wrapExceptions), &thisLib);
  CHECK(r != 0 && thisLib.dli_fname);

  void* leakedHandle = dlopen(thisLib.dli_fname, RTLD_NODELETE | RTLD_NOW);
  CHECK(leakedHandle);

  lua_pushlightuserdata(L, reinterpret_cast<void*>(&wrapExceptions));
  luaJIT_setmode(L, -1, LUAJIT_MODE_WRAPCFUNC | LUAJIT_MODE_ON);
  lua_pop(L, 1);
}

}}}  // namespaces
