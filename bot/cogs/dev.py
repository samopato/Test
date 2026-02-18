import discord
from discord.ext import commands
import os

class Dev(commands.Cog):
    def __init__(self, bot: commands.Bot):
        self.bot = bot

    @commands.command(name="reload")
    @commands.is_owner()
    async def reload(self, ctx, extension: str):
        """Reloads a specific cog."""
        try:
            await self.bot.reload_extension(f"cogs.{extension}")
            await ctx.send(f"✅ Successfully reloaded `{extension}`")
        except Exception as e:
            await ctx.send(f"❌ Error: {e}")

    @commands.command(name="sync")
    @commands.is_owner()
    async def sync(self, ctx):
        """Manually sync slash commands."""
        await self.bot.tree.sync()
        await ctx.send("Syncing slash commands... check console for status.")

async def setup(bot):
    await bot.add_cog(Dev(bot))