import os
import sys
import json
import discord
import logging
import asyncio # Added for better sync handling
import websockets
import webbrowser
from discord.ext import commands
from discord import app_commands # Crucial for slash commands
from dotenv import load_dotenv

#-----------------------------------
#-- Setup
#-----------------------------------
logging.basicConfig(level=logging.INFO)

ROBLOX_VEX_PATH = "/sdcard/Android/data/com.roblox.client/files/gloop/external/Workspace/vex"
BASE_DIR = os.path.join(ROBLOX_VEX_PATH, "bot")
DATA_DIR = os.path.join(BASE_DIR, '..', 'data')
SETTINGS_FILE = os.path.join(DATA_DIR, 'settings.json')

env_path = os.path.join(BASE_DIR, '.env')
load_dotenv(dotenv_path=env_path)
TOKEN = os.getenv('DISCORD_TOKEN')

outputChannel = bot.get_channel(1462534721517916465)

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
        self.connected_lua_clients = set()

    async def setup_hook(self):
        """ Runs when the bot starts to register Slash Commands. """
        print(f"📂 Loading data from: {DATA_DIR}")
        
        server = await websockets.serve(self.ws_handler, "127.0.0.1", 8765)
        print("🚀 WebSocket Server started on ws://127.0.0.1:8765")
        
        await self.tree.sync()
        print("✅ Slash commands synced.")

    async def ws_handler(self, websocket):
        """ Handles incoming Lua connections """
        await channel.send("🔗 Roblox client connected to WebSocket!")
        self.connected_lua_clients.add(websocket)
        try:
            await websocket.wait_closed()
        finally:
            self.connected_lua_clients.remove(websocket)
            await channel.send("❌ Roblox client disconnected.")

    async def on_message(self, message):
        """ Captures every message and sends it to Lua """
        if message.author.bot: return
            
        if message.channel.id != 1459426707025952859: return

        payload = json.dumps({
            "type": "chat",
            "author": message.author.name,
            "content": message.content
        })

        if self.connected_lua_clients:
            await asyncio.gather(*[client.send(payload) for client in self.connected_lua_clients])
        
        await self.process_commands(message)

    async def on_ready(self):
        print("\n" + "="*30)
        print(f"Logged in as: {self.user}")
        print(f"Latency:      {round(self.latency * 1000)}ms")
        print("="*30 + "\n")
        
        await self.change_presence(activity=discord.Activity(
            type=discord.ActivityType.watching, 
            name="VEX"
        ))

bot = VexBot()

# -----------------------------------
# 4. SLASH COMMANDS
# -----------------------------------

@bot.tree.command(name="ping", description="Checks the bot's latency")
async def ping(interaction: discord.Interaction):
    await interaction.response.send_message(f"**Pong!** ({round(bot.latency * 1000)}ms)")

@bot.tree.command(name="test", description="Opens Chrome on Android device")
async def test(interaction: discord.Interaction):
    url = "http://www.Google.com"
    webbrowser.get(chrome_path).open(url)

    await interaction.response.send_message("🌐 Opening browser on the device...", ephemeral=True)

@bot.tree.command(name="status", description="Shows the bot's current file path status")
async def status(interaction: discord.Interaction):
    if os.path.exists(SETTINGS_FILE):
        await interaction.response.send_message(f"✅ Settings file found at: `{SETTINGS_FILE}`")
    else:
        await interaction.response.send_message(f"❌ Could not find settings file at: `{SETTINGS_FILE}`")

@bot.tree.command(name="restart", description="Restarts the bot (Owner only)")
async def restart(interaction: discord.Interaction):
    # Manual check for owner since @commands.is_owner() doesn't work on tree commands directly
    if await bot.is_owner(interaction.user):
        await interaction.response.send_message("🔄 Restarting bot...")
        os.execv(sys.executable, [sys.executable] + sys.argv)
    else:
        await interaction.response.send_message("🚫 You do not have permission to restart the bot.", ephemeral=True)

# -----------------------------------
# 5. THE PANEL (V2 COMPONENTS)
# -----------------------------------

@bot.tree.command(name="panel", description="Opens the VEX control panel")
async def panel(interaction: discord.Interaction):
    # We keep your raw component data structure
    component_data = [
        {
            "type": 17, # Container
            "accent_color": 3447003, 
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

    # Instead of manual HTTP Route, we use the interaction response directly
    # Note: Type 17 components are experimental; if they fail to render via standard send_message,
    # the bot will fall back to your HTTP method.
    try:
        await interaction.response.send_message(components=component_data)
    except Exception as e:
        # Fallback to the manual POST if standard send_message rejects Type 17
        payload = {"components": component_data, "flags": 32768}
        route = discord.http.Route("POST", f"/channels/{interaction.channel_id}/messages")
        await bot.http.request(route, json=payload)
        await interaction.response.send_message("Panel deployed via HTTP fallback.", ephemeral=True)

# -----------------------------------
# 6. INTERACTION HANDLING
# -----------------------------------

@bot.event
async def on_interaction(interaction: discord.Interaction):
    # This handles both button clicks AND slash command registration
    if interaction.type == discord.InteractionType.component:
        cid = interaction.data.get("custom_id")
        
        if cid == "start_btn":
            await interaction.response.send_message("nao funciona ainda xd", ephemeral=True)
        elif cid == "player_select":
            selected = interaction.data.get("values")[0]
            await interaction.response.send_message(f"Selected: {selected}", ephemeral=True)

# -----------------------------------
# 7. EXECUTION
# -----------------------------------

if __name__ == "__main__":
    if not TOKEN:
        print("CRITICAL ERROR: 'DISCORD_TOKEN' not found in .env file.")
        sys.exit(1)
    
    try:
        bot.run(TOKEN)
    except Exception as e:
        print(f"Failed to start bot: {e}")








