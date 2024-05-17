//
//  libretro.h
//  ArcadiaCore
//
//  Created by Davide Andreoli on 15/05/24.
//

#ifndef libretro_h
#define libretro_h

struct retro_variable
{
   /* Variable to query in RETRO_ENVIRONMENT_GET_VARIABLE.
    * If NULL, obtains the complete environment string if more
    * complex parsing is necessary.
    * The environment string is formatted as key-value pairs
    * delimited by semicolons as so:
    * "key1=value1;key2=value2;..."
    */
   const char *key;

   /* Value to be obtained. If key does not exist, it is set to NULL. */
   const char *value;
};

#endif /* libretro_h */
