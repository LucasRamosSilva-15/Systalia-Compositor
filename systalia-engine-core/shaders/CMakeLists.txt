add_library(systalia_engine_shaders OBJECT)

target_link_libraries(systalia_engine_shaders PRIVATE
    Qt6::Core
    Qt6::Gui
    Qt6::ShaderTools
)

qt6_add_shaders(systalia_engine_shaders "systalia_engine_shaders"
    PREFIX
        "/shaders"
    FILES
        valo_optical.vert
        valo_optical.frag
)
