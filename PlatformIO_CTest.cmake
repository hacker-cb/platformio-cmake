###############################################################################
#
# PlatformIO wrapper to run PlatformIO tests in JetBrains CLion IDE
#
###############################################################################

if (NOT PlatformIO_Env_INCLUDED)
    message(FATAL_ERROR "Please include this file after `PlatformIO_Env.cmake`")
endif ()

#
# Output of the `platformio test --list-tests` command:
#
# ======================================================================================
# Environment               Test                                   Status    Duration
# ------------------------  -------------------------------------  --------  ----------
# test-native               common/crypto/test_xor128              SKIPPED
# test-native               common/transport/test_simple_router    SKIPPED
# ...
# ======================================================================================

# Execute `platformio test --list-tests` to get the list of available tests
# Parse columns `Environment` and `Test` to get the list of available tests
#   `Environment` save to variable `TEST_ENVIRONMENT`
#   `Test` save to variable `TEST_NAME`

enable_testing()

set(PIO_TEST_EXTRA_FLAGS "-v" CACHE STRING "Extra arguments for `platformio test` command")

# Set custom variables
if(EXISTS ${PIO_PROJECT_DIR}/PlatformIO_CTest_Custom.cmake)
    include(${PIO_PROJECT_DIR}/PlatformIO_CTest_Custom.cmake)
endif()

###############################################################################
# Save content of the `platformio test --list-tests` command to the file
###############################################################################
set(PIO_LIST_TESTS_OUTPUT_FILE ${CMAKE_CURRENT_BINARY_DIR}/pio_list_tests_output.txt)
execute_process(
  COMMAND ${PIO_COMMAND} test --list-tests
  OUTPUT_FILE ${PIO_LIST_TESTS_OUTPUT_FILE}
  RESULT_VARIABLE PIO_LIST_TESTS_RESULT
  WORKING_DIRECTORY ${PIO_PROJECT_DIR}
)
if (NOT PIO_LIST_TESTS_RESULT EQUAL 0)
    message(FATAL_ERROR "PlatformIO test --list-tests failed")
endif()

file(STRINGS ${PIO_LIST_TESTS_OUTPUT_FILE} TESTS_OUTPUT_CONTENT)

set(CURRENT_ENV_TESTS, "")

set(TESTS_CONTENT_START 0)
foreach(TEST_LINE ${TESTS_OUTPUT_CONTENT})
    # Skip until line starts from `-----`
    if(TEST_LINE MATCHES "^-----")
        set(TESTS_CONTENT_START 1)
    endif()

    if(TEST_LINE MATCHES "^=====" AND TESTS_CONTENT_START)
        set(TESTS_CONTENT_START 0)
    endif()


    if (NOT TESTS_CONTENT_START)
        continue()
    endif ()


    # Split line to columns using one or more spaces as delimiter
    string(REGEX REPLACE " +" ";" TEST_LINE_COLUMNS ${TEST_LINE})
    list(GET TEST_LINE_COLUMNS 0 TEST_ENVIRONMENT)
    list(GET TEST_LINE_COLUMNS 1 TEST_NAME)

    # Ensure test environment matches to the current environment
    if ("${TEST_ENVIRONMENT}" STREQUAL "${PIO_ENV}")
        list(APPEND CURRENT_ENV_TESTS ${TEST_NAME})
    else()
#        message(STATUS "[PlatformIO_CTest] Skip test: ${TEST_ENVIRONMENT} -> ${TEST_NAME}")
    endif()

endforeach()

###############################################################################
# Add tests
###############################################################################
list(SORT CURRENT_ENV_TESTS)
foreach(TEST_NAME ${CURRENT_ENV_TESTS})
    #
    # Match filter
    #
    set(MATCH_FILTER 0)
    if (PIO_ENV_OPTIONS_TEST_FILTER)
        # Strip any number of trailing '*' from the filter
        foreach(FILTER ${PIO_ENV_OPTIONS_TEST_FILTER})
            # Strip any number of trailing '*' from the filter
            string(REGEX REPLACE "\\*+$" "" FILTER ${FILTER})
            if (${TEST_NAME} MATCHES "^${FILTER}")
                set(MATCH_FILTER 1)
                break()
            endif()
        endforeach()
    else()
        set(MATCH_FILTER 1)
    endif()

    #
    # Match ignore
    #
    set(MATCH_IGNORE 0)
    if (PIO_ENV_OPTIONS_TEST_IGNORE)
        foreach(TEST_IGNORE ${PIO_ENV_OPTIONS_TEST_IGNORE})
            # Strip any number of trailing '*' from the filter
            string(REGEX REPLACE "\\*+$" "" TEST_IGNORE ${TEST_IGNORE})
            if (${TEST_NAME} MATCHES "^${TEST_IGNORE}")
                set(MATCH_IGNORE 1)
                break()
            endif()
        endforeach()
    endif()

    #
    # Add tests
    #
    if (MATCH_FILTER EQUAL 1)
        if (MATCH_IGNORE EQUAL 1)
            message(STATUS "[PlatformIO_CTest] Ignore test: ${PIO_ENV} -> ${TEST_NAME}")
        else()
            message(STATUS "[PlatformIO_CTest] Add test: ${PIO_ENV} -> ${TEST_NAME} (${PIO_TEST_EXTRA_FLAGS})")
            add_test(NAME ${TEST_NAME}
                    COMMAND ${PIO_COMMAND} test ${PIO_TEST_EXTRA_FLAGS} -e ${PIO_ENV} -f ${TEST_NAME}
                    WORKING_DIRECTORY ${PIO_PROJECT_DIR}
                    )
        endif()
    else()
        message(STATUS "[PlatformIO_CTest] Skip test: ${PIO_ENV} -> ${TEST_NAME}")
    endif()
endforeach()
