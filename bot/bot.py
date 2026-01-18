import os
import sys
import json
import discord
import logging
import asyncio
import websockets
import webbrowser
import requests
from discord.ext import commands
from discord import app_commands
from dotenv import load_dotenv

# -----------------------------------
# -- Setup & Configuration
# -----------------------------------
logging.basicConfig(level=logging.INFO)

# Define Paths
ROBLOX_VEX_PATH = "/sdcard/Android/data/com.roblox.client/files/gloop/external/Workspace/vex"
BASE_DIR = os.path.join(ROBLOX_VEX_PATH, "bot")
DATA_DIR = os.path.join(BASE_DIR, '..', 'data')
env_path = os.path.join(BASE_DIR, '.env')

load_dotenv(dotenv_path=env_path)

# Credentials
TOKEN = os.getenv('DISCORD_TOKEN')
ROBLOX_COOKIE = os.getenv('ROBLOX_COOKIE')

# State Handling
user_selections = {}  # Stores {user_id: {place_id, job_id, color}}

# -----------------------------------
# -- Helper Functions
# -----------------------------------

def get_authenticated_user(cookie):
    """Automatically gets your Roblox ID from the cookie."""
    try:
        resp = requests.get(
            "https://users.roblox.com/v1/users/authenticated",
            cookies={".ROBLOSECURITY": cookie}
        )
        if resp.status_code == 200:
            user = resp.json()
            print(f"✅ Authenticated as: {user['name']} ({user['id']})")
            return user['id']
    except Exception as e:
        print(f"❌ Auth Error: {e}")
    return None

# Load ID immediately
MY_ROBLOX_ID = get_authenticated_user(ROBLOX_COOKIE) if ROBLOX_COOKIE else None

def get_roblox_friends():
    """Fetches online friends for the dropdown."""
    if not MY_ROBLOX_ID or not ROBLOX_COOKIE:
        return []

    try:
        # 1. Get Friend List
        friends_resp = requests.get(
            f"https://friends.roblox.com/v1/users/{MY_ROBLOX_ID}/friends",
            cookies={".ROBLOSECURITY": ROBLOX_COOKIE}
        )
        friend_ids = [f["id"] for f in friends_resp.json()["data"]]

        if not friend_ids: return []

        # 2. Check Presence
        presence_resp = requests.post(
            "https://presence.roblox.com/v1/presence/users",
            json={"userIds": friend_ids},
            cookies={".ROBLOSECURITY": ROBLOX_COOKIE}
        )
        
        options = []
        for p in presence_resp.json()["userPresences"]:
            # 2 = In Game, 1 = Online, 0 = Offline
            if p["userPresenceType"] in [1, 2]:
                status_icon = "🟢" if p["userPresenceType"] == 2 else "🔵"
                desc = p.get("lastLocation", "Browsing Website")
                
                # Value format: "UserID|PlaceID|JobID"
                val = f"{p['userId']}|{p.get('placeId', 0)}|{p.get('gameId', '0')}"
                
                options.append({
                    "label": f"{status_icon} {p['lastUserName']}",
                    "value": val,
                    "description": desc[:100]
                })
        return options[:25] # Discord limit
    except Exception as e:
        print(f"API Error: {e}")
        return []

def build_panel_payload(color, options, selected_value=None):
    """Constructs the JSON for the Type 17 component panel."""
    
    # If options is empty (no friends online), add a placeholder
    if not options:
        options = [{"label": "No friends online", "value": "null", "description": "Try again later"}]

    # Mark the selected option as default if one exists
    if selected_value:
        for opt in options:
            if opt["value"] == selected_value:
                opt["default"] = True
            else:
                opt["default"] = False

    return [
        {
            "type": 17, # Container
            "accent_color": color, 
            "components": [
                {"type": 12, "items": [{"media": {"url": "https://cdn.discohook.app/tenor/trump-laugh-gif-16069436437887441139.gif"}}]},
                {"type": 14, "divider": True},
                {"type": 10, "content": "**Player to join**"},
                {
                    "type": 1,
                    "components": [{
                        "type": 3,
                        "custom_id": "player_select",
                        "placeholder": "Choose a player...",
                        "options": options
                    }]
                },
                {
                    "type": 1,
                    "components": [
                        {"type": 2, "style": 1, "label": "Start", "custom_id": "start_btn"},
                        {"type": 2, "style": 4, "label": "Rejoin", "custom_id": "rejoin_btn"}
                    ]
                }
            ]
        }
    ]

# -----------------------------------
# -- Bot Class
# -----------------------------------

