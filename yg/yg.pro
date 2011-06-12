# Yoga graphics or graphics yoga?

TARGET = yg
TEMPLATE = lib
CONFIG += staticlib
DEFINES += YG_LIBRARY

ROOT_DIR = ..
DEPENDENCIES = geometry coding base freetype fribidi expat

INCLUDEPATH += $$ROOT_DIR/3party/freetype/include $$ROOT_DIR/3party/agg

include($$ROOT_DIR/common.pri)

!iphone*:!bada* {
  DEPENDENCIES += platform
}

SOURCES += \
    internal/opengl.cpp \
    vertex.cpp \
    resource_manager.cpp \
    skin.cpp \
    pen_info.cpp \
    resource_style.cpp \
    color.cpp \
    skin_loader.cpp \
    memento.cpp \
    framebuffer.cpp \
    vertexbuffer.cpp \
    indexbuffer.cpp \
    utils.cpp \
    renderbuffer.cpp \
    base_texture.cpp \
    managed_texture.cpp \
    fence.cpp \
    thread_renderer.cpp \
    render_command.cpp \
    blitter.cpp \
    clipper.cpp \
    renderer.cpp \
    render_state.cpp \
    geometry_renderer.cpp \
    skin_page.cpp \
    storage.cpp \
    render_state_updater.cpp \
    glyph_cache.cpp \
    glyph_cache_impl.cpp \
    ft2_debug.cpp \
    geometry_batcher.cpp \
    text_renderer.cpp \
    layer_manager.cpp \
    path_renderer.cpp \
    shape_renderer.cpp \
    symbol_renderer.cpp \
    circle_info.cpp \
    area_renderer.cpp \
    font_desc.cpp \
    glyph_layout.cpp \
    text_element.cpp \
    text_path.cpp \
    info_layer.cpp

HEADERS += \
    internal/opengl.hpp \
    vertex.hpp \
    resource_manager.hpp \
    texture.hpp \
    skin.hpp \
    skin_loader.hpp \
    pen_info.hpp \
    resource_style.hpp \
    color.hpp \
    memento.hpp \
    framebuffer.hpp \
    vertexbuffer.hpp \
    indexbuffer.hpp \
    utils.hpp \
    renderbuffer.hpp \
    base_texture.hpp \
    managed_texture.hpp \
    fence.hpp \
    thread_renderer.hpp \
    rendercontext.hpp \
    render_command.hpp \
    blitter.hpp \
    clipper.hpp \
    renderer.hpp \
    render_state.hpp \
    geometry_renderer.hpp \
    skin_page.hpp \
    storage.hpp \
    render_state_updater.hpp \
    render_target.hpp \
    glyph_cache.hpp \
    data_formats.hpp \
    glyph_cache_impl.hpp \
    ft2_debug.hpp \
    text_renderer.hpp \
    geometry_batcher.hpp \
    screen.hpp \
    layer_manager.hpp \
    gpu_state.hpp \
    defines.hpp \
    path_renderer.hpp \
    shape_renderer.hpp \
    symbol_renderer.hpp \
    circle_info.hpp \
    area_renderer.hpp \
    font_desc.hpp \
    glyph_layout.hpp \
    text_element.hpp \
    text_path.hpp \
    info_layer.hpp

win32 {
  HEADERS += internal/opengl_win32.hpp
  SOURCES += internal/opengl_win32.cpp
}
