cmake_minimum_required(VERSION 3.21)
project(cef_embedder_spike LANGUAGES C CXX)

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

  set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CEF_ROOT}/cmake")
  find_package(CEF REQUIRED)

  if(NOT OS_LINUX)
    message(FATAL_ERROR "The first embedder spike currently targets Linux only")
  endif()

  # Match the sample-project / cefsimple binary-distribution shape on Linux.
  add_logical_target("libcef_lib" "${CEF_LIB_DEBUG}" "${CEF_LIB_RELEASE}")
  set_cef_target_out_dir()

  add_subdirectory(${CEF_LIBCEF_DLL_WRAPPER_PATH} libcef_dll_wrapper)

  add_executable(cef_embedder_spike
    src/main_linux.cc
    src/spike_app.cc
    src/spike_app.h
    src/spike_handler.cc
    src/spike_handler.h
  )
  set_executable_target_properties(cef_embedder_spike)
  add_dependencies(cef_embedder_spike libcef_dll_wrapper)
  target_link_libraries(cef_embedder_spike libcef_lib libcef_dll_wrapper ${CEF_STANDARD_LIBS})
  set_target_properties(cef_embedder_spike PROPERTIES
    INSTALL_RPATH "$ORIGIN"
    BUILD_WITH_INSTALL_RPATH TRUE
    RUNTIME_OUTPUT_DIRECTORY ${CEF_TARGET_OUT_DIR}
  )

  copy_files("cef_embedder_spike" "${CEF_BINARY_FILES}" "${CEF_BINARY_DIR}" "${CEF_TARGET_OUT_DIR}")
  copy_files("cef_embedder_spike" "${CEF_RESOURCE_FILES}" "${CEF_RESOURCE_DIR}" "${CEF_TARGET_OUT_DIR}")
  if(EXISTS "${CEF_BINARY_DIR}/libminigbm.so")
    copy_files("cef_embedder_spike" "libminigbm.so" "${CEF_BINARY_DIR}" "${CEF_TARGET_OUT_DIR}")
  endif()
  set_linux_suid_permissions("cef_embedder_spike" "${CEF_TARGET_OUT_DIR}/chrome-sandbox")
else()
  message(STATUS "CEF spike scaffold only. Reconfigure with -DCEF_EMBEDDER_SPIKE_ENABLE_CEF=ON once a CEF distribution is available.")
  add_executable(cef_embedder_spike src/main_stub.cpp)
  target_compile_features(cef_embedder_spike PRIVATE cxx_std_20)
endif()
