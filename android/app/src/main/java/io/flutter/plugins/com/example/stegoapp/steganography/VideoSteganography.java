package com.example.stegoapp.steganography;

import android.content.Context;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.media.MediaCodec;
import android.media.MediaExtractor;
import android.media.MediaFormat;
import android.media.MediaMuxer;
import android.util.Log;

import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.nio.ByteBuffer;
import java.security.MessageDigest;
import java.util.zip.CRC32;
import java.util.zip.Deflater;
import java.util.zip.Inflater;

public class VideoSteganography {
    private static final String TAG = "VideoSteganography";
    private final Context context;
    private static final int HEADER_SIZE = 8;
    private static final int MAGIC_NUMBER = 0x53544547; 
    private static final int MAX_DATA_SIZE = 5 * 1024 * 1024; 
    private static final int FRAME_SKIP_COUNT = 10;
    private static final int HEADER_FRAME_POSITION = 15;

    public VideoSteganography(Context context) {
        this.context = context;
    }

  
    private Bitmap loadBitmap(String uri) throws IOException {
        return BitmapFactory.decodeFile(uri);
    }


    private String createTempFile(String extension) throws IOException {
        File tempFile = File.createTempFile("stego_", "." + extension, context.getCacheDir());
        return tempFile.getAbsolutePath();
    }

    private byte[] ultraCompress(byte[] data) {
        Deflater deflater = new Deflater(Deflater.BEST_COMPRESSION);
        deflater.setInput(data);
        deflater.finish();
        ByteArrayOutputStream outputStream = new ByteArrayOutputStream(data.length);
        byte[] buffer = new byte[1024];
        while (!deflater.finished()) {
            int count = deflater.deflate(buffer);
            outputStream.write(buffer, 0, count);
        }
        try {
            outputStream.close();
        } catch (IOException e) {
            Log.e(TAG, "Error closing output stream in compress", e);
        }
        byte[] compressedData = outputStream.toByteArray();
        byte[] result = new byte[compressedData.length + 1];
        result[0] = 1;
        System.arraycopy(compressedData, 0, result, 1, compressedData.length);
        return result;
    }


    private byte[] ultraDecompress(byte[] data) throws IOException {
        if (data.length < 1 || data[0] != 1) {
            throw new IOException("Data not compressed or invalid format");
        }
        byte[] compressedData = new byte[data.length - 1];
        System.arraycopy(data, 1, compressedData, 0, compressedData.length);
        Inflater inflater = new Inflater();
        inflater.setInput(compressedData);
        ByteArrayOutputStream outputStream = new ByteArrayOutputStream(compressedData.length);
        byte[] buffer = new byte[1024];
        try {
            while (!inflater.finished()) {
                int count = inflater.inflate(buffer);
                outputStream.write(buffer, 0, count);
            }
            outputStream.close();
        } catch (Exception e) {
            throw new IOException("Decompression failed", e);
        }
        return outputStream.toByteArray();
    }

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

    public Bitmap extractImageFromVideo(String stegoVideoUri) {
        try {
            byte[] imageData = extractBinaryFromVideo(stegoVideoUri);
            if (imageData != null && imageData.length > 0) {
                return BitmapFactory.decodeByteArray(imageData, 0, imageData.length);
            } else {
                Log.e(TAG, "Extracted data is null or empty");
                return null;
            }
        } catch (Exception e) {
            Log.e(TAG, "Error extracting image from video", e);
            return null;
        }
    }

