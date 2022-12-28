#
# Filter SRC_LIST to match only *.h/*.hpp/*.c/*.cpp/*.ino files
#
list(FILTER SRC_LIST INCLUDE REGEX "\\.(c|cpp|cxx|cc|hpp|ino|h)$")