# roblox.py
import discord
from discord.ext import commands
from discord import app_commands
import aiohttp
from core.logger import setup_logger

log = setup_logger("Roblox")

class Utility(commands.Cog):
    def __init__(self, bot: commands.Bot):
        self.bot = bot

    # Ping
    @app_commands.command(name = "ping", description = "Check the bot's response time")
    async def ping(self, interaction: discord.Interaction):
        latency = round(self.bot.latency * 1000) 

        embed = discord.Embed(
            title="🏓 Pong!",
            description=f"Latency: **{latency}ms**",
            color=discord.Color.green()
        )
            
        await interaction.response.send_message(embed=embed)

async def setup(bot):
    await bot.add_cog(Utility(bot))