    private String hideBinaryInVideo(byte[] data, String videoUri) throws IOException {
        ByteBuffer dataWithChecksum = ByteBuffer.allocate(data.length + 4);
        CRC32 crc = new CRC32();
        crc.update(data);
        dataWithChecksum.putInt((int) crc.getValue());
        dataWithChecksum.put(data);
        byte[] dataToHide = ultraCompress(dataWithChecksum.array());
        Log.d(TAG, "Data size to hide: " + dataToHide.length + " bytes");
        Log.d(TAG, "Pre-embed first byte (compression flag): " + (dataToHide[0] & 0xFF));
        Log.d(TAG, "Pre-embed first 5 bytes: " +
                String.format("%02x %02x %02x %02x %02x",
                        dataToHide[0], dataToHide[1], dataToHide[2],
                        dataToHide[3], dataToHide[4]));
        String dataHash = computeHash(dataToHide);
        Log.d(TAG, "Pre-embed data hash: " + dataHash);
        String outputPath = createTempFile("mp4");
        MediaExtractor extractor = new MediaExtractor();
        extractor.setDataSource(videoUri);
        int videoTrackIndex = -1;
        MediaFormat videoFormat = null;
        for (int i = 0; i < extractor.getTrackCount(); i++) {
            MediaFormat format = extractor.getTrackFormat(i);
            String mime = format.getString(MediaFormat.KEY_MIME);
            if (mime.startsWith("video/")) {
                videoTrackIndex = i;
                videoFormat = format;
                break;
            }
        }
        if (videoTrackIndex == -1) {
            throw new IOException("No video track found");
        }
        MediaMuxer muxer = new MediaMuxer(outputPath, MediaMuxer.OutputFormat.MUXER_OUTPUT_MPEG_4);
        int videoOutputTrackIndex = muxer.addTrack(videoFormat);
        int[] trackMap = new int[extractor.getTrackCount()];
        for (int i = 0; i < extractor.getTrackCount(); i++) {
            if (i == videoTrackIndex) {
                trackMap[i] = videoOutputTrackIndex;
            } else {
                trackMap[i] = muxer.addTrack(extractor.getTrackFormat(i));
            }
        }
        muxer.start();
        ByteBuffer headerBuffer = ByteBuffer.allocate(HEADER_SIZE);
        headerBuffer.putInt(MAGIC_NUMBER);
        headerBuffer.putInt(dataToHide.length);
        headerBuffer.rewind();
        boolean headerWritten = false;
        int dataOffset = 0;
        boolean dataFullyWritten = false;
        int maxBufferSize = 1024 * 1024;
        ByteBuffer buffer = ByteBuffer.allocate(maxBufferSize);
        MediaCodec.BufferInfo bufferInfo = new MediaCodec.BufferInfo();
        extractor.selectTrack(videoTrackIndex);
        int framesSkipped = 0;
        while (framesSkipped < FRAME_SKIP_COUNT) {
            buffer.clear();
            int chunkSize = extractor.readSampleData(buffer, 0);
            if (chunkSize < 0) {
                break;
            }
            bufferInfo.offset = 0;
            bufferInfo.size = chunkSize;
            bufferInfo.presentationTimeUs = extractor.getSampleTime();
            bufferInfo.flags = extractor.getSampleFlags();
            buffer.rewind();
            muxer.writeSampleData(videoOutputTrackIndex, buffer, bufferInfo);
            extractor.advance();
            framesSkipped++;
        }
        int nonKeyframeCount = 0;
        while (true) {
            buffer.clear();
            int chunkSize = extractor.readSampleData(buffer, 0);
            if (chunkSize < 0) {
                break;
            }
            int trackIndex = extractor.getSampleTrackIndex();
            if (trackIndex != videoTrackIndex) {
                extractor.advance();
                continue;
            }
            bufferInfo.offset = 0;
            bufferInfo.size = chunkSize;
            bufferInfo.presentationTimeUs = extractor.getSampleTime();
            bufferInfo.flags = extractor.getSampleFlags();
            boolean isKeyFrame = (bufferInfo.flags & MediaCodec.BUFFER_FLAG_KEY_FRAME) != 0;
            if (!isKeyFrame) {
                nonKeyframeCount++;
                buffer.rewind();
                byte[] frameData = new byte[chunkSize];
                buffer.get(frameData, 0, chunkSize);
                if (!headerWritten && nonKeyframeCount == HEADER_FRAME_POSITION && chunkSize > HEADER_SIZE * 8) {
                    embedBytes(frameData, headerBuffer.array(), 0);
                    headerWritten = true;
                    Log.d(TAG, "Header written in non-keyframe #" + nonKeyframeCount);
                } else if (headerWritten && !dataFullyWritten && dataOffset < dataToHide.length && nonKeyframeCount > HEADER_FRAME_POSITION) {
                    int maxBytesToEmbed = Math.max(1, (chunkSize / 8) * 3 / 4);
                    int bytesToEmbed = Math.min(maxBytesToEmbed, dataToHide.length - dataOffset);
                    if (bytesToEmbed > 0) {
                        byte[] dataChunk = new byte[bytesToEmbed];
                        System.arraycopy(dataToHide, dataOffset, dataChunk, 0, bytesToEmbed);
                        int safeOffset = Math.max(HEADER_SIZE * 8, chunkSize / 5);
                        embedBytes(frameData, dataChunk, safeOffset);
                        dataOffset += bytesToEmbed;
                        if (dataOffset >= dataToHide.length) {
                            dataFullyWritten = true;
                            Log.d(TAG, "All data written, total: " + dataOffset + " bytes");
                        }
                    }
                }
                ByteBuffer modifiedBuffer = ByteBuffer.wrap(frameData);
                muxer.writeSampleData(trackMap[trackIndex], modifiedBuffer, bufferInfo);
            } else {
                buffer.rewind();
                muxer.writeSampleData(trackMap[trackIndex], buffer, bufferInfo);
            }
            extractor.advance();
        }
        for (int i = 0; i < extractor.getTrackCount(); i++) {
            if (i == videoTrackIndex) continue;
            extractor.unselectTrack(videoTrackIndex);
            extractor.selectTrack(i);
            while (true) {
                buffer.clear();
                int chunkSize = extractor.readSampleData(buffer, 0);
                if (chunkSize < 0) {
                    break;
                }
                int trackIndex = extractor.getSampleTrackIndex();
                bufferInfo.offset = 0;
                bufferInfo.size = chunkSize;
                bufferInfo.presentationTimeUs = extractor.getSampleTime();
                bufferInfo.flags = extractor.getSampleFlags();
                buffer.rewind();
                muxer.writeSampleData(trackMap[trackIndex], buffer, bufferInfo);
                extractor.advance();
            }
        }
        extractor.release();
        muxer.stop();
        muxer.release();
        if (!dataFullyWritten) {
            throw new IOException("Video too small to hide data of size " + dataToHide.length + " bytes. Only embedded " + dataOffset + " bytes");
        }
        return outputPath;
    }

