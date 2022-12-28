###############################################################################
#
# PlatformIO project configuration parser
#
# PIO_PROJECT_DIR       - project directory
# PIO_ENV               - environment name
# PIO_ENV_OPTIONS_xxxx  - value of the current environment option
#
###############################################################################

cmake_minimum_required(VERSION 3.19) # string(JSON ...) requires 3.19


set(PIO_PROJECT_DIR ${PROJECT_SOURCE_DIR})
set(PIO_ENV ${CMAKE_BUILD_TYPE})
set(PlatformIO_Env_INCLUDED TRUE)


message(STATUS "Current environment: ${PIO_ENV}")


# Find platformio executable
find_program(PIO_COMMAND platformio PATHS $ENV{HOME}/.platformio/bin/)
if (PIO_COMMAND STREQUAL "PIO_COMMAND-NOTFOUND")
    message(FATAL_ERROR "PlatformIO executable not found")
endif ()

###############################################################################
#
# Save content of the `pio project config --json-output` command to the file
#
###############################################################################
execute_process(
        COMMAND ${PIO_COMMAND} project config --json-output
        WORKING_DIRECTORY ${PIO_PROJECT_DIR}
        OUTPUT_VARIABLE PIO_PROJECT_CONFIG_JSON
        RESULT_VARIABLE PIO_PROJECT_CONFIG_RESULT
)
if (NOT PIO_PROJECT_CONFIG_RESULT EQUAL 0)
    message(FATAL_ERROR "Failed to get project configuration")
endif ()

###############################################################################
# Get project options for current environment
# PIO_ENV_OPTIONS_xxxx will be set
###############################################################################
set(_PIO_ENV_OPTIONS_PREFIX "PIO_ENV_OPTIONS_")

set(ENV_IDX 0)
while(1)
    string(JSON ENV_CONFIG_ARR ERROR_VARIABLE ENV_CONFIG_ARR_ERR GET ${PIO_PROJECT_CONFIG_JSON} ${ENV_IDX})
    if (NOT ENV_CONFIG_ARR_ERR STREQUAL "NOTFOUND")
        break()
    endif ()
    # message(STATUS "ENV_CONFIG_ARR_ERR: ${ENV_CONFIG_ARR_ERR}")
    # message(STATUS "ENV_CONFIG_ARR: ${ENV_CONFIG_ARR}")

    string(JSON ENV_NAME ERROR_VARIABLE ENV_NAME_ERR GET ${ENV_CONFIG_ARR} 0) # String
    string(JSON ENV_OPTIONS GET ${ENV_CONFIG_ARR} 1) # Array

    if (ENV_NAME STREQUAL "env:${CMAKE_BUILD_TYPE}")
        # message(STATUS "ENV_NAME: ${ENV_NAME}") # DEBUG
        # message(STATUS "ENV_OPTIONS: ${ENV_OPTIONS}") # DEBUG

        # Loop over options
        set(OPT_IDX 0)
        while(1)
            string(JSON OPT_CONFIG_ARR ERROR_VARIABLE OPT_CONFIG_ARR_ERR GET ${ENV_OPTIONS} ${OPT_IDX})
            if (NOT OPT_CONFIG_ARR_ERR STREQUAL "NOTFOUND")
                break()
            endif()
            # message(STATUS "OPT_CONFIG_ARR: ${OPT_CONFIG_ARR}") # DEBUG

            string(JSON OPT_NAME ERROR_VARIABLE ENV_NAME_ERR GET ${OPT_CONFIG_ARR} 0) # String
            string(JSON OPT_VALUE_TYPE TYPE ${OPT_CONFIG_ARR} 1) # Array or String
            string(JSON OPT_VALUE GET ${OPT_CONFIG_ARR} 1) # MIXED

            #message(STATUS "OPT_NAME: ${OPT_NAME}, OPT_VALUE_TYPE: ${OPT_VALUE_TYPE}") # DEBUG
            #message(STATUS "OPT_VALUE: ${OPT_VALUE}") # DEBUG

            if (OPT_VALUE_TYPE STREQUAL "ARRAY")
                set(ARR_VALUE_LIST "")
                set(ARR_VALUE_IDX 0)
                while(1)
                    string(JSON ARR_VALUE ERROR_VARIABLE ARR_VALUE_ERR GET ${OPT_VALUE} ${ARR_VALUE_IDX})
                    if (NOT ARR_VALUE_ERR STREQUAL "NOTFOUND")
                        break()
                    endif()
                    # message(STATUS "ARR_VALUE: ${ARR_VALUE}") # DEBUG
                    list(APPEND ARR_VALUE_LIST ${ARR_VALUE})
                    math(EXPR ARR_VALUE_IDX "${ARR_VALUE_IDX} + 1")
                endwhile()
                set(OPT_VALUE "${ARR_VALUE_LIST}")
            endif()

            # set option to upper case and replace '-' to '_'
            string(REPLACE "-" "_" OPT_NAME ${OPT_NAME})
            string(TOUPPER ${OPT_NAME} OPT_NAME)

            message(STATUS "[PlatformIO_Env] Env option: ${_PIO_ENV_OPTIONS_PREFIX}${OPT_NAME} = ${OPT_VALUE}")
            set(${_PIO_ENV_OPTIONS_PREFIX}${OPT_NAME} ${OPT_VALUE} CACHE INTERNAL "")

            math(EXPR OPT_IDX "${OPT_IDX} + 1")
        endwhile()
    endif()

    if (ENV_IDX EQUAL 7)
        break()
    endif ()

    math(EXPR ENV_IDX "${ENV_IDX} + 1")
endwhile()