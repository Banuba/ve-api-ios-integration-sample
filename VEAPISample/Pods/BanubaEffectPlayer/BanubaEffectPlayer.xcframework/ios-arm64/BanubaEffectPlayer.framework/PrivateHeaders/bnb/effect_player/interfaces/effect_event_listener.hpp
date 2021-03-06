/// \file
/// \addtogroup EffectPlayer
/// @{
///
// AUTOGENERATED FILE - DO NOT MODIFY!
// This file generated by Djinni from effect_player.djinni

#pragma once

#include <bnb/utils/defs.hpp>
#include <string>
#include <unordered_map>

namespace bnb { namespace interfaces {

/** Callback interface for effect events. */
class BNB_EXPORT effect_event_listener {
public:
    virtual ~effect_event_listener() {}

    /**
     * Callback function for custom effect events.
     * Function that is to be invoked by effect on certain events (e.g. analytics).
     *
     * @note The function is executed in Render thread.
     *
     * @param name event name
     * @param params map of (string, string) which describes events parameters (key-value pairs)
     */
    virtual void on_effect_event(const std::string & name, const std::unordered_map<std::string, std::string> & params) = 0;
};

} }  // namespace bnb::interfaces
/// @}

