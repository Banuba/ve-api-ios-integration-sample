/// \file
/// \addtogroup Types
/// @{
///
// AUTOGENERATED FILE - DO NOT MODIFY!
// This file generated by Djinni from types.djinni

#pragma once

#include <cstdint>
#include <utility>
#include <vector>

namespace bnb { namespace interfaces {

struct transformed_mask final {
    int32_t width;
    int32_t height;
    int32_t channel;
    bool inverse;
    /** (common -> mask) transformation */
    std::vector<float> basis_transform;

    transformed_mask(int32_t width_,
                     int32_t height_,
                     int32_t channel_,
                     bool inverse_,
                     std::vector<float> basis_transform_)
    : width(std::move(width_))
    , height(std::move(height_))
    , channel(std::move(channel_))
    , inverse(std::move(inverse_))
    , basis_transform(std::move(basis_transform_))
    {}
};

} }  // namespace bnb::interfaces
/// @}

