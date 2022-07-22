/// \file
/// \addtogroup Scene
/// @{
///
// AUTOGENERATED FILE - DO NOT MODIFY!
// This file generated by Djinni from scene.djinni

#pragma once

#include <functional>

namespace bnb { namespace interfaces {

enum class texture_filtering_mode : int {
    point,
    linear,
    trilinear,
};

} }  // namespace bnb::interfaces

namespace std {

template <>
struct hash<::bnb::interfaces::texture_filtering_mode> {
    size_t operator()(::bnb::interfaces::texture_filtering_mode type) const {
        return std::hash<int>()(static_cast<int>(type));
    }
};

}  // namespace std
/// @}