    private byte[] extractBinaryFromVideo(String stegoVideoUri) throws IOException {
        MediaExtractor extractor = new MediaExtractor();
        extractor.setDataSource(stegoVideoUri);
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
        int framesSkipped = 0;
        while (framesSkipped < FRAME_SKIP_COUNT) {
            int sampleSize = extractor.readSampleData(ByteBuffer.allocate(1024 * 1024), 0);
            if (sampleSize < 0) {
                throw new IOException("End of stream reached before skipping initial frames");
            }
            extractor.advance();
            framesSkipped++;
        }
        ByteBuffer buffer = ByteBuffer.allocate(1024 * 1024);
        boolean headerFound = false;
        int dataLength = 0;
        int headerOffset = 0;
        int nonKeyframeCount = 0;
        int maxHeaderSearchFrames = HEADER_FRAME_POSITION + 10;
        int framesChecked = 0;
        while (!headerFound && framesChecked < maxHeaderSearchFrames) {
            buffer.clear();
            int sampleSize = extractor.readSampleData(buffer, 0);
            if (sampleSize < 0) {
                throw new IOException("End of stream reached before finding header");
            }
            int flags = extractor.getSampleFlags();
            boolean isKeyFrame = (flags & MediaCodec.BUFFER_FLAG_KEY_FRAME) != 0;
            if (!isKeyFrame && sampleSize > HEADER_SIZE * 8) {
                nonKeyframeCount++;
                buffer.rewind();
                byte[] frameData = new byte[sampleSize];
                buffer.get(frameData, 0, sampleSize);
                for (int offset = 0; offset < Math.min(32, sampleSize - HEADER_SIZE * 8); offset += 4) {
                    byte[] headerBytes = extractBytes(frameData, HEADER_SIZE, offset);
                    ByteBuffer headerBuffer = ByteBuffer.wrap(headerBytes);
                    int magicNumber = headerBuffer.getInt();
                    if (magicNumber == MAGIC_NUMBER) {
                        dataLength = headerBuffer.getInt();
                        if (dataLength > 0 && dataLength <= MAX_DATA_SIZE) {
                            Log.d(TAG, "Header found at frame " + nonKeyframeCount + ", offset " + offset + ", data length: " + dataLength);
                            headerFound = true;
                            headerOffset = offset;
                            break;
                        }
                    }
                }
            }
            if (!headerFound) {
                extractor.advance();
            }
            framesChecked++;
        }
        if (!headerFound) {
            throw new IOException("Failed to find valid header");
        }
        extractor.advance();
        nonKeyframeCount++;
        byte[] extractedData = new byte[dataLength];
        int dataOffset = 0;
        while (dataOffset < dataLength) {
            buffer.clear();
            int sampleSize = extractor.readSampleData(buffer, 0);
            if (sampleSize < 0) {
                break;
            }
            int flags = extractor.getSampleFlags();
            boolean isKeyFrame = (flags & MediaCodec.BUFFER_FLAG_KEY_FRAME) != 0;
            if (!isKeyFrame) {
                buffer.rewind();
                byte[] frameData = new byte[sampleSize];
                buffer.get(frameData, 0, sampleSize);
                int safeOffset = Math.max(HEADER_SIZE * 8, sampleSize / 5);
                int maxBytesToExtract = Math.max(1, (sampleSize / 8) * 3 / 4);
                int bytesToExtract = Math.min(maxBytesToExtract, dataLength - dataOffset);
                if (bytesToExtract > 0) {
                    byte[] dataChunk = extractBytes(frameData, bytesToExtract, safeOffset);
                    System.arraycopy(dataChunk, 0, extractedData, dataOffset, bytesToExtract);
                    dataOffset += bytesToExtract;
                    Log.d(TAG, "Extracted " + bytesToExtract + " bytes from frame " + nonKeyframeCount + ", total: " + dataOffset);
                }
                nonKeyframeCount++;
            }
            extractor.advance();
        }
        extractor.release();
        if (dataOffset < dataLength) {
            Log.w(TAG, "Only extracted " + dataOffset + " bytes out of " + dataLength);
            throw new IOException("Incomplete data extraction: got " + dataOffset + " of " + dataLength + " bytes");
        }
        String extractedHash = computeHash(extractedData);
        Log.d(TAG, "Post-extract data hash: " + extractedHash);
        Log.d(TAG, "Extracted first byte (compression flag): " + (extractedData[0] & 0xFF));
        Log.d(TAG, "Extracted first 5 bytes: " +
                String.format("%02x %02x %02x %02x %02x",
                        extractedData[0], extractedData[1], extractedData[2],
                        extractedData[3], extractedData[4]));
        byte[] decompressedData;
        try {
            decompressedData = ultraDecompress(extractedData);
        } catch (Exception e) {
            Log.e(TAG, "Decompression failed with exception", e);
            throw e;
        }
        ByteBuffer buffer2 = ByteBuffer.wrap(decompressedData);
        int storedChecksum = buffer2.getInt();
        byte[] actualData = new byte[decompressedData.length - 4];
        buffer2.get(actualData);
        CRC32 crc = new CRC32();
        crc.update(actualData);
        int calculatedChecksum = (int) crc.getValue();
        if (storedChecksum != calculatedChecksum) {
            throw new IOException("Data integrity check failed: stored checksum " + storedChecksum +
                    ", calculated " + calculatedChecksum);
        }
        return actualData;
    }

