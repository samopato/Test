import discord
import asyncio
import os
from discord.ext import commands
from colorama import Fore
from core import config
from core.logger import setup_logger, log_banner

log = setup_logger("Main")

class VexBot(commands.Bot):
    def __init__(self):
        intents = discord.Intents.default()
        intents.message_content = True
        super().__init__(
            command_prefix="!", 
            intents=intents
        )
        self.connected_clients = set()

    async def on_ready(self):
        """This runs when the bot is logged in."""

        text = f"""        ✓ {self.user}
        ✓ {self.user.id}
        ✓ Connected to {len(self.guilds)} guild(s)"""

        log_banner(text, "GREEN")      
        activity = discord.Activity(
            type=discord.ActivityType.watching,
            name="https://discord.gg/EqVFdatk5Y"
        )
        await self.change_presence(activity=activity, status=discord.Status.online)

    async def setup_hook(self):
        """This runs before the bot starts connecting to Discord."""
        log.info(f"Loading Cogs")
        
        for filename in os.listdir('./cogs'):
            if filename.endswith('.py'):
                cog_path = f'cogs.{filename[:-3]}'
                try:
                    await self.load_extension(cog_path)
                    log.info(f"Loaded: {cog_path}")
                except Exception as e:
                    log.error(f"Failed to load {cog_path}: {e}")
        
        await self.tree.sync()
        log.info(f"{Fore.BLUE}All Cogs Loaded & Synced")

# --- Execution ---

if __name__ == "__main__":
    try:
        log_banner("Starting VEX Discord Bot...")
        bot = VexBot()
        bot.owner_id = 1403524993056505966
        bot.run(config.TOKEN, log_handler = None)
    except KeyboardInterrupt:
        log.info(f"{Fore.YELLOW}Received keyboard interrupt, shutting down...")
    except Exception as e:
        log.critical(f"{Fore.RED}Fatal error: {e}", exc_info=True)
    finally:
        log.info(f"{Fore.YELLOW}Bot shutdown complete")