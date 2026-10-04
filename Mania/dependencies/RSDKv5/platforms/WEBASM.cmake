cmake_minimum_required(VERSION 3.20)

project(RetroEngine)

if(NOT EMSCRIPTEN)
    message(FATAL_ERROR
        "This CMake configuration is for WebAssembly/Emscripten. Configure with emcmake."
    )
endif()

set(RETRO_SUBSYSTEM "SDL2" CACHE STRING "The subsystem to use")

set(DEP_PATH all)

message(NOTICE "Configuring RetroEngine for WebAssembly")

add_executable(
    RetroEngine
    ${RETRO_FILES}
)

# Emscripten provides SDL2 through -sUSE_SDL=2.
# No desktop SDL2 CMake package is required.

# Ogg
find_package(Ogg CONFIG)

if(NOT Ogg_FOUND)

    message(NOTICE
        "libogg not found, attempting to build from source"
    )

    set(COMPILE_OGG TRUE)

else()

    message(NOTICE "found libogg")

    add_library(libogg ALIAS Ogg::ogg)

    target_link_libraries(
        RetroEngine
        PRIVATE
        libogg
    )

endif()

# Theora
find_package(unofficial-theora CONFIG)

if(unofficial-theora_FOUND)

    message(NOTICE "found libtheora")

    add_library(
        libtheora
        ALIAS
        unofficial::theora::theora
    )

    target_link_libraries(
        RetroEngine
        PRIVATE
        libtheora
    )

else()

    message(NOTICE
        "could not find unofficial-theora, attempting to find Theora"
    )

    find_package(Theora CONFIG)

    if(Theora_FOUND)

        message(NOTICE "found libtheora")

        add_library(
            libtheora
            ALIAS
            Theora::theora
        )

        target_link_libraries(
            RetroEngine
            PRIVATE
            libtheora
        )

    else()

        message(NOTICE
            "libtheora not found, attempting to build from source"
        )

        set(COMPILE_THEORA TRUE)

    endif()

endif()

target_compile_definitions(
    RetroEngine
    PRIVATE
    _CRT_SECURE_NO_WARNINGS
)

target_link_options(
    RetroEngine
    PRIVATE

    -sUSE_SDL=2
    -sWASM=1
    -sNO_EXIT_RUNTIME=1
    -sASSERTIONS=1

    -sUSE_WEBGL2=1
    -sMIN_WEBGL_VERSION=2

    -sALLOW_MEMORY_GROWTH=1

    -sPTHREAD_POOL_SIZE=0

    -sEXPORTED_RUNTIME_METHODS=["ccall","cwrap"]

    --shell-file
    ${CMAKE_CURRENT_SOURCE_DIR}/shell.html
)

if(USE_MINIAUDIO)

    target_compile_definitions(
        RetroEngine
        PRIVATE
        RETRO_AUDIODEVICE_MINI=1
    )

endif()

if(
    CMAKE_CXX_COMPILER_ID STREQUAL "Clang"
    OR
    CMAKE_CXX_COMPILER_ID STREQUAL "GNU"
)

    target_compile_options(
        RetroEngine
        PRIVATE

        -Wno-microsoft-cast
        -Wno-microsoft-exception-spec
    )

endif()