#pragma once

#include <bnb/utils/interfaces/all.hpp>
#include <memory>

namespace bnb::interfaces
{
    using image_releaser_sptr = std::shared_ptr<image_releaser>;
    using image_releaser_wptr = std::weak_ptr<image_releaser>;
    using image_releaser_uptr = std::unique_ptr<image_releaser>;
    using image_releaser_ptr = bnb::interfaces::image_releaser*;

    using log_record_callback_sptr = std::shared_ptr<log_record_callback>;
    using log_record_callback_wptr = std::weak_ptr<log_record_callback>;
    using log_record_callback_uptr = std::unique_ptr<log_record_callback>;
    using log_record_callback_ptr = bnb::interfaces::log_record_callback*;

}
