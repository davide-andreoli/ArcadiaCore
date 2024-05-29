//
//  workers.c
//  ArcadiaCore
//
//  Created by Davide Andreoli on 21/05/24.
//

#include "libretro_callbacks.h"
#include <stdlib.h>
#include <stdio.h>

uint8_t* libretro_video_refresh_callback(const void *frame_buffer_data, uint32_t width, uint32_t height, int pitch, enum retro_pixel_format pixel_format) {
    if (frame_buffer_data == NULL) {
        printf("frame_buffer_data was null\n");
        return NULL;
    }
    
    int bytesPerPixel;
    
    if (pixel_format == RETRO_PIXEL_FORMAT_XRGB8888) {
        bytesPerPixel = 4; // XRGB8888 format
    } else if (pixel_format == RETRO_PIXEL_FORMAT_RGB565) {
        bytesPerPixel = 2; // RGB565 format
    } else {
        printf("Unsupported pixel format\n");
        return NULL;
    }

    int lengthOfFrameBuffer = height * pitch;

    uint8_t *pixelArray = (uint8_t *)malloc(width * height * 4); // 4 bytes per pixel for output buffer
    if (pixelArray == NULL) {
        printf("Failed to allocate memory for pixelArray\n");
        return NULL;
    }

    uint32_t endianness = __BYTE_ORDER__;

    for (uint32_t y = 0; y < height; y++) {
        int rowOffset = y * pitch;
        for (uint32_t x = 0; x < width; x++) {
            int pixelOffset = rowOffset + x * bytesPerPixel;
            int rgbaOffset = y * width * 4 + x * 4;

            if (pixel_format == RETRO_PIXEL_FORMAT_XRGB8888) {
                uint8_t blue = *((uint8_t *)(frame_buffer_data + pixelOffset));
                uint8_t green = *((uint8_t *)(frame_buffer_data + pixelOffset + 1));
                uint8_t red = *((uint8_t *)(frame_buffer_data + pixelOffset + 2));
                uint8_t alpha = *((uint8_t *)(frame_buffer_data + pixelOffset + 3));
                if (endianness == __ORDER_LITTLE_ENDIAN__) {
                    pixelArray[rgbaOffset] = blue;
                    pixelArray[rgbaOffset + 1] = green;
                    pixelArray[rgbaOffset + 2] = red;
                    pixelArray[rgbaOffset + 3] = alpha;
                } else if (endianness == __ORDER_BIG_ENDIAN__) {
                    pixelArray[rgbaOffset] = red;
                    pixelArray[rgbaOffset + 1] = green;
                    pixelArray[rgbaOffset + 2] = blue;
                    pixelArray[rgbaOffset + 3] = alpha;
                } else {
                    printf("Unknown endianness\n");
                    free(pixelArray);
                    return NULL;
                }

            } else if (pixel_format == RETRO_PIXEL_FORMAT_RGB565) {
                uint16_t pixelData = *((uint16_t *)(frame_buffer_data + pixelOffset));

                uint8_t red = (uint8_t)(((pixelData >> 11) & 0x1F) * 255 / 31);
                uint8_t green = (uint8_t)(((pixelData >> 5) & 0x3F) * 255 / 63);
                uint8_t blue = (uint8_t)((pixelData & 0x1F) * 255 / 31);
                uint8_t alpha = 255;

                pixelArray[rgbaOffset] = blue;
                pixelArray[rgbaOffset + 1] = green;
                pixelArray[rgbaOffset + 2] = red;
                pixelArray[rgbaOffset + 3] = alpha;
            }
        }
    }
    return pixelArray;
}

int16_t libretro_input_state_callback(int16_t *array, int size, uint32_t id) {
    if (array == NULL || *array != id)
        return 0;
    
    for (int i = 0; i < size - 1; i++) {
        array[i] = array[i + 1];
    }

    return 1;
}

void convert_s16_to_float(float *out, const int16_t *in, size_t samples, float gain) {
    size_t i;
    float scale = 1.0f / 32768.0f;
    for (i = 0; i < samples; i++) {
        out[i] = ((float)in[i] * scale) * gain;
    }
}


