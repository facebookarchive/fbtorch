/**
 * Copyright 2014 Facebook
 * @author Tudor Bosman (tudorb@fb.com)
 */

#ifndef DEEPLEARNING_TORCH_EXCEPTIONS_H_
#define DEEPLEARNING_TORCH_EXCEPTIONS_H_

#include <lua.hpp>

namespace facebook { namespace deeplearning { namespace torch {

void initWrappedExceptions(lua_State* L);

}}}  // namespaces

#endif /* DEEPLEARNING_TORCH_EXCEPTIONS_H_ */

