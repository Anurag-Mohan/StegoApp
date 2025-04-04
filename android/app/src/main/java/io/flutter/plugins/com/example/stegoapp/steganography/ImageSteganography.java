package com.example.stegoapp.steganography;

import android.content.Context;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.util.Log;

import java.io.ByteArrayOutputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.util.concurrent.CountDownLatch;
import java.util.*;
import java.util.concurrent.TimeUnit;

public class ImageSteganography {
    private static final String TAG = "ImageSteganography";
    private final Context context;
    private final TextSteganography textSteganography;

    public ImageSteganography(Context context, TextSteganography textSteganography) {
        this.context = context;
        this.textSteganography = textSteganography;
    }

    public TextSteganography getTextSteganography() {
        return textSteganography;
    }

    public String hideImageInImage(String secretImageUri, String carrierUri) {
        try {
            Bitmap secretBitmap = loadBitmap(secretImageUri);
            Bitmap carrierBitmap = loadBitmap(carrierUri);
            
            ByteArrayOutputStream stream = new ByteArrayOutputStream();
            secretBitmap.compress(Bitmap.CompressFormat.PNG, 100, stream);
            byte[] secretData = stream.toByteArray();
            secretBitmap.recycle();
            
            return hideBinaryInImage(secretData, carrierBitmap);
        } catch (Exception e) {
            Log.e(TAG, "Error hiding image in image", e);
            return "Error: " + e.getMessage();
        }
    }

    public Bitmap extractImageFromImage(String carrierUri) {
        try {
            byte[] imageData = extractBinaryFromImage(carrierUri);
            return BitmapFactory.decodeByteArray(imageData, 0, imageData.length);
        } catch (Exception e) {
            Log.e(TAG, "Error extracting image from image", e);
            return null;
        }
    }

    private String hideBinaryInImage(byte[] data, Bitmap carrierBitmap) throws IOException {
        int width = carrierBitmap.getWidth();
        int height = carrierBitmap.getHeight();
        int pixelCount = width * height;
        
        byte[] dataToHide = textSteganography.ultraCompress(data);
        int dataLength = dataToHide.length;
        
        int bitsAvailable = (pixelCount - TextSteganography.LENGTH_BITS) * 3;
        if (dataLength * 8 > bitsAvailable) {
            carrierBitmap.recycle();
            throw new IOException("Image too small for data");
        }
        
        ByteBuffer pixelBuffer = ByteBuffer.allocateDirect(pixelCount * 4);
        pixelBuffer.order(ByteOrder.nativeOrder());
        carrierBitmap.copyPixelsToBuffer(pixelBuffer);
        carrierBitmap.recycle();
        pixelBuffer.rewind();
        
        for (int i = 0; i < TextSteganography.LENGTH_BITS; i++) {
            int pos = i * 4;
            byte r = pixelBuffer.get(pos + 2);
            r = (byte)((r & 0xFE) | ((dataLength >> i) & 1));
            pixelBuffer.put(pos + 2, r);
        }
        
        int dataBits = dataLength * 8;
        int bitsPerThread = (dataBits + TextSteganography.THREAD_COUNT - 1) / TextSteganography.THREAD_COUNT;
        CountDownLatch latch = new CountDownLatch(TextSteganography.THREAD_COUNT);
        
        for (int t = 0; t < TextSteganography.THREAD_COUNT; t++) {
            final int startBit = t * bitsPerThread;
            final int endBit = Math.min((t + 1) * bitsPerThread, dataBits);
            
            textSteganography.executor.execute(() -> {
                try {
                    textSteganography.embedDataParallel(pixelBuffer, dataToHide, TextSteganography.LENGTH_BITS, startBit, endBit);
                } finally {
                    latch.countDown();
                }
            });
        }
        
        try {
            latch.await(10, TimeUnit.SECONDS);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        }
        
        pixelBuffer.rewind();
        Bitmap resultBitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888);
        resultBitmap.copyPixelsFromBuffer(pixelBuffer);
        
        String outputPath = textSteganography.createTempFile("png");
        try (FileOutputStream fos = new FileOutputStream(outputPath)) {
            resultBitmap.compress(Bitmap.CompressFormat.PNG, 100, fos);
            fos.flush();
        }
        
        resultBitmap.recycle();
        return outputPath;
    }

    private byte[] extractBinaryFromImage(String carrierUri) throws IOException {
        Bitmap carrierBitmap = loadBitmap(carrierUri);
        int width = carrierBitmap.getWidth();
        int height = carrierBitmap.getHeight();
        int pixelCount = width * height;
        
        ByteBuffer pixelBuffer = ByteBuffer.allocateDirect(pixelCount * 4);
        pixelBuffer.order(ByteOrder.nativeOrder());
        carrierBitmap.copyPixelsToBuffer(pixelBuffer);
        carrierBitmap.recycle();
        pixelBuffer.rewind();
        
        int dataLength = 0;
        for (int i = 0; i < TextSteganography.LENGTH_BITS; i++) {
            int pos = i * 4;
            byte r = pixelBuffer.get(pos + 2);
            int bit = r & 1;
            dataLength |= (bit << i);
        }
        
        int maxPossibleLength = (pixelCount - TextSteganography.LENGTH_BITS) * 3 / 8;
        if (dataLength <= 0 || dataLength > maxPossibleLength) {
            throw new IOException("Invalid data length");
        }
        
        byte[] extractedData = new byte[dataLength];
        int dataBits = dataLength * 8;
        int bitsPerThread = (dataBits + TextSteganography.THREAD_COUNT - 1) / TextSteganography.THREAD_COUNT;
        CountDownLatch latch = new CountDownLatch(TextSteganography.THREAD_COUNT);
        
        for (int t = 0; t < TextSteganography.THREAD_COUNT; t++) {
            final int startBit = t * bitsPerThread;
            final int endBit = Math.min((t + 1) * bitsPerThread, dataBits);
            
            textSteganography.executor.execute(() -> {
                try {
                    textSteganography.extractDataParallel(pixelBuffer, extractedData, TextSteganography.LENGTH_BITS, startBit, endBit);
                } finally {
                    latch.countDown();
                }
            });
        }
        
        try {
            latch.await(10, TimeUnit.SECONDS);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        }
        
        return textSteganography.ultraDecompress(extractedData);
    }

    protected Bitmap loadBitmap(String uriString) throws IOException {
        return textSteganography.loadBitmap(uriString);
    }

    public String saveBitmapToTempFile(Bitmap bitmap) throws IOException {
        String outputPath = textSteganography.createTempFile("png");
        try (FileOutputStream fos = new FileOutputStream(outputPath)) {
            bitmap.compress(Bitmap.CompressFormat.PNG, 100, fos);
            fos.flush();
        }
        return outputPath;
    }
}
