package com.example.stegoapp;

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
import java.util.Arrays;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.TimeUnit;

import android.media.MediaExtractor;
import android.media.MediaFormat;
import android.media.MediaMuxer;
import android.media.MediaMetadataRetriever;
import java.io.FileInputStream;
import android.media.MediaCodec;

public class UltraFastSteganography {
    private static final String TAG = "UltraFastSteganography";
    private final Context context;
    private final ExecutorService executor;
    private static final int THREAD_COUNT = Runtime.getRuntime().availableProcessors() * 2;
    private static final int BUFFER_SIZE = 64 * 1024;
    private static final int HEADER_SIZE = 8;
    private static final int LENGTH_BITS = 32; 
    private final LZ4Factory lz4Factory;

    public UltraFastSteganography(Context context) {
        this.context = context;
        this.executor = Executors.newFixedThreadPool(THREAD_COUNT);
        this.lz4Factory = LZ4Factory.fastestInstance();
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
        
        Bitmap carrierBitmap;
        Uri uri = Uri.parse(carrierUri);
        
        if (carrierUri.startsWith("content://")) {
            InputStream inputStream = context.getContentResolver().openInputStream(uri);
            carrierBitmap = BitmapFactory.decodeStream(inputStream, null, options);
            inputStream.close();
        } else {
            carrierBitmap = BitmapFactory.decodeFile(carrierUri, options);
        }
        
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
        

        ByteBuffer.allocateDirect(4).putInt(0);
        

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
        
        Bitmap carrierBitmap;
        Uri uri = Uri.parse(carrierUri);
        
        if (carrierUri.startsWith("content://")) {
            InputStream inputStream = context.getContentResolver().openInputStream(uri);
            carrierBitmap = BitmapFactory.decodeStream(inputStream, null, options);
            inputStream.close();
        } else {
            carrierBitmap = BitmapFactory.decodeFile(carrierUri, options);
        }
        
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

    // ================ IMAGE-IN-VIDEO METHODS ================
    public String hideImageInVideo(String secretImageUri, String carrierVideoUri) {
        try {

            Bitmap secretBitmap = loadBitmap(secretImageUri);
            ByteArrayOutputStream stream = new ByteArrayOutputStream();
            secretBitmap.compress(Bitmap.CompressFormat.PNG, 100, stream);
            byte[] secretData = stream.toByteArray();
            secretBitmap.recycle();
            
     
            return hideBinaryInVideo(secretData, carrierVideoUri);
        } catch (Exception e) {
            Log.e(TAG, "Error hiding image in video", e);
            return "Error: " + e.getMessage();
        }
    }

    public Bitmap extractImageFromVideo(String carrierVideoUri) {
        try {

            byte[] imageData = extractBinaryFromVideo(carrierVideoUri);
            

            return BitmapFactory.decodeByteArray(imageData, 0, imageData.length);
        } catch (Exception e) {
            Log.e(TAG, "Error extracting image from video", e);
            return null;
        }
    }

    public String saveBitmapToTempFile(Bitmap bitmap) throws IOException {
    String outputPath = createTempFile("png");
    try (FileOutputStream fos = new FileOutputStream(outputPath)) {
        bitmap.compress(Bitmap.CompressFormat.PNG, 100, fos);
        fos.flush();
    }
    return outputPath;
    }
    // ================  BINARY DATA METHODS ================
    private String hideBinaryInImage(byte[] data, Bitmap carrierBitmap) throws IOException {

        int width = carrierBitmap.getWidth();
        int height = carrierBitmap.getHeight();
        int pixelCount = width * height;
        
        byte[] dataToHide = ultraCompress(data);
        int dataLength = dataToHide.length;
        

        int bitsAvailable = (pixelCount - LENGTH_BITS) * 3;
        if (dataLength * 8 > bitsAvailable) {
            carrierBitmap.recycle();
            throw new IOException("Image too small for data");
        }
        

        ByteBuffer pixelBuffer = ByteBuffer.allocateDirect(pixelCount * 4);
        pixelBuffer.order(ByteOrder.nativeOrder());
        carrierBitmap.copyPixelsToBuffer(pixelBuffer);
        carrierBitmap.recycle();
        pixelBuffer.rewind();
        

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
        
        // Save result
        String outputPath = createTempFile("png");
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
        for (int i = 0; i < LENGTH_BITS; i++) {
            int pos = i * 4;
            byte r = pixelBuffer.get(pos + 2);
            int bit = r & 1;
            dataLength |= (bit << i);
        }
        

        int maxPossibleLength = (pixelCount - LENGTH_BITS) * 3 / 8;
        if (dataLength <= 0 || dataLength > maxPossibleLength) {
            throw new IOException("Invalid data length");
        }
        

        byte[] extractedData = new byte[dataLength];
        int dataBits = dataLength * 8;
        int bitsPerThread = (dataBits + THREAD_COUNT - 1) / THREAD_COUNT;
        CountDownLatch latch = new CountDownLatch(THREAD_COUNT);
        
        for (int t = 0; t < THREAD_COUNT; t++) {
            final int startBit = t * bitsPerThread;
            final int endBit = Math.min((t + 1) * bitsPerThread, dataBits);
            
            executor.execute(() -> {
                try {
                    extractDataParallel(pixelBuffer, extractedData, LENGTH_BITS, startBit, endBit);
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
        

        return ultraDecompress(extractedData);
    }

    // ================ VIDEO STEGANOGRAPHY METHODS ================
    private String hideBinaryInVideo(byte[] data, String videoUri) throws IOException {

        byte[] dataToHide = ultraCompress(data);
        

        MediaExtractor extractor = new MediaExtractor();
        extractor.setDataSource(videoUri);
        

        int videoTrackIndex = -1;
        for (int i = 0; i < extractor.getTrackCount(); i++) {
            MediaFormat format = extractor.getTrackFormat(i);
            String mime = format.getString(MediaFormat.KEY_MIME);
            if (mime.startsWith("video/")) {
                videoTrackIndex = i;
                break;
            }
        }
        
        if (videoTrackIndex == -1) {
            throw new IOException("No video track found");
        }
        
        extractor.selectTrack(videoTrackIndex);
        

        String outputPath = createTempFile("mp4");
        MediaMuxer muxer = new MediaMuxer(outputPath, MediaMuxer.OutputFormat.MUXER_OUTPUT_MPEG_4);

        ByteBuffer buffer = ByteBuffer.allocate(1024 * 1024);
        MediaCodec.BufferInfo info = new MediaCodec.BufferInfo();
        
        while (true) {
            int sampleSize = extractor.readSampleData(buffer, 0);
            if (sampleSize < 0) break;
            

            
            extractor.advance();
        }
        
        extractor.release();
        muxer.release();
        
        return outputPath;
    }

    private byte[] extractBinaryFromVideo(String videoUri) throws IOException {

        
        MediaMetadataRetriever retriever = new MediaMetadataRetriever();
        retriever.setDataSource(videoUri);
        

        String frameCountStr = retriever.extractMetadata(
            MediaMetadataRetriever.METADATA_KEY_VIDEO_FRAME_COUNT);
        int frameCount = frameCountStr != null ? Integer.parseInt(frameCountStr) : 100;
        
        ByteArrayOutputStream outputStream = new ByteArrayOutputStream();
        

        for (int i = 0; i < Math.min(frameCount, 10); i++) {
            Bitmap frame = retriever.getFrameAtTime(i * 1000000L, 
                MediaMetadataRetriever.OPTION_CLOSEST_SYNC);
            if (frame != null) {

                byte[] pixelData = getPixels(frame);
                outputStream.write(pixelData, 0, Math.min(100, pixelData.length));
                frame.recycle();
            }
        }
        
        retriever.release();
        return ultraDecompress(outputStream.toByteArray());
    }

    // ================ HELPER METHODS ================
    private Bitmap loadBitmap(String uriString) throws IOException {
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

    private byte[] getPixels(Bitmap bitmap) {
        int size = bitmap.getRowBytes() * bitmap.getHeight();
        ByteBuffer byteBuffer = ByteBuffer.allocate(size);
        bitmap.copyPixelsToBuffer(byteBuffer);
        return byteBuffer.array();
    }

    private void embedDataParallel(ByteBuffer buffer, byte[] data, int startPixelIdx, int startBit, int endBit) {
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

    private void extractDataParallel(ByteBuffer buffer, byte[] output, int startPixelIdx, int startBit, int endBit) {
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

    private byte[] ultraCompress(byte[] data) {
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

    private byte[] ultraDecompress(byte[] data) {
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

    private String createTempFile(String extension) throws IOException {
        File outputDir = context.getCacheDir();
        File tempFile = File.createTempFile("ufs_", "." + extension, outputDir);
        return tempFile.getAbsolutePath();
    }

    public void cleanup() {
        executor.shutdownNow();
        try {
            if (!executor.awaitTermination(500, TimeUnit.MILLISECONDS)) {
                Log.w(TAG, "Executor did not terminate in time");
            }
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        }
    }
}
