cmake_minimum_required(VERSION 3.22)

find_package(Qt6 6.7 REQUIRED COMPONENTS
    Core
    Gui
    Test
    ShaderTools
)

find_package(Vulkan REQUIRED)

qt_add_executable(tst_systalia_engine
    tst_SystaliaEngine.cpp
)

target_include_directories(tst_systalia_engine PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}/../src
    ${CMAKE_CURRENT_SOURCE_DIR}/../src/gfx
)

target_link_libraries(tst_systalia_engine PRIVATE
    Qt6::Core
    Qt6::Gui
    Qt6::Test
    Qt6::ShaderTools
    Vulkan::Vulkan
)

qt6_add_shaders(tst_systalia_engine "tst_engine_shaders"
    BATCHABLE
    PREFIX
        "/shaders"
    BASE
        "${CMAKE_CURRENT_SOURCE_DIR}/../shaders"
    FILES
        ${CMAKE_CURRENT_SOURCE_DIR}/../shaders/valo_optical.vert
        ${CMAKE_CURRENT_SOURCE_DIR}/../shaders/valo_optical.frag
)

add_test(NAME tst_systalia_engine COMMAND tst_systalia_engine)
