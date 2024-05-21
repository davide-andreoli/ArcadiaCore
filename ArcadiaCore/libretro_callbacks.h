//
//  workers.h
//  ArcadiaCore
//
//  Created by Davide Andreoli on 21/05/24.
//

#ifndef libretro_callbacks_h
#define libretro_callbacks_h

#include <stdio.h>
#import <LibretroCommon/libretro.h>

uint8_t* libretro_video_refresh_callback(const void *frame_buffer_data, uint32_t width, uint32_t height, int pitch, enum retro_pixel_format pixel_format);
int16_t libretro_input_state_callback(int16_t *array, int size, uint32_t id);

void convert_s16_to_float(float *out, const int16_t *in, size_t samples, float gain);


#endif /* workers_h */
