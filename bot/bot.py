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

logging.basicConfig(level=logging.INFO)

ROBLOX_VEX_PATH = "/sdcard/Android/data/com.roblox.client/files/gloop/external/Workspace/vex"

BASE_DIR = os.path.join(ROBLOX_VEX_PATH, "bot")

print(BASE_DIR)

DATA_DIR = os.path.join(BASE_DIR, '..', 'data')
SETTINGS_FILE = os.path.join(DATA_DIR, 'settings.json')

env_path = os.path.join(BASE_DIR, '.env')

load_dotenv(dotenv_path=env_path)
TOKEN = os.getenv('DISCORD_TOKEN')

print(env_path)

#-----------------------------------
#-- Bot class
#-----------------------------------

class VexBot(commands.Bot):
    def __init__(self):
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

        await self.change_presence(activity=discord.Activity(
            type=discord.ActivityType.watching, 
            name="VEX"
        ))

# -----------------------------------
# 3. INITIALIZATION
# -----------------------------------

bot = VexBot()

# -----------------------------------
# 4. COMMANDS
# -----------------------------------


@bot.event
async def on_interaction(interaction: discord.Interaction):
    if interaction.type == discord.InteractionType.component:
        cid = interaction.data.get("custom_id")
        
        if cid == "start_btn":
            await interaction.response.send_message("Starting...", ephemeral=True)
        elif cid == "player_select":
            selected = interaction.data.get("values")[0]
            await interaction.response.send_message(f"Selected: {selected}", ephemeral=True)

@bot.command()
async def panel(ctx):
    # Your JSON structure converted to a Python Dictionary
    component_data = [
        {
            "type": 17,
            "accent_color": 3447003, # Optional: Blue color
            "components": [
                {"type": 12, "items": [{"media": {"url": "https://cdn.discohook.app/tenor/trump-laugh-gif-16069436437887441139.gif"}}]},
                {"type": 14, "divider": True},
                {"type": 10, "content": "**Player to join**"},
                {
                    "type": 1,
                    "components": [
                        {
                            "type": 3,
                            "custom_id": "player_select",
                            "placeholder": "Choose a player...",
                            "options": [
                                {"label": "JustinBiever79070", "value": "justin_id"}
                            ]
                        }
                    ]
                },
                {
                    "type": 1,
                    "components": [
                        {"type": 2, "style": 1, "label": "Start", "custom_id": "start_btn"},
                        {"type": 2, "style": 1, "label": "Rejoin", "custom_id": "rejoin_btn"}
                    ]
                }
            ]
        }
    ]

    flags = discord.MessageFlags()
    
    flags.value = 32768 

    await ctx.send(components=component_data, flags=flags)

@bot.command(name="ping")
async def ping(ctx):
    """Checks if the bot is responsive."""
    await ctx.send(f"**Pong!** ({round(bot.latency * 1000)}ms)")

@bot.command(name="test")
async def test(ctx: commands.Context):
	url = "https://www.discord.com"
	os.system(f"am start -a android.intent.action.VIEW -d {url}")
	await ctx.send("Teste pra abrir o chrome")

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
        return
    
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
