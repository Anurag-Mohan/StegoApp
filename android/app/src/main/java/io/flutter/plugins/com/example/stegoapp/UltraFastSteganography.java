package com.example.stegoapp;

import android.content.Context;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.net.Uri;
import android.util.Log;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

import net.jpountz.lz4.LZ4Factory;

import com.example.stegoapp.steganography.TextSteganography;
import com.example.stegoapp.steganography.ImageSteganography;
import com.example.stegoapp.steganography.VideoSteganography;



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
    private final TextSteganography textSteganography;
    private final ImageSteganography imageSteganography;
    private final VideoSteganography videoSteganography;
    private final ExecutorService executor;
    private final LZ4Factory lz4Factory;

    public UltraFastSteganography(Context context) {
        this.lz4Factory = LZ4Factory.fastestInstance();
        this.executor = Executors.newFixedThreadPool(TextSteganography.THREAD_COUNT);
        this.textSteganography = new TextSteganography(context, executor, lz4Factory);
        this.imageSteganography = new ImageSteganography(context, textSteganography);
        this.videoSteganography = new VideoSteganography(context);
    }

    public String hideTextInImage(String text, String carrierUri) {
        return textSteganography.hideTextInImage(text, carrierUri);
    }

    public String extractTextFromImage(String carrierUri) {
        return textSteganography.extractTextFromImage(carrierUri);
    }

    public String hideImageInImage(String secretImageUri, String carrierUri) {
        return imageSteganography.hideImageInImage(secretImageUri, carrierUri);
    }

    public Bitmap extractImageFromImage(String carrierUri) {
        return imageSteganography.extractImageFromImage(carrierUri);
    }

    public String hideImageInVideo(String secretImageUri, String carrierVideoUri) {
        return videoSteganography.hideImageInVideo(secretImageUri, carrierVideoUri);
    }

    public Bitmap extractImageFromVideo(String carrierVideoUri) {
        return videoSteganography.extractImageFromVideo(carrierVideoUri);
    }

    public String saveBitmapToTempFile(Bitmap bitmap) throws IOException {
        return imageSteganography.saveBitmapToTempFile(bitmap);
    }

    public void cleanup() {
        executor.shutdownNow();
        try {
            if (!executor.awaitTermination(500, TimeUnit.MILLISECONDS)) {
                Log.w("UltraFastSteganography", "Executor did not terminate in time");
            }
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        }
    }
}