cmake_minimum_required(VERSION 3.22)

find_package(Qt6 6.7 REQUIRED COMPONENTS Core Gui Quick Test ShaderTools)
find_package(Vulkan REQUIRED)

# 1. Teste Unitário (std140, offsets e assets .qsb)
add_executable(tst_systalia_engine tst_SystaliaEngine.cpp)
target_link_libraries(tst_systalia_engine PRIVATE Qt6::Core Qt6::Test systalia_engine_core)
add_test(NAME Unit_Std140AndAssets COMMAND tst_systalia_engine)

# 2. Teste Gráfico Offscreen (Validação da Janela Principal e Refração)
add_executable(tst_render_verification tst_RenderVerification.cpp)
target_link_libraries(tst_render_verification PRIVATE Qt6::Core Qt6::Gui Qt6::Quick Qt6::Test systalia_engine_core Vulkan::Vulkan)
add_test(NAME Render_MainWindowAndRefraction COMMAND tst_render_verification)
