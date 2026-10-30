package com.ahni.ahni_mobile

import android.graphics.Rect
import android.net.Uri
import com.google.mlkit.vision.common.InputImage
import com.google.mlkit.vision.text.TextRecognition
import com.google.mlkit.vision.text.korean.KoreanTextRecognizerOptions
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity: FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "ahni/grade_ocr").setMethodCallHandler { call, result ->
            val path = call.argument<String>("path")
            if (call.method != "recognize") { result.notImplemented(); return@setMethodCallHandler }
            if (path == null) { result.error("invalid_path", "Image path is missing", null); return@setMethodCallHandler }
            val recognizer = TextRecognition.getClient(KoreanTextRecognizerOptions.Builder().build())
            try {
                val image = InputImage.fromFilePath(this, Uri.fromFile(File(path)))
                fun row(text: String, rect: Rect): Map<String, Any> = mapOf("text" to text, "left" to rect.left, "top" to rect.top, "right" to rect.right, "bottom" to rect.bottom)
                recognizer.process(image).addOnSuccessListener { recognized ->
                    val lines = recognized.textBlocks.flatMap { it.lines }
                    val lineRows = lines.mapNotNull { line -> line.boundingBox?.let { row(line.text, it) } }
                    val fragments = lines.flatMap { line ->
                        val elements = line.elements.mapNotNull { element -> element.boundingBox?.let { row(element.text, it) } }
                        if (elements.isEmpty()) listOfNotNull(line.boundingBox?.let { row(line.text, it) }) else elements
                    }
                    result.success(mapOf("text" to recognized.text, "lines" to lineRows, "fragments" to fragments))
                }.addOnFailureListener { result.error("ocr_failed", "OCR failed", null) }
                    .addOnCompleteListener { recognizer.close() }
            } catch (e: Exception) {
                recognizer.close()
                result.error("ocr_failed", "OCR failed", null)
            }
        }
    }
}
