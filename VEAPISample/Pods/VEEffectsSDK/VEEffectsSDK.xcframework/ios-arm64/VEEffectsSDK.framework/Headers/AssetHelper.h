//
//  AssetHelper.h
//  BanubaSdk
//
//  Created by Alexey Ereschenko on 3/7/19.
//  Copyright © 2019 Banuba. All rights reserved.
//

#import <Foundation/Foundation.h>

size_t rearrange_lut3d_pixels( uint8_t const * pixels2d, size_t w, size_t h, uint8_t * pixels3d );
size_t rearrange_lut3d_pixels_for_metal( uint8_t const * pixels2d, size_t w, size_t h, uint8_t * pixels3d );
unsigned char* loadPng(char const *filename, int *x, int *y, int *comp, int req_comp);
void freePng(unsigned char *image);