    private void embedBytes(byte[] carrier, byte[] data, int offset) {
        Log.d(TAG, "Embedding " + data.length + " bytes at offset " + offset + " in carrier of size " + carrier.length);
        for (int i = 0; i < data.length; i++) {
            if (offset + i * 8 + 7 >= carrier.length) {
                Log.e(TAG, "Data won't fit: required " + (offset + i * 8 + 7) + ", available " + carrier.length);
                throw new ArrayIndexOutOfBoundsException("Data won't fit in carrier");
            }
            embedByte(carrier, offset + i * 8, data[i]);
        }
        byte[] verify = extractBytes(carrier, Math.min(5, data.length), offset);
        Log.d(TAG, "Embedded verification - First 5 bytes: " +
                String.format("%02x %02x %02x %02x %02x",
                        verify[0], verify[1], verify[2], verify[3], verify[4]));
    }

    private void embedByte(byte[] carrier, int offset, byte b) {
        for (int i = 0; i < 8; i++) {
            int bit = (b >> i) & 1;
            carrier[offset + i] = (byte) ((carrier[offset + i] & 0xFE) | bit);
        }
    }

    private byte[] extractBytes(byte[] carrier, int length, int offset) {
        byte[] result = new byte[length];
        for (int i = 0; i < length; i++) {
            if (offset + i * 8 + 7 >= carrier.length) {
                Log.w(TAG, "Attempted to read beyond carrier bounds at offset " + (offset + i * 8) + ", carrier length: " + carrier.length);
                break;
            }
            result[i] = extractByte(carrier, offset + i * 8);
        }
        return result;
    }

    private byte extractByte(byte[] carrier, int offset) {
        byte b = 0;
        for (int i = 0; i < 8; i++) {
            if (offset + i < carrier.length) {
                int bit = carrier[offset + i] & 1;
                b |= (bit << i);
            }
        }
        return b;
    }

    private String computeHash(byte[] data) {
        try {
            MessageDigest md = MessageDigest.getInstance("SHA-256");
            byte[] hash = md.digest(data);
            StringBuilder hexString = new StringBuilder();
            for (byte b : hash) {
                String hex = Integer.toHexString(0xff & b);
                if (hex.length() == 1) hexString.append('0');
                hexString.append(hex);
            }
            return hexString.toString();
        } catch (Exception e) {
            Log.e(TAG, "Error computing hash", e);
            return "error";
        }
    }
}