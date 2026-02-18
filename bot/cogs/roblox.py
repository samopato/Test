# roblox.py
import discord
from discord.ext import commands
from discord import app_commands
import aiohttp
import core.config
from core.logger import setup_logger

log = setup_logger("Roblox")

class Roblox(commands.Cog):
    def __init__(self, bot):
        self.bot = bot
        self.selection_state = {}

    def fetch_friends(self):
        # ... Move your fetch_friends code here ...
        # Use config.ROBLOX_COOKIE instead of the global variable
        pass

    @app_commands.command(name="panel", description="Spawn the V2 Control Panel")
    async def panel(self, interaction: discord.Interaction):
        if not await self.bot.is_owner(interaction.user):
            return await interaction.response.send_message("Owner only!", ephemeral=True)
        
        await interaction.response.send_message("Creating panel...", ephemeral=True)
        log.info(f"Panel created in {interaction.channel.id}")

async def setup(bot):
    await bot.add_cog(Roblox(bot))