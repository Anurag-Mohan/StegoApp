package com.example.stegoapp.steganography;

import android.content.Context;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.net.Uri;
import android.util.Log;

import net.jpountz.lz4.LZ4Factory;
import net.jpountz.lz4.LZ4FastDecompressor;
import net.jpountz.lz4.LZ4Compressor;

import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.nio.charset.StandardCharsets;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.TimeUnit;
import java.io.*;







import android.content.Context;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.net.Uri;
import android.util.Log;

import net.jpountz.lz4.LZ4Factory;
import net.jpountz.lz4.LZ4FastDecompressor;
import net.jpountz.lz4.LZ4Compressor;

import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.nio.charset.StandardCharsets;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.TimeUnit;


public class TextSteganography {
    private static final String TAG = "TextSteganography";
    private final Context context;
    public final ExecutorService executor;
    public static final int THREAD_COUNT = Runtime.getRuntime().availableProcessors() * 2;
    public static final int LENGTH_BITS = 32;
    private final LZ4Factory lz4Factory;

    public TextSteganography(Context context, ExecutorService executor, LZ4Factory lz4Factory) {
        this.context = context;
        this.executor = executor;
        this.lz4Factory = lz4Factory;
    }

    public String hideTextInImage(String text, String carrierUri) {
        long startTime = System.nanoTime();
        try {
            String result = hideInImage(text, carrierUri);
            Log.d(TAG, "Hide operation took: " + (System.nanoTime() - startTime) / 1_000_000 + "ms");
            return result;
        } catch (Exception e) {
            Log.e(TAG, "Error hiding text", e);
            return "Error: " + e.getMessage();
        }
    }

    public String extractTextFromImage(String carrierUri) {
        long startTime = System.nanoTime();
        try {
            String result = extractFromImage(carrierUri);
            Log.d(TAG, "Extract operation took: " + (System.nanoTime() - startTime) / 1_000_000 + "ms");
            return result;
        } catch (Exception e) {
            Log.e(TAG, "Error extracting text", e);
            return "Error: " + e.getMessage();
        }
    }

    private String hideInImage(String text, String carrierUri) throws IOException {
        BitmapFactory.Options options = new BitmapFactory.Options();
        options.inPreferredConfig = Bitmap.Config.ARGB_8888;
        options.inMutable = true;
        options.inSampleSize = 1;
        options.inJustDecodeBounds = false;
        
        Bitmap carrierBitmap = loadBitmap(carrierUri);
        
        if (carrierBitmap == null) {
            throw new IOException("Failed to decode image from: " + carrierUri);
        }
        
        int width = carrierBitmap.getWidth();
        int height = carrierBitmap.getHeight();
        int pixelCount = width * height;
        
        byte[] textBytes = text.getBytes(StandardCharsets.UTF_8);
        byte[] dataToHide = ultraCompress(textBytes);
        int dataLength = dataToHide.length;
        
        Log.d(TAG, "Hiding data with compression flag: " + (dataToHide[0] & 0xFF) + 
              ", total length: " + dataLength);

        int bitsAvailable = (pixelCount - LENGTH_BITS) * 3; 
        if (dataLength * 8 > bitsAvailable) {
            carrierBitmap.recycle();
            throw new IOException("Image too small for data. Need at least " + 
                              ((dataLength * 8 / 3) + LENGTH_BITS) + " pixels, but have " + pixelCount);
        }
        
        ByteBuffer pixelBuffer = ByteBuffer.allocateDirect(pixelCount * 4);
        pixelBuffer.order(ByteOrder.nativeOrder());
        carrierBitmap.copyPixelsToBuffer(pixelBuffer);
        carrierBitmap.recycle();
        pixelBuffer.rewind();
        
        Log.d(TAG, "Embedding data length: " + dataLength + " in pixels 0-" + (LENGTH_BITS-1));
        for (int i = 0; i < LENGTH_BITS; i++) {
            int pos = i * 4;
            byte r = pixelBuffer.get(pos + 2); 
            r = (byte)((r & 0xFE) | ((dataLength >> i) & 1));
            pixelBuffer.put(pos + 2, r);
        }
        
        int dataBits = dataLength * 8;
        int bitsPerThread = (dataBits + THREAD_COUNT - 1) / THREAD_COUNT;
        CountDownLatch latch = new CountDownLatch(THREAD_COUNT);
        
        for (int t = 0; t < THREAD_COUNT; t++) {
            final int threadIdx = t;
            final int startBit = t * bitsPerThread;
            final int endBit = Math.min((t + 1) * bitsPerThread, dataBits);
            
            executor.execute(() -> {
                try {
                    embedDataParallel(pixelBuffer, dataToHide, LENGTH_BITS, startBit, endBit);
                    Log.d(TAG, "Thread " + threadIdx + " completed embedding bits " + startBit + " to " + endBit);
                } catch (Exception e) {
                    Log.e(TAG, "Error in thread " + threadIdx, e);
                } finally {
                    latch.countDown();
                }
            });
        }
        
        try {
            if (!latch.await(10, TimeUnit.SECONDS)) {
                Log.w(TAG, "Embedding timed out, some threads did not complete");
            }
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        }
        
        pixelBuffer.rewind();
        
        byte[] verification = new byte[1];
        extractDataSingleThread(pixelBuffer, verification, LENGTH_BITS, 0, 8);
        
        Log.d(TAG, "Verification - Original: " + (dataToHide[0] & 0xFF) + 
              ", Extracted: " + (verification[0] & 0xFF));
              
        if ((verification[0] & 0xFF) != (dataToHide[0] & 0xFF)) {
            throw new IOException("Embedding verification failed - first byte mismatch. " +
                            "Original: " + (dataToHide[0] & 0xFF) + 
                            ", Extracted: " + (verification[0] & 0xFF));
        }
        
        pixelBuffer.rewind();
        Bitmap resultBitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888);
        resultBitmap.copyPixelsFromBuffer(pixelBuffer);
        
