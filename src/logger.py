import sys
import loguru
import mininet.log

# Default logger level
LOG_LEVEL: str = "INFO"

# Mininet
mininet.log.setLogLevel(LOG_LEVEL.lower())

# Loguru
loguru.logger.configure(
    handlers=[
        dict(
            sink=sys.stdout,
            format="{time:HH:mm:ss.SSS} | <level>{level: <8}</level> | {message}",
            level=LOG_LEVEL.upper(),
        ),
        dict(sink="log.log", serialize=True, enqueue=True, level="TRACE"),
    ]
)

# Main logger
logger = loguru.logger
