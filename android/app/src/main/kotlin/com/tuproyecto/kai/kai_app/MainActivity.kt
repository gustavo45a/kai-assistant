package com.tuproyecto.kai.kai_app

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.EventChannel
import android.os.Handler
import android.os.Looper
import android.util.Log
import java.io.*

class MainActivity: FlutterActivity() {
    private val TAG = "KAI_MAIN"
    private val METHOD_CHANNEL = "com.tuproyecto.kai.kai_app/ia_local"
    private val EVENT_CHANNEL = "com.tuproyecto.kai.kai_app/llama_event"
    
    private var modelFile: File? = null
    private var nativeContextPtr: Long = 0
    private var isNativeLibraryLoaded = false
    
    // Firmas JNI Nativas de Llama.cpp
    private external fun loadModelNative(modelPath: String): Long
    private external fun freeModelNative()
    private external fun generateTokenNative(prompt: String): String
    
    init {
        try {
            System.loadLibrary("llama-jni")
            isNativeLibraryLoaded = true
            Log.i(TAG, "Llama-JNI: Biblioteca nativa cargada con éxito.")
        } catch (e: UnsatisfiedLinkError) {
            Log.e(TAG, "Llama-JNI: No se pudo cargar la biblioteca nativa: ${e.message}")
            isNativeLibraryLoaded = false
        }
    }
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, METHOD_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "initModel" -> {
                    val path = call.argument<String>("path")
                    if (path == null) {
                        result.error("INVALID_PATH", "La ruta del modelo no puede ser nula", null)
                        return@setMethodCallHandler
                    }
                    try {
                        val file = File(path)
                        if (!file.exists()) {
                            result.error("FILE_NOT_FOUND", "No se encontró el archivo en: $path", null)
                            return@setMethodCallHandler
                        }
                        modelFile = file
                        
                        if (isNativeLibraryLoaded) {
                            nativeContextPtr = loadModelNative(path)
                            val resultMap = mapOf(
                                "status" to "loaded",
                                "nativePointer" to nativeContextPtr,
                                "message" to "Modelo cargado en dirección de memoria nativa real C++"
                            )
                            result.success(resultMap)
                        } else {
                            result.error("NATIVE_LIB_NOT_LOADED", "La biblioteca C++ JNI (llama-jni) no está compilada en tu entorno local. Instala el NDK de Android para compilarla.", null)
                        }
                    } catch (e: Exception) {
                        result.error("INIT_FAILED", "Error al inicializar el modelo nativo: ${e.message}", null)
                    }
                }
                "generateNativeResponse" -> {
                    val prompt = call.argument<String>("prompt") ?: ""
                    if (!isNativeLibraryLoaded || nativeContextPtr == 0L) {
                        result.error("MODEL_NOT_LOADED", "El motor nativo JNI de Llama no ha sido cargado.", null)
                        return@setMethodCallHandler
                    }
                    
                    try {
                        val response = generateTokenNative(prompt)
                        result.success(response)
                    } catch (e: Exception) {
                        result.error("INFERENCE_FAILED", "Error durante la inferencia nativa C++: ${e.message}", null)
                    }
                }
                else -> result.notImplemented()
            }
        }
        
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL).setStreamHandler(object : EventChannel.StreamHandler {
            private var eventSink: EventChannel.EventSink? = null
            private val handler = Handler(Looper.getMainLooper())
            
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                eventSink = events
                val prompt = arguments as? String ?: ""
                
                if (!isNativeLibraryLoaded || nativeContextPtr == 0L) {
                    eventSink?.error("MODEL_NOT_LOADED", "Debe inicializar el motor nativo primero", null)
                    eventSink?.endOfStream()
                    return
                }
                
                Thread {
                    try {
                        // Generación real a través del JNI C++
                        val response = generateTokenNative(prompt)
                        val words = response.split(" ")
                        for (word in words) {
                            Thread.sleep(80) // Streaming visual progresivo
                            handler.post {
                                eventSink?.success("$word ")
                            }
                        }
                    } catch (e: Exception) {
                        handler.post {
                            eventSink?.error("STREAM_ERROR", e.message, null)
                        }
                    } finally {
                        handler.post {
                            eventSink?.endOfStream()
                        }
                    }
                }.start()
            }
            
            override fun onCancel(arguments: Any?) {
                eventSink = null
            }
        })
    }
}
