/// \file
/// \addtogroup Types
/// @{
///
// AUTOGENERATED FILE - DO NOT MODIFY!
// This file generated by Djinni from types.djinni

#pragma once

#include "bnb/types/interfaces/transformed_mask.hpp"
#include <utility>
#include <vector>

namespace bnb { namespace interfaces {

struct transformed_mask_float final {
    transformed_mask meta;
    std::vector<float> mask;

    transformed_mask_float(transformed_mask meta_,
                           std::vector<float> mask_)
    : meta(std::move(meta_))
    , mask(std::move(mask_))
    {}
};

} }  // namespace bnb::interfaces
/// @}
