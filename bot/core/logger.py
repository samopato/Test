import logging
import sys
from colorama import Fore, Back, Style, init

# Initialize colorama
init(autoreset=True)

class ColoredFormatter(logging.Formatter):
    COLORS = {
        'DEBUG': Fore.CYAN,
        'INFO': Fore.GREEN,
        'WARNING': Fore.YELLOW,
        'ERROR': Fore.RED,
        'CRITICAL': Fore.RED + Back.WHITE + Style.BRIGHT,
    }

    def format(self, record):
        levelname = record.levelname
        if levelname in self.COLORS:
            record.levelname = f"{self.COLORS[levelname]}{levelname}{Style.RESET_ALL}"
        record.name = f"{Fore.MAGENTA}{record.name}{Style.RESET_ALL}"
        return super().format(record)

def setup_logger(name):
    """Function to create a logger instance easily."""
    logger = logging.getLogger(name)
    
    # Only add handlers if they don't exist (prevents double logs)
    if not logger.handlers:
        handler = logging.StreamHandler(sys.stdout)
        formatter = ColoredFormatter(
            '%(asctime)s - %(name)s - %(levelname)s - %(message)s',
            datefmt='%Y-%m-%d %H:%M:%S'
        )
        handler.setFormatter(formatter)
        logger.addHandler(handler)
        logger.setLevel(logging.INFO)
        
    return logger

def log_banner(text, color_name="CYAN"):
    color = getattr(Fore, color_name.upper(), Fore.WHITE)
    
    print(f"\n{color}{'='*40}")
    print(f"{color}{text.center(40)}")
    print(f"{color}{'='*40}{Style.RESET_ALL}\n")