class VexBot(commands.Bot):
    def __init__(self):
        super().__init__(
            command_prefix="!", 
            intents=discord.Intents.all(),
            help_command=commands.DefaultHelpCommand()
        )
        self.connected_clients = set()

    async def setup_hook(self):
        # Start WebSocket Server
        await websockets.serve(self.ws_handler, "127.0.0.1", 8765, reuse_address=True)
        print("🚀 WebSocket Server listening on ws://127.0.0.1:8765")
        await self.tree.sync()

    async def ws_handler(self, websocket):
        self.connected_clients.add(websocket)
        channel = self.get_channel(1462534721517916465)
        if channel: await channel.send("🔗 Roblox Connected!")
        
        try:
            await websocket.wait_closed()
        finally:
            self.connected_clients.remove(websocket)
            if channel: await channel.send("❌ Roblox Disconnected.")

    async def on_message(self, message):
        if message.author.bot or message.channel.id != 1459426707025952859:
            return

        payload = json.dumps({
            "type": "chat",
            "author": message.author.name,
            "content": message.content
        })
        
        if self.connected_clients:
            await asyncio.gather(*[c.send(payload) for c in self.connected_clients], return_exceptions=True)

        await self.process_commands(message)

bot = VexBot()

# -----------------------------------
# -- Slash Commands
# -----------------------------------

@bot.tree.command(name="panel", description="Opens the VEX control panel")
async def panel(interaction: discord.Interaction):
    await interaction.response.defer()
    
    options = get_roblox_friends()
    
    # Default Color: Red (16711680) because no one is selected yet
    components = build_panel_payload(16711680, options)

    # Use HTTP fallback to send experimental components
    try:
        route = discord.http.Route("POST", f"/webhooks/{bot.user.id}/{interaction.token}/messages/@original")
        await bot.http.request(route, json={"components": components})
    except Exception as e:
        await interaction.followup.send(f"Failed to render panel: {e}")

@bot.tree.command(name="restart", description="Restarts the bot")
async def restart(interaction: discord.Interaction):
    await interaction.response.send_message("🔄 Restarting...")
    os.execv(sys.executable, [sys.executable] + sys.argv)

# -----------------------------------
# -- Interaction Handler (The Brain)
# -----------------------------------

@bot.event
async def on_interaction(interaction: discord.Interaction):
    if interaction.type != discord.InteractionType.component:
        return

    cid = interaction.data.get("custom_id")
    
    # --- 1. Dropdown Selection ---
    if cid == "player_select":
        selected_val = interaction.data.get("values")[0]
        
        if selected_val == "null":
            await interaction.response.send_message("No friend selected.", ephemeral=True)
            return

        # Parse Data: UserID | PlaceID | JobID
        parts = selected_val.split("|")
        place_id = int(parts[1])
        
        # Determine Color: Green (3447003) if In-Game, Blue (32526) if Online
        new_color = 3447003 if place_id > 0 else 32526
        
        # Save selection state
        user_selections[interaction.user.id] = {
            "val": selected_val,
            "place": place_id,
            "job": parts[2]
        }

        # Re-fetch options to rebuild the UI with the new color
        # (We cache options briefly in a real app, but here we fetch fresh to be safe)
        options = get_roblox_friends()
        new_components = build_panel_payload(new_color, options, selected_val)

        # Update the panel visually
        try:
            await interaction.response.edit_message(components=new_components)
        except:
            await interaction.response.send_message("Selection saved (UI update failed).", ephemeral=True)

    # --- 2. Start Button ---
    elif cid == "start_btn":
        data = user_selections.get(interaction.user.id)
        
        if not data:
            await interaction.response.send_message("⚠️ Select a player first!", ephemeral=True)
            return

        if data["place"] == 0:
            await interaction.response.send_message("⚠️ Player is online but not in a game.", ephemeral=True)
            return

        # Launch Roblox
        url = f"roblox://placeId={data['place']}&gameInstanceId={data['job']}"
        webbrowser.open(url)
        await interaction.response.send_message(f"🚀 Joining game...", ephemeral=True)

    # --- 3. Rejoin Button (WebSocket) ---
    elif cid == "rejoin_btn":
        if not bot.connected_clients:
            await interaction.response.send_message("❌ No Roblox client connected.", ephemeral=True)
            return
            
        payload = json.dumps({"type": "rejoin"})
        await asyncio.gather(*[c.send(payload) for c in bot.connected_clients], return_exceptions=True)
        await interaction.response.send_message("🔄 Sent REJOIN command.", ephemeral=True)

# -----------------------------------
# -- Run
# -----------------------------------
if __name__ == "__main__":
    if not TOKEN:
        print("CRITICAL: Missing DISCORD_TOKEN in .env")
    else:
        bot.run(TOKEN)
