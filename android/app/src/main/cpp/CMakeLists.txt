cmake_minimum_required(VERSION 3.10.2)
project("llama-jni")

# Establecemos estándares de C++17
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Agrega la biblioteca compartida JNI para conectar Kotlin con llama.cpp
add_library(llama-jni SHARED llama-jni.cpp)

# Busca y enlaza la biblioteca de registros (log) de Android
find_library(log-lib log)

# Enlaza las librerías necesarias
target_link_libraries(
    llama-jni
    ${log-lib}
)
