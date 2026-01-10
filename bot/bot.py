import os
import sys
import json
import discord
import logging
from discord.ext import commands
from dotenv import load_dotenv

#-----------------------------------
#-- Setup
#-----------------------------------

# Setup logging (Makes debugging much easier on Pydroid)
logging.basicConfig(level=logging.INFO)

# Load environment variables from .env file
load_dotenv()
TOKEN = os.getenv('DISCORD_TOKEN')

# Define paths to other important folders
# (This allows the bot to find 'data/settings.json' easily)
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
DATA_DIR = os.path.join(BASE_DIR, '..', 'data')
SETTINGS_FILE = os.path.join(DATA_DIR, 'settings.json')

#-----------------------------------
#-- Bot class
#-----------------------------------

class VexBot(commands.Bot):
    def __init__(self):
        # Define Intents (Permissions)
        intents = discord.Intents.default()
        intents.message_content = True 

        super().__init__(
            command_prefix="!", 
            intents=intents,
            help_command=commands.DefaultHelpCommand()
        )

    async def setup_hook(self):
        """
        This runs once when the bot starts.
        Great place to load extensions (Cogs) or sync commands.
        """
        print(f"📂 Loading data from: {DATA_DIR}")
        # self.load_settings() # (Optional: You can add a function to load JSON here)

    async def on_ready(self):
        """
        Runs when the bot has successfully connected to Discord.
        """
        print("\n" + "="*30)
        print(f"Logged in as: {self.user}")
        print(f"Bot ID:      {self.user.id}")
        print(f"Latency:     {round(self.latency * 1000)}ms")
        print("="*30 + "\n")
        
        # Set a custom status (e.g., "Watching Vex Admin")
        await self.change_presence(activity=discord.Activity(
            type=discord.ActivityType.watching, 
            name="Vex Admin Panel"
        ))

# -----------------------------------
# 3. INITIALIZATION
# -----------------------------------

bot = VexBot()

# -----------------------------------
# 4. COMMANDS
# -----------------------------------

@bot.command(name="ping")
async def ping(ctx):
    """Checks if the bot is responsive."""
    await ctx.send(f"**Pong!** ({round(bot.latency * 1000)}ms)")

@bot.command(name="status")
async def status(ctx):
    """Shows the bot's current file path status."""
    if os.path.exists(SETTINGS_FILE):
        await ctx.send(f"Settings file found at: `{SETTINGS_FILE}`")
    else:
        await ctx.send(f"Could not find settings file at: `{SETTINGS_FILE}`")

# -----------------------------------
# 5. ERROR HANDLING
# -----------------------------------

@bot.event
async def on_command_error(ctx, error):
    """ Catches errors globally so the bot doesn't crash. """
    if isinstance(error, commands.CommandNotFound):
        return  # Ignore random/wrong commands
    
    # Send a pretty error message to Discord
    embed = discord.Embed(title="Error", description=str(error), color=discord.Color.red())
    await ctx.send(embed=embed)
    print(f"ERROR: {error}")

# -----------------------------------
# 6. MAIN EXECUTION
# -----------------------------------

if __name__ == "__main__":
    if not TOKEN:
        print("CRITICAL ERROR: 'DISCORD_TOKEN' not found in .env file.")
        sys.exit(1)
    
    try:
        bot.run(TOKEN)
    except Exception as e:
        print(f"Failed to start bot: {e}")