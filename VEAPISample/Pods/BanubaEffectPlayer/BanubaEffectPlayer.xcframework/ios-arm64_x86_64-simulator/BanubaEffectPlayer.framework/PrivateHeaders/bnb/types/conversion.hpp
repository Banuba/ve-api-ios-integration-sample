#pragma once

#include <bnb/types/full_image.hpp>
#include <bnb/utils/stdrestrict.hpp>
#include <functional>

namespace bnb
{
    using memory_deletter = std::function<void()>;

    full_image_t make_full_image_from_rgb_planes(
        // clang-format off
        const image_format& image_format,
        const uint8_t* r_buffer, int32_t r_row_stride, int32_t r_pixel_stride,
        const uint8_t* g_buffer, int32_t g_row_stride, int32_t g_pixel_stride,
        const uint8_t* b_buffer, int32_t b_row_stride, int32_t b_pixel_stride
        // clang-format on
    );

    full_image_t make_full_image_from_nonplanar_bpc8_no_copy(
        const image_format& image_format,
        const bpc8_image_t::pixel_format_t pixel_format,
        uint8_t* buffer,
        int32_t row_stride,
        memory_deletter free_memory);

    full_image_t make_full_image_from_yuv_planes(
        // clang-format off
        const image_format& image_format,
        const std::vector<uint8_t>& y_buffer, int32_t y_row_stride, int32_t y_pixel_stride,
        const std::vector<uint8_t>& u_buffer, int32_t u_row_stride, int32_t u_pixel_stride,
        const std::vector<uint8_t>& v_buffer, int32_t v_row_stride, int32_t v_pixel_stride,
        const yuv_format_t& yuv_format
        // clang-format on
    );

    full_image_t make_full_image_from_yuv_planes(
        // clang-format off
        const image_format& image_format,
        const uint8_t* restrict y_buffer, int32_t y_row_stride, int32_t y_pixel_stride,
        const uint8_t* u_buffer, int32_t u_row_stride, int32_t u_pixel_stride,
        const uint8_t* v_buffer, int32_t v_row_stride, int32_t v_pixel_stride,
        const yuv_format_t& yuv_format
        // clang-format on
    );

    full_image_t make_full_image_from_biplanar_yuv(
        // clang-format off
       const image_format& image_format,
       const std::vector<uint8_t>& lumo_buffer, int32_t lumo_row_stride,
       const std::vector<uint8_t>& chromo_buffer, int32_t chromo_row_stride,
       const yuv_format_t& yuv_format
        // clang-format on
    );

    full_image_t make_full_image_from_biplanar_yuv(
        // clang-format off
        const image_format& image_format,
        const uint8_t* restrict lumo_buffer, int32_t lumo_row_stride,
        const uint8_t* restrict chromo_buffer, int32_t chromo_row_stride,
        const yuv_format_t& yuv_format
        // clang-format on
    );

    full_image_t make_full_image_from_biplanar_yuv_no_copy(
        // clang-format off
        const image_format& image_format,
        uint8_t* restrict lumo_buffer, int32_t lumo_row_stride, memory_deletter free_lumo,
        uint8_t* restrict chromo_buffer, int32_t chromo_row_stride, memory_deletter free_chromo,
        const yuv_format_t& yuv_format
        // clang-format on
    );

    full_image_t make_full_image_from_yuv_planes_no_copy(
        // clang-format off
        const image_format& image_format,
        uint8_t* restrict lumo_buffer, int32_t lumo_row_stride,
        int32_t lumo_pixel_stride, memory_deletter free_lumo,
        uint8_t* restrict chromo_1_buffer, int32_t chromo_1_row_stride, int32_t chromo_1_pixel_stride,
        uint8_t* restrict chromo_2_buffer, int32_t chromo_2_row_stride, int32_t chromo_2_pixel_stride,
        memory_deletter free_chromo_1, memory_deletter free_chromo_2,
        const yuv_format_t& yuv_format
        // clang-format on
    );

    color_plane convert_bpc8_to_y_plane(
        const bpc8_image_t& image, uint32_t width, uint32_t height);

    color_plane convert_bpc8_to_uv_plane(
        const bpc8_image_t& image, uint32_t width, uint32_t height, bool legacy_yuv = true);

    full_image_t convert_image_to_yuv(full_image_t input_image, bool legacy_yuv = true);

    color_plane convert_bgr_to_y_plane(unsigned char const* image, uint32_t width, uint32_t height);

    color_plane convert_bgr_to_uv_plane(unsigned char const* image, uint32_t width, uint32_t height);
} // namespace bnb
