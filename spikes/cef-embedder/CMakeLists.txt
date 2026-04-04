cmake_minimum_required(VERSION 3.21)
project(cef_embedder_spike LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

option(CEF_EMBEDDER_SPIKE_ENABLE_CEF "Build against a local CEF binary distribution" OFF)

if(CEF_EMBEDDER_SPIKE_ENABLE_CEF)
  if(NOT DEFINED CEF_ROOT AND DEFINED ENV{CEF_ROOT})
    set(CEF_ROOT "$ENV{CEF_ROOT}")
  endif()

  if(NOT DEFINED CEF_ROOT)
    message(FATAL_ERROR "CEF_EMBEDDER_SPIKE_ENABLE_CEF=ON requires -DCEF_ROOT=/path/to/cef_binary_... or CEF_ROOT in the environment")
  endif()

  message(STATUS "CEF spike bootstrap mode enabled")
  message(STATUS "CEF_ROOT=${CEF_ROOT}")
  message(STATUS "Next step: wire FindCEF / sample-project style bootstrap here")
else()
  message(STATUS "CEF spike scaffold only. Reconfigure with -DCEF_EMBEDDER_SPIKE_ENABLE_CEF=ON once a CEF distribution is available.")
endif()

add_executable(cef_embedder_spike src/main.cpp)

target_compile_features(cef_embedder_spike PRIVATE cxx_std_20)
