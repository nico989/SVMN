import sys
import loguru

# Console
loguru.logger.add(
    sys.stdout, format="{time} - {level} - {message}", colorize=True, level="INFO"
)

# File
loguru.logger.add("log_{time}.log")

logger = loguru.logger
