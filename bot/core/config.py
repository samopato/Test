import os
from dotenv import load_dotenv

load_dotenv()

TOKEN = os.getenv('DISCORD_TOKEN')
DEBUG = os.getenv('DEBUG_MODE', 'False').lower() == 'true'

# You can even build paths here
BASE_DIR = os.path.dirname(os.path.abspath(__file__))