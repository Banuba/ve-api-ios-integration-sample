/// \file
/// \addtogroup Utils
/// @{
///
// AUTOGENERATED FILE - DO NOT MODIFY!
// This file generated by Djinni from utils.djinni

#pragma once

#include <bnb/utils/defs.hpp>
#include <cstdint>

namespace bnb { namespace interfaces {

class BNB_EXPORT image_releaser {
public:
    virtual ~image_releaser() {}

    virtual void allocate_plane(int32_t amount) = 0;

    virtual void deallocate_plane() = 0;
};

} }  // namespace bnb::interfaces
/// @}

