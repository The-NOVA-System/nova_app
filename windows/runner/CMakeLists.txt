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

target_link_options(${APP_NAME} PUBLIC -ObjC)
target_link_libraries(${APP_NAME}
    ${advapi32}
    ${ws2_32}
    ${crypt32}
    ${rpcrt4}
    ${ole32}
    ${shell32})