# PlatformIO CMake wrappers

Set of PlatformIO CMake wrappers to use with cmake-based IDEs (CLion, ...)

## Usage:

* Add this repository as a submodule to your project:

```bash
git submodule add https://github.com/hacker-cb/platformio-cmake.git
```

* Create `CMakeListsUser.txt` with the following content:

```cmake
# PlatformIO Environment parser
include(platformio-cmake/PlatformIO_Env.cmake)

# PlatformIO CTest Wrappers
include(platformio-cmake/PlatformIO_CTest.cmake)

# Filter all source files
include(platformio-cmake/PlatformIO_FilterSources.cmake)
```