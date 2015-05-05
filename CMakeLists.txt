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
FILE(GLOB luasrc *.lua)
SET(src
  Exceptions.cpp
  FBTorch.cpp
  )

SET(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++11")

ADD_TORCH_PACKAGE(fbtorch "${src}" "${luasrc}")
TARGET_LINK_LIBRARIES(fbtorch folly)

