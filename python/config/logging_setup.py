"""
Simple logging setup for the application.

"""

import logging
from config.settings import LOG_DIR, LOG_LEVEL

# Create logger
def get_logger(name: str) -> logging.Logger:
    """
    Get a logger for the given module.

    Usage in your modules:
        from config.logging_setup import get_logger
        logger = get_logger(__name__)
        logger.error("Something went wrong!")
        logger.warning("Be careful!")
    """
    logger = logging.getLogger(name)

    # Only configure if not already configured
    if logger.handlers:
        return logger

    logger.setLevel(LOG_LEVEL)

    # Format: timestamp - module name - level - message
    formatter = logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s')

    # 1. File handler for errors
    error_file = LOG_DIR / 'errors.log'
    error_handler = logging.FileHandler(error_file)
    error_handler.setLevel(logging.ERROR)
    error_handler.setFormatter(formatter)
    logger.addHandler(error_handler)

    # 2. File handler for warnings and above
    warning_file = LOG_DIR / 'warnings.log'
    warning_handler = logging.FileHandler(warning_file)
    warning_handler.setLevel(logging.WARNING)
    warning_handler.setFormatter(formatter)
    logger.addHandler(warning_handler)

    info_file = LOG_DIR / 'info.log'
    info_handler = logging.FileHandler(info_file)
    info_handler.setLevel(logging.INFO)
    info_handler.setFormatter(formatter)
    logger.addHandler(info_handler)


    # 3. Console handler (optional - shows in terminal)
    console_handler = logging.StreamHandler()
    console_handler.setLevel(logging.WARNING)
    console_handler.setFormatter(formatter)
    logger.addHandler(console_handler)


    return logger