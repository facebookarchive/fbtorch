CMAKE_MINIMUM_REQUIRED(VERSION 2.6 FATAL_ERROR)
CMAKE_POLICY(VERSION 2.6)
IF(APPLE)
    message(STATUS "FBCUNN Untested/Unsupported on OSX")
ENDIF()

SET(CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake" "${CMAKE_MODULE_PATH}")

FIND_PACKAGE(Torch REQUIRED)
INCLUDE(MultiLevelIncludes)
MLI_SET_DEPTH(2)
FIND_PACKAGE(Folly REQUIRED)

LINK_DIRECTORIES("${Torch_INSTALL_LIB}")

########################################################
FILE(GLOB luasrc fbtorch.lua)
SET(src
  Exceptions.cpp
  FBTorch.cpp
  )

SET(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++11")

ADD_LIBRARY(fbtorch_ext MODULE ${src})

set_target_properties(fbtorch_ext 
                      PROPERTIES PREFIX "")

INSTALL(TARGETS fbtorch_ext
  RUNTIME DESTINATION "${Torch_INSTALL_LUA_CPATH_SUBDIR}"
  LIBRARY DESTINATION "${Torch_INSTALL_LUA_CPATH_SUBDIR}")

INSTALL(
  FILES
  ${luasrc}
  DESTINATION "${Torch_INSTALL_LUA_PATH_SUBDIR}")

TARGET_LINK_LIBRARIES(fbtorch_ext folly)

