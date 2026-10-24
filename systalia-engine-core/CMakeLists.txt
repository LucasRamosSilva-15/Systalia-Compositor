cmake_minimum_required(VERSION 3.22)
project(systalia_engine_core LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 23)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

if(POLICY QTP0004)
    qt_policy(SET QTP0004 NEW)
endif()

set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_AUTOUIC ON)

find_package(Qt6 6.7 REQUIRED COMPONENTS
    Core
    Gui
    Quick
    QuickControls2
    ShaderTools
)

find_package(Vulkan REQUIRED)

# Biblioteca estática central com o motor, shaders e registro QML
qt_add_library(systalia_engine_core STATIC
    src/gfx/SystaliaSurfaceProps.hpp
    src/gfx/SystaliaGlassMaterial.hpp
    src/gfx/SystaliaGlassMaterial.cpp
    src/gfx/SystaliaGlassItem.hpp
    src/gfx/SystaliaGlassItem.cpp
)

target_include_directories(systalia_engine_core PUBLIC
    ${CMAKE_CURRENT_SOURCE_DIR}/src
    ${CMAKE_CURRENT_SOURCE_DIR}/src/gfx
)

target_link_libraries(systalia_engine_core PUBLIC
    Qt6::Core
    Qt6::Gui
    Qt6::Quick
    Qt6::QuickControls2
    Qt6::ShaderTools
    Vulkan::Vulkan
)

qt6_add_shaders(systalia_engine_core "systalia_engine_shaders"
    PREFIX
        "/shaders"
    BASE
        "shaders"
    FILES
        shaders/valo_optical.vert
        shaders/valo_optical.frag
)

qt_add_qml_module(systalia_engine_core
    URI Systalia.Engine
    VERSION 1.0
    RESOURCE_PREFIX "/qt/qml"
    QML_FILES
        src/qml/main.qml
    NO_PLUGIN
)

# Alvo executável principal
qt_add_executable(systalia_engine_app
    src/main.cpp
)
set_target_properties(systalia_engine_app PROPERTIES OUTPUT_NAME "systalia_engine_core")
target_link_libraries(systalia_engine_app PRIVATE
    systalia_engine_core
)

enable_testing()
add_subdirectory(tests)