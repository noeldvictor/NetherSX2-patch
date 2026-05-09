cmake_minimum_required(VERSION 3.14)

project(nethersx2_gpu_driver_shim LANGUAGES C CXX)

if(NOT DEFINED ADRENOTOOLS_DIR)
    message(FATAL_ERROR "ADRENOTOOLS_DIR must point to a libadrenotools checkout")
endif()

set(BUILD_SHARED_LIBS OFF CACHE BOOL "" FORCE)
set(GEN_INSTALL_TARGET OFF CACHE BOOL "" FORCE)

add_subdirectory("${ADRENOTOOLS_DIR}" adrenotools-build)

add_library(vulkad SHARED gpu_driver_shim.cpp)
target_compile_features(vulkad PRIVATE cxx_std_17)
target_include_directories(vulkad PRIVATE "${ADRENOTOOLS_DIR}/include")
target_link_libraries(vulkad PRIVATE adrenotools log dl)
target_link_options(vulkad PRIVATE "-Wl,-z,global")
