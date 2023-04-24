# The following lines of boilerplate have to be in your project's
# CMakeLists in this exact order for cmake to work correctly
cmake_minimum_required(VERSION 3.16)

set(GENERATED_DIR ${CMAKE_SOURCE_DIR}/generated) 
set(MODEL_DIR ${CMAKE_SOURCE_DIR}/model) 
set(SCRIPT_DIR ${CMAKE_SOURCE_DIR}/script)
file(GLOB MODEL_SRC CONFIGURE_DEPENDS "${MODEL_DIR}/*.xml")
file(MAKE_DIRECTORY ${GENERATED_DIR})

include($ENV{IDF_PATH}/tools/cmake/project.cmake)
project(alarma)

include_directories(${GENERATED_DIR}) 

foreach (XML ${MODEL_SRC})
    string(REGEX REPLACE "/model/" "/generated/" XML_GEN ${XML})
    string(REGEX REPLACE "[.]xml$" ".hh" MODEL_HH ${XML_GEN})
    set(GENERATED_HH ${GENERATED_HH} ${MODEL_HH})
endforeach ()

add_custom_command(OUTPUT ${GENERATED_HH}
    COMMAND python ${SCRIPT_DIR}/pt2cpp.py ${MODEL_SRC}
    DEPENDS ${MODEL_SRC}
)

add_custom_target(gen_hh DEPENDS ${GENERATED_HH})
set_property(TARGET ${PROJECT_NAME}.elf APPEND
    PROPERTY ADDITIONAL_CLEAN_FILES ${GENERATED_HH})

add_dependencies(${PROJECT_NAME}.elf gen_hh)
