import logging
import os

import structlog

debug_log_level = os.environ.get('DEBUG_LOG_LEVEL')
# Default log_level is INFO. Set to debug only if DEBUG_LOG_LEVEL is present and True.
log_level = logging.DEBUG if debug_log_level is not None and int(debug_log_level) == 1 else logging.INFO


def replace_event_with_message(_, __, event_dict):
    event_dict['message'] = event_dict['event']
    event_dict.pop('event')
    return event_dict


def log_level_uppercase(_, log_level, event_dict):
    event_dict['severity'] = log_level.upper()
    event_dict.pop('level')
    return event_dict


structlog.configure(
    processors=[
        # Add log level to the message
        structlog.processors.add_log_level,
        structlog.processors.TimeStamper(utc=True, fmt='ISO'),
        structlog.processors.StackInfoRenderer(),
        structlog.dev.set_exc_info,
        replace_event_with_message,
        log_level_uppercase,
        structlog.processors.JSONRenderer(sort_keys=True),
    ],
    # Set minimum log level
    wrapper_class=structlog.make_filtering_bound_logger(log_level),
    context_class=dict,
    logger_factory=structlog.PrintLoggerFactory(),
    cache_logger_on_first_use=False,
)
