import sys
import loguru
import mininet.log

# Mininet
mininet.log.setLogLevel("info")

# Console
loguru.logger.add(
    sys.stdout, format="{time} - {level} - {message}", colorize=True, level="INFO"
)

# File
loguru.logger.add("log_{time}.log")

logger = loguru.logger
