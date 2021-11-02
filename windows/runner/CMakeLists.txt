cmake_minimum_required(VERSION 3.15)
project(runner LANGUAGES CXX)

add_executable(${BINARY_NAME} WIN32
  "flutter_window.cpp"
  "main.cpp"
  "utils.cpp"
  "win32_window.cpp"
  "${FLUTTER_MANAGED_DIR}/generated_plugin_registrant.cc"
  "Runner.rc"
  "runner.exe.manifest"
)
apply_standard_settings(${BINARY_NAME})
target_compile_definitions(${BINARY_NAME} PRIVATE "NOMINMAX")
target_link_libraries(${BINARY_NAME} PRIVATE flutter flutter_wrapper_app cocos2d firebase_auth firebase_app firebase_firestore)
target_include_directories(${BINARY_NAME} PRIVATE "${CMAKE_SOURCE_DIR}")
add_dependencies(${BINARY_NAME} flutter_assemble)
add_subdirectory(third_party/firebase_cpp_sdk)

find_library(ADVAPI32_LIB advapi32)
 if (NOT ADVAPI32_LIB)
     message(FATAL_ERROR "\tFailed to find advapi32")
 endif()

 find_library(WS2_32_LIB ws2_32)
 if (WS2_32_LIB)
     message(FATAL_ERROR "\tFailed to find ws2_32")
 endif()

 find_library(CRYPT32_LIB crypt32)
 if (NOT CRYPT32_LIB)
     message(FATAL_ERROR "\tFailed to find crypt32")
 endif()

 find_library(RPCRT4_LIB rpcrt4)
 if (NOT RPCRT4_LIB)
     message(FATAL_ERROR "\tFailed to find rpcrt4")
 endif()

 find_library(OLE32_LIB ole32)
 if (NOT OLE32_LIB)
     message(FATAL_ERROR "\tFailed to find ole32")
 endif()

 find_library(SHELL32_LIB shell32)
 if (NOT SHELL32_LIB)
     message(FATAL_ERROR "\tFailed to find shell32")
 endif()

target_link_options(${BINARY_NAME} PUBLIC -ObjC)
target_link_libraries(${BINARY_NAME}
    PRIVATE
    ${ADVAPI32_LIB}
    ${WS2_32_LIB}
    ${CRYPT32_LIB}
    ${RPCRT4_LIB}
    ${OLE32_LIB}
    ${SHELL32_LIB})