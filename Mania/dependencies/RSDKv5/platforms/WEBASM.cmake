cmake_minimum_required(VERSION 3.20)

project(RetroEngine)

if(NOT EMSCRIPTEN)
    message(FATAL_ERROR "This CMake configuration is for WebAssembly/Emscripten. Configure with emcmake.")
endif()

set(RETRO_SUBSYSTEM "SDL2" CACHE STRING "The subsystem to use")

message(NOTICE "Configuring RetroEngine for WebAssembly")

add_executable(RetroEngine ${RETRO_FILES})

# ------------------------------------------------------------
# SDL2
# ------------------------------------------------------------

find_package(SDL2 CONFIG REQUIRED)

target_link_libraries(RetroEngine
    $<TARGET_NAME_IF_EXISTS:SDL2::SDL2main>
    $<IF:$<TARGET_EXISTS:SDL2::SDL2>,SDL2::SDL2,SDL2::SDL2-static>
)

# ------------------------------------------------------------
# Ogg
# ------------------------------------------------------------

find_package(Ogg CONFIG)

if(NOT Ogg_FOUND)
    message(NOTICE "libogg not found, attempting to build from source")
    set(COMPILE_OGG TRUE)
else()
    message(NOTICE "found libogg")
    add_library(libogg ALIAS Ogg::ogg)
    target_link_libraries(RetroEngine PRIVATE libogg)
endif()

# ------------------------------------------------------------
# Theora
# ------------------------------------------------------------

find_package(unofficial-theora CONFIG)

if(unofficial-theora_FOUND)
    message(NOTICE "found libtheora")
    add_library(libtheora ALIAS unofficial::theora::theora)
    target_link_libraries(RetroEngine PRIVATE libtheora)

else()

    message(NOTICE "could not find unofficial-theora, attempting to find Theora")

    find_package(Theora CONFIG)

    if(Theora_FOUND)

        message(NOTICE "found libtheora")
        add_library(libtheora ALIAS Theora::theora)
        target_link_libraries(RetroEngine PRIVATE libtheora)

    else()

        message(NOTICE "libtheora not found, attempting to build from source")
        set(COMPILE_THEORA TRUE)

    endif()

endif()

# ------------------------------------------------------------
# Compiler definitions
# ------------------------------------------------------------

target_compile_definitions(RetroEngine PRIVATE
    _CRT_SECURE_NO_WARNINGS
)

# ------------------------------------------------------------
# Emscripten linker settings
# ------------------------------------------------------------

target_link_options(RetroEngine PRIVATE

    # Generate an HTML launcher.
    -sUSE_SDL=2

    # Browser/WebAssembly support.
    -sWASM=1

    # Allow the program to run indefinitely.
    -sNO_EXIT_RUNTIME=1

    # Keep the runtime alive.
    -sASSERTIONS=1

    # WebGL 2.
    -sUSE_WEBGL2=1

    # WebGL 2 is enough for most modern browser rendering.
    -sMIN_WEBGL_VERSION=2

    # Better browser filesystem compatibility.
    -sALLOW_MEMORY_GROWTH=1

    # Don't require pthreads.
    -sPTHREAD_POOL_SIZE=0

    # Export the runtime methods commonly useful to JS.
    -sEXPORTED_RUNTIME_METHODS=["ccall","cwrap"]

    # Output HTML.
    --shell-file ${CMAKE_CURRENT_SOURCE_DIR}/shell.html
)

# ------------------------------------------------------------
# Emscripten compile options
# ------------------------------------------------------------

target_compile_options(RetroEngine PRIVATE
    -pthread
)

# ------------------------------------------------------------
# Optional MiniAudio
# ------------------------------------------------------------

if(USE_MINIAUDIO)
    target_compile_definitions(RetroEngine PRIVATE
        RETRO_AUDIODEVICE_MINI=1
    )
endif()

# ------------------------------------------------------------
# Warnings
# ------------------------------------------------------------

if(CMAKE_CXX_COMPILER_ID STREQUAL "Clang" OR
   CMAKE_CXX_COMPILER_ID STREQUAL "GNU")

    target_compile_options(RetroEngine PRIVATE
        -Wno-microsoft-cast
        -Wno-microsoft-exception-spec
    )

endif()