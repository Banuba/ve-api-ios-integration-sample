/// \file
/// \addtogroup EffectPlayer
/// @{
///
// AUTOGENERATED FILE - DO NOT MODIFY!
// This file generated by Djinni from effect_player.djinni

#pragma once

#include <bnb/utils/defs.hpp>

namespace bnb { namespace interfaces {

struct effect_info;

/** Callback interface to receive effect info changes. */
class BNB_EXPORT effect_info_listener {
public:
    virtual ~effect_info_listener() {}

    /** Current effect information. */
    virtual void on_effect_info_updated(const effect_info & info) = 0;
};

} }  // namespace bnb::interfaces
/// @}
