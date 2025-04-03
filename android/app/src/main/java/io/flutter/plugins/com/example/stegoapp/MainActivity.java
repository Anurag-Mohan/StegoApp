package com.example.stegoapp;

import androidx.annotation.NonNull;
import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodCall;
import android.content.Context;
import android.graphics.Bitmap;
import android.util.Log;

import java.util.HashMap;
import java.util.Map;

public class MainActivity extends FlutterActivity {
    private static final String CHANNEL = "com.example.stegoapp/UltraFastSteganography";
    private UltraFastSteganography steganographyManager;

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);
        
        steganographyManager = new UltraFastSteganography(getContext());
        
        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL)
            .setMethodCallHandler(
                (call, result) -> {
                    handleMethodCall(call, result);
                }
            );
    }
    
    private void handleMethodCall(MethodCall call, MethodChannel.Result result) {
        switch (call.method) {
            case "hideTextInImage":
                handleHideTextInImage(call, result);
                break;
            case "extractTextFromImage":
                handleExtractTextFromImage(call, result);
                break;
            case "hideImageInImage":
                handleHideImageInImage(call, result);
                break;
            case "extractImageFromImage":
                handleExtractImageFromImage(call, result);
                break;
            case "hideImageInVideo":
                handleHideImageInVideo(call, result);
                break;
            case "extractImageFromVideo":
                handleExtractImageFromVideo(call, result);
                break;
            default:
                result.notImplemented();
                break;
        }
    }
    
    // ============== EXISTING TEXT METHODS (UNCHANGED) ==============
    private void handleHideTextInImage(MethodCall call, MethodChannel.Result result) {
        try {
            String text = call.argument("text");
            String carrierUri = call.argument("carrierUri");
            
            if (text == null || carrierUri == null) {
                Map<String, Object> response = new HashMap<>();
                response.put("success", false);
                response.put("error", "Missing required parameters");
                result.success(response);
                return;
            }
            
            String outputPath = steganographyManager.hideTextInImage(text, carrierUri);
            
            if (outputPath.startsWith("Error:")) {
                Map<String, Object> response = new HashMap<>();
                response.put("success", false);
                response.put("error", outputPath.substring(7));
                result.success(response);
            } else {
                Map<String, Object> response = new HashMap<>();
                response.put("success", true);
                response.put("path", outputPath);
                result.success(response);
            }
        } catch (Exception e) {
            Log.e("UltraFastSteganography", "Error hiding text in image", e);
            Map<String, Object> response = new HashMap<>();
            response.put("success", false);
            response.put("error", e.getMessage());
            result.success(response);
        }
    }
    
    private void handleExtractTextFromImage(MethodCall call, MethodChannel.Result result) {
        try {
            String carrierUri = call.argument("carrierUri");
            
            if (carrierUri == null) {
                Map<String, Object> response = new HashMap<>();
                response.put("success", false);
                response.put("error", "Missing required parameters");
                result.success(response);
                return;
            }
            
            String extractedText = steganographyManager.extractTextFromImage(carrierUri);
            
            if (extractedText.startsWith("Error:")) {
                Map<String, Object> response = new HashMap<>();
                response.put("success", false);
                response.put("error", extractedText.substring(7));
                result.success(response);
            } else {
                Map<String, Object> response = new HashMap<>();
                response.put("success", true);
                response.put("text", extractedText);
                result.success(response);
            }
        } catch (Exception e) {
            Log.e("UltraFastSteganography", "Error extracting text from image", e);
            Map<String, Object> response = new HashMap<>();
            response.put("success", false);
            response.put("error", e.getMessage());
            result.success(response);
        }
    }
    
    // ============== NEW IMAGE-IN-IMAGE METHODS ==============
    private void handleHideImageInImage(MethodCall call, MethodChannel.Result result) {
        try {
            String secretImageUri = call.argument("secretImageUri");
            String carrierUri = call.argument("carrierUri");
            
            if (secretImageUri == null || carrierUri == null) {
                Map<String, Object> response = new HashMap<>();
                response.put("success", false);
                response.put("error", "Missing required parameters");
                result.success(response);
                return;
            }
            
            String outputPath = steganographyManager.hideImageInImage(secretImageUri, carrierUri);
            
            if (outputPath.startsWith("Error:")) {
                Map<String, Object> response = new HashMap<>();
                response.put("success", false);
                response.put("error", outputPath.substring(7));
                result.success(response);
            } else {
                Map<String, Object> response = new HashMap<>();
                response.put("success", true);
                response.put("path", outputPath);
                result.success(response);
            }
        } catch (Exception e) {
            Log.e("UltraFastSteganography", "Error hiding image in image", e);
            Map<String, Object> response = new HashMap<>();
            response.put("success", false);
            response.put("error", e.getMessage());
            result.success(response);
        }
    }
    
    private void handleExtractImageFromImage(MethodCall call, MethodChannel.Result result) {
        try {
            String carrierUri = call.argument("carrierUri");
            
            if (carrierUri == null) {
                Map<String, Object> response = new HashMap<>();
                response.put("success", false);
                response.put("error", "Missing required parameters");
                result.success(response);
                return;
            }
            
            Bitmap extractedImage = steganographyManager.extractImageFromImage(carrierUri);
            
            if (extractedImage == null) {
                Map<String, Object> response = new HashMap<>();
                response.put("success", false);
                response.put("error", "Failed to extract image");
                result.success(response);
            } else {
                // Convert bitmap to file and return path
                String outputPath = steganographyManager.saveBitmapToTempFile(extractedImage);
                Map<String, Object> response = new HashMap<>();
                response.put("success", true);
                response.put("path", outputPath);
                result.success(response);
                extractedImage.recycle();
            }
        } catch (Exception e) {
            Log.e("UltraFastSteganography", "Error extracting image from image", e);
            Map<String, Object> response = new HashMap<>();
            response.put("success", false);
            response.put("error", e.getMessage());
            result.success(response);
        }
    }
    
    // ============== NEW IMAGE-IN-VIDEO METHODS ==============
    private void handleHideImageInVideo(MethodCall call, MethodChannel.Result result) {
        try {
            String secretImageUri = call.argument("secretImageUri");
            String carrierVideoUri = call.argument("carrierVideoUri");
            
            if (secretImageUri == null || carrierVideoUri == null) {
                Map<String, Object> response = new HashMap<>();
                response.put("success", false);
                response.put("error", "Missing required parameters");
                result.success(response);
                return;
            }
            
            String outputPath = steganographyManager.hideImageInVideo(secretImageUri, carrierVideoUri);
            
            if (outputPath.startsWith("Error:")) {
                Map<String, Object> response = new HashMap<>();
                response.put("success", false);
                response.put("error", outputPath.substring(7));
                result.success(response);
            } else {
                Map<String, Object> response = new HashMap<>();
                response.put("success", true);
                response.put("path", outputPath);
                result.success(response);
            }
        } catch (Exception e) {
            Log.e("UltraFastSteganography", "Error hiding image in video", e);
            Map<String, Object> response = new HashMap<>();
            response.put("success", false);
            response.put("error", e.getMessage());
            result.success(response);
        }
    }
    
    private void handleExtractImageFromVideo(MethodCall call, MethodChannel.Result result) {
        try {
            String carrierVideoUri = call.argument("carrierVideoUri");
            
            if (carrierVideoUri == null) {
                Map<String, Object> response = new HashMap<>();
                response.put("success", false);
                response.put("error", "Missing required parameters");
                result.success(response);
                return;
            }
            
            Bitmap extractedImage = steganographyManager.extractImageFromVideo(carrierVideoUri);
            
            if (extractedImage == null) {
                Map<String, Object> response = new HashMap<>();
                response.put("success", false);
                response.put("error", "Failed to extract image");
                result.success(response);
            } else {
                // Convert bitmap to file and return path
                String outputPath = steganographyManager.saveBitmapToTempFile(extractedImage);
                Map<String, Object> response = new HashMap<>();
                response.put("success", true);
                response.put("path", outputPath);
                result.success(response);
                extractedImage.recycle();
            }
        } catch (Exception e) {
            Log.e("UltraFastSteganography", "Error extracting image from video", e);
            Map<String, Object> response = new HashMap<>();
            response.put("success", false);
            response.put("error", e.getMessage());
            result.success(response);
        }
    }
    
    @Override
    public void onDestroy() {
        if (steganographyManager != null) {
            steganographyManager.cleanup();
        }
        super.onDestroy();
    }
}