        String outputPath = createTempFile("png");
        try (FileOutputStream fos = new FileOutputStream(outputPath)) {
            if (!resultBitmap.compress(Bitmap.CompressFormat.PNG, 100, fos)) {
                throw new IOException("Failed to compress bitmap");
            }
            fos.flush();
        }
        
        Bitmap saved = BitmapFactory.decodeFile(outputPath);
        if (saved == null || saved.getWidth() != width || saved.getHeight() != height) {
            throw new IOException("Image dimensions changed after saving");
        }
        saved.recycle();
        resultBitmap.recycle();
        
        return outputPath;
    }

    private String extractFromImage(String carrierUri) throws IOException {
        BitmapFactory.Options options = new BitmapFactory.Options();
        options.inPreferredConfig = Bitmap.Config.ARGB_8888;
        options.inSampleSize = 1;
        
        Bitmap carrierBitmap = loadBitmap(carrierUri);
        
        if (carrierBitmap == null) {
            throw new IOException("Failed to decode image from: " + carrierUri);
        }
        
        int width = carrierBitmap.getWidth();
        int height = carrierBitmap.getHeight();
        int pixelCount = width * height;
        
        ByteBuffer pixelBuffer = ByteBuffer.allocateDirect(pixelCount * 4);
        pixelBuffer.order(ByteOrder.nativeOrder());
        carrierBitmap.copyPixelsToBuffer(pixelBuffer);
        carrierBitmap.recycle();
        pixelBuffer.rewind();
        
        int dataLength = 0;
        for (int i = 0; i < LENGTH_BITS; i++) {
            int pos = i * 4;
            byte r = pixelBuffer.get(pos + 2);
            int bit = r & 1;
            dataLength |= (bit << i);
        }

        Log.d(TAG, "Extracted data length: " + dataLength + " from image with " + pixelCount + " pixels");

        int maxPossibleLength = (pixelCount - LENGTH_BITS) * 3 / 8;
        if (dataLength <= 0 || dataLength > maxPossibleLength) {
            throw new IOException("Invalid data length detected: " + dataLength + 
                              ". This image may not contain valid steganographic data. Max possible: " + maxPossibleLength);
        }
        
        if (pixelCount < LENGTH_BITS + 10) {
            throw new IOException("Image too small to contain steganographic data");
        }
        
        byte[] extractedData = new byte[dataLength];
        int dataBits = dataLength * 8;
        int bitsPerThread = (dataBits + THREAD_COUNT - 1) / THREAD_COUNT;
        CountDownLatch latch = new CountDownLatch(THREAD_COUNT);
        
        for (int t = 0; t < THREAD_COUNT; t++) {
            final int threadIdx = t;
            final int startBit = t * bitsPerThread;
            final int endBit = Math.min((t + 1) * bitsPerThread, dataBits);
            
            executor.execute(() -> {
                try {
                    extractDataParallel(pixelBuffer, extractedData, LENGTH_BITS, startBit, endBit);
                    Log.d(TAG, "Thread " + threadIdx + " completed extracting bits " + startBit + " to " + endBit);
                } catch (Exception e) {
                    Log.e(TAG, "Error in thread " + threadIdx, e);
                } finally {
                    latch.countDown();
                }
            });
        }
        
        try {
            if (!latch.await(10, TimeUnit.SECONDS)) {
                Log.w(TAG, "Extraction timed out, some threads did not complete");
            }
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        }
        
        try {
            byte[] decompressed = ultraDecompress(extractedData);
            return new String(decompressed, StandardCharsets.UTF_8);
        } catch (Exception e) {
            Log.e(TAG, "Failed to decompress data. First byte: " + (extractedData[0] & 0xFF));
            throw new IOException("Failed to decompress data: " + e.getMessage());
        }
    }

    public Bitmap loadBitmap(String uriString) throws IOException {
        Uri uri = Uri.parse(uriString);
        InputStream inputStream = null;
        
        try {
            if (uriString.startsWith("content://")) {
                inputStream = context.getContentResolver().openInputStream(uri);
            } else {
                inputStream = new FileInputStream(uriString);
            }
            
            return BitmapFactory.decodeStream(inputStream);
        } finally {
            if (inputStream != null) {
                inputStream.close();
            }
        }
    }

    public void embedDataParallel(ByteBuffer buffer, byte[] data, int startPixelIdx, int startBit, int endBit) {
        for (int bitIdx = startBit; bitIdx < endBit; bitIdx++) {
            int bytePos = bitIdx / 8;
            if (bytePos >= data.length) break;
            
            int bitInByte = bitIdx % 8;
            int bitValue = (data[bytePos] >> bitInByte) & 1;
            
            int pixelOffset = startPixelIdx + (bitIdx / 3);
            int channel = bitIdx % 3;
            int bufferPos = pixelOffset * 4;
            
            switch (channel) {
                case 0: 
                    byte r = buffer.get(bufferPos + 2);
                    r = (byte)((r & 0xFE) | bitValue);
                    buffer.put(bufferPos + 2, r);
                    break;
                case 1: 
                    byte g = buffer.get(bufferPos + 1);
                    g = (byte)((g & 0xFE) | bitValue);
                    buffer.put(bufferPos + 1, g);
                    break;
                case 2:
                    byte b = buffer.get(bufferPos);
                    b = (byte)((b & 0xFE) | bitValue);
                    buffer.put(bufferPos, b);
                    break;
            }
        }
    }

    private void extractDataSingleThread(ByteBuffer buffer, byte[] output, int startPixelIdx, int startBit, int endBit) {
        for (int bitIdx = startBit; bitIdx < endBit; bitIdx++) {
            int outputBytePos = bitIdx / 8;
            if (outputBytePos >= output.length) break;
            
            int bitInByte = bitIdx % 8;
            
            int pixelOffset = startPixelIdx + (bitIdx / 3);
            int channel = bitIdx % 3;
            int bufferPos = pixelOffset * 4;

            int bitValue = 0;
            switch (channel) {
                case 0:
                    bitValue = buffer.get(bufferPos + 2) & 1;
                    break;
                case 1: 
                    bitValue = buffer.get(bufferPos + 1) & 1;
                    break;
                case 2: 
                    bitValue = buffer.get(bufferPos) & 1;
                    break;
            }
            
            if (bitValue == 1) {
                output[outputBytePos] |= (1 << bitInByte);
            } else {
                output[outputBytePos] &= ~(1 << bitInByte);
            }
        }
    }

    public void extractDataParallel(ByteBuffer buffer, byte[] output, int startPixelIdx, int startBit, int endBit) {
        for (int bitIdx = startBit; bitIdx < endBit; bitIdx++) {
            int outputBytePos = bitIdx / 8;
            if (outputBytePos >= output.length) break;
            
            int bitInByte = bitIdx % 8;
            
            int pixelOffset = startPixelIdx + (bitIdx / 3);
            int channel = bitIdx % 3;
            int bufferPos = pixelOffset * 4;
            
            int bitValue = 0;
            switch (channel) {
                case 0: 
                    bitValue = buffer.get(bufferPos + 2) & 1;
                    break;
                case 1:
                    bitValue = buffer.get(bufferPos + 1) & 1;
                    break;
                case 2: 
                    bitValue = buffer.get(bufferPos) & 1;
                    break;
            }
            
            synchronized (output) {
                if (bitValue == 1) {
                    output[outputBytePos] |= (1 << bitInByte);
                } else {
                    output[outputBytePos] &= ~(1 << bitInByte);
                }
            }
        }
    }

    public byte[] ultraCompress(byte[] data) {
        if (data.length < 512) {
            byte[] result = new byte[data.length + 5];
            result[0] = 0; 
            ByteBuffer.wrap(result, 1, 4).putInt(data.length);
            System.arraycopy(data, 0, result, 5, data.length);
            return result;
        }
        
        LZ4Compressor compressor = lz4Factory.fastCompressor();
        int maxCompressedSize = compressor.maxCompressedLength(data.length);
        byte[] compressed = new byte[maxCompressedSize];
        int compressedLength = compressor.compress(data, 0, data.length, compressed, 0, maxCompressedSize);

        if (compressedLength >= data.length) {
            byte[] result = new byte[data.length + 5];
            result[0] = 0; 
            ByteBuffer.wrap(result, 1, 4).putInt(data.length);
            System.arraycopy(data, 0, result, 5, data.length);
            return result;
        }
        
        byte[] result = new byte[compressedLength + 9];
        result[0] = 1; 
        ByteBuffer headerBuffer = ByteBuffer.wrap(result, 1, 8);
        headerBuffer.putInt(data.length);      
        headerBuffer.putInt(compressedLength); 
        System.arraycopy(compressed, 0, result, 9, compressedLength);
        
        return result;
    }

    public byte[] ultraDecompress(byte[] data) {
        if (data.length < 5) {
            throw new IllegalArgumentException("Data too short to contain header");
        }
        
        int compressionFlag = data[0] & 0xFF;
        
        if (compressionFlag == 0) {
            int originalLength = ByteBuffer.wrap(data, 1, 4).getInt();
            if (originalLength <= 0 || originalLength > 100_000_000) {
                throw new IllegalArgumentException("Invalid original length: " + originalLength);
            }
            byte[] result = new byte[originalLength];
            System.arraycopy(data, 5, result, 0, originalLength);
            return result;
        } else if (compressionFlag == 1) {
            if (data.length < 9) {
                throw new IllegalArgumentException("Compressed data too short to contain header");
            }
            
            ByteBuffer headerBuffer = ByteBuffer.wrap(data, 1, 8);
            int originalLength = headerBuffer.getInt();
            int compressedLength = headerBuffer.getInt();
            
            if (originalLength <= 0 || originalLength > 100_000_000 || 
                compressedLength <= 0 || compressedLength > data.length - 9) {
                throw new IllegalArgumentException("Invalid decompression sizes");
            }
            
            byte[] result = new byte[originalLength];
            LZ4FastDecompressor decompressor = lz4Factory.fastDecompressor();
            decompressor.decompress(data, 9, result, 0, originalLength);
            return result;
        } else {
            throw new IllegalArgumentException("Unknown compression flag: " + compressionFlag + 
                                           " (Decimal: " + compressionFlag + 
                                           ", Hex: 0x" + Integer.toHexString(compressionFlag) + 
                                           "). This image may not contain valid steganographic data.");
        }
    }

    public String createTempFile(String extension) throws IOException {
        File outputDir = context.getCacheDir();
        File tempFile = File.createTempFile("ufs_", "." + extension, outputDir);
        return tempFile.getAbsolutePath();
    }
}