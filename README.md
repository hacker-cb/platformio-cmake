# Set of PlatformIO CMake wrappers to use with cmake-based IDEs (CLion, ...)

## Usage:

Create `CMakeListsUser.txt` with the following content:

```cmake
# PlatformIO Environment parser
include(platformio-cmake/PlatformIO_Env.cmake)

# PlatformIO CTest Wrappers
include(platformio-cmake/PlatformIO_CTest.cmake)

# Filter all source files
include(platformio-cmake/PlatformIO_FilterSources.cmake)
```