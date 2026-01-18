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
# -- Setup
# -----------------------------------
logging.basicConfig(level=logging.INFO)
load_dotenv()

TOKEN = os.getenv('DISCORD_TOKEN')
ROBLOX_COOKIE = os.getenv('ROBLOX_COOKIE')
LOG_CHANNEL_ID = 1462534721517916465

# Local state to track what the owner selected
# Format: { owner_id: {"place": 0, "job": "0", "name": "None"} }
selection_state = {}

# -----------------------------------
# -- Roblox Data Helpers
# -----------------------------------

def get_auth_id(cookie):
    try:
        r = requests.get("https://users.roblox.com/v1/users/authenticated", 
                         cookies={".ROBLOSECURITY": cookie}, timeout=5)
        return r.json().get('id') if r.status_code == 200 else None
    except: return None

MY_ROBLOX_ID = get_auth_id(ROBLOX_COOKIE)

def fetch_friends():
    """Fetches online friends and maps them to your JSON structure."""
    try:
        headers = {".ROBLOSECURITY": ROBLOX_COOKIE}
        f_resp = requests.get(f"https://friends.roblox.com/v1/users/{MY_ROBLOX_ID}/friends", 
                              cookies=headers, timeout=5)
        ids = [f["id"] for f in f_resp.json()["data"]]
        
        p_resp = requests.post("https://presence.roblox.com/v1/presence/users", 
                               json={"userIds": ids}, cookies=headers, timeout=5)
        
        options = []
        for p in p_resp.json()["userPresences"]:
            if p["userPresenceType"] in [1, 2]: # Online or In-Game
                icon = "🟢" if p["userPresenceType"] == 2 else "🔵"
                # Value format: UserID|PlaceID|JobID
                val = f"{p['userId']}|{p.get('placeId', 0)}|{p.get('gameId', '0')}"
                options.append({
                    "label": f"{p['lastUserName']}",
                    "value": val,
                    "description": f"{icon} {p.get('lastLocation', 'Online')[:50]}"
                })
        return options[:25]
    except: return []

# -----------------------------------
# -- The V2 Component Builder
# -----------------------------------

def build_v2_panel(accent_color, options, place_id="None", game_id="None", selected_val=None):
    """Returns the exact raw JSON structure for Type 17 components."""
    
    if not options:
        options = [{"label": "No friends online", "value": "null", "description": "Offline"}]

    # Set default in dropdown if selected
    if selected_val:
        for opt in options:
            opt["default"] = (opt["value"] == selected_val)

    return [
        {
            "type": 17, # Container
            "accent_color": accent_color,
            "components": [
                {
                    "type": 12, # Media
                    "items": [{"media": {"url": "https://cdn.discohook.app/tenor/trump-laugh-gif-16069436437887441139.gif"}}]
                },
                {"type": 14, "divider": True},
                {
                    "type": 10, # Text Section
                    "content": f"📊 **SESSION STATS**\n**PlaceID:** `{place_id}`\n**GameID:** `{game_id}`"
                },
                {
                    "type": 1, # Action Row
                    "components": [
                        {
                            "type": 3, # Select Menu
                            "custom_id": "vex_player_select",
                            "placeholder": "Select a target player...",
                            "options": options,
                            "min_values": 1,
                            "max_values": 1
                        }
                    ]
                },
                {
                    "type": 1, # Action Row
                    "components": [
                        {"type": 2, "style": 3, "label": "Start", "custom_id": "vex_start_btn"},
                        {"type": 2, "style": 1, "label": "Rejoin", "custom_id": "vex_rejoin_btn"},
                        {"type": 2, "style": 5, "label": "Join BOT", "url": "https://discohook.app", "disabled": True}
                    ]
                }
            ]
        }
    ]

# -----------------------------------
# -- Bot Core
# -----------------------------------

class VexBot(commands.Bot):
    def __init__(self):
        super().__init__(command_prefix="!", intents=discord.Intents.all())
        self.connected_clients = set()

    async def setup_hook(self):
        # Start WebSocket as background task
        self.loop.create_task(self.start_ws())
        await self.tree.sync()

    async def start_ws(self):
        async with websockets.serve(self.ws_handler, "127.0.0.1", 8765, reuse_address=True):
            await asyncio.Future()

    async def ws_handler(self, ws):
        self.connected_clients.add(ws)
        log_ch = self.get_channel(LOG_CHANNEL_ID)
        if log_ch: await log_ch.send("🔗 **WebSocket Client Connected**")
        try:
            await ws.wait_closed()
        finally:
            if ws in self.connected_clients: self.connected_clients.remove(ws)
            if log_ch: await log_ch.send("❌ **WebSocket Client Disconnected**")

bot = VexBot()

# -----------------------------------
# -- Command & Interaction Handlers
# -----------------------------------

@bot.tree.command(name="panel", description="Owner Only: Spawn the V2 Control Panel")
async def panel(interaction: discord.Interaction):
    if not await bot.is_owner(interaction.user):
        return await interaction.response.send_message("🚫 Access Denied.", ephemeral=True)

    await interaction.response.defer()
    
    options = fetch_friends()
    # Initial color: Red (16711680)
    components = build_v2_panel(16711680, options)

    # Use raw HTTP POST to send Type 17 components
    route = discord.http.Route("POST", f"/webhooks/{bot.user.id}/{interaction.token}")
    try:
        await bot.http.request(route, json={"components": components})
    except Exception as e:
        print(f"Error sending V2 Panel: {e}")
        await interaction.followup.send("Failed to render V2 Panel. Ensure your bot has V2 Component access.")

@bot.event
async def on_interaction(interaction: discord.Interaction):
    if interaction.type != discord.InteractionType.component:
        return

    cid = interaction.data.get("custom_id")
    uid = interaction.user.id

    # 1. Handle Select Menu
    if cid == "vex_player_select":
        val = interaction.data.get("values")[0]
        if val == "null": return

        parts = val.split("|")
        p_id, j_id = parts[1], parts[2]
        
        # Determine Color: Green if in-game, Blue if online
        new_color = 3447003 if int(p_id) > 0 else 32526
        selection_state[uid] = {"place": p_id, "job": j_id, "val": val}

        # Edit message with raw JSON to update stats/color
        options = fetch_friends()
        new_json = build_v2_panel(new_color, options, p_id, j_id, val)
        
        await interaction.response.edit_message(components=new_json)

    # 2. Handle Start Button
    elif cid == "vex_start_btn":
        data = selection_state.get(uid)
        if not data or int(data["place"]) == 0:
            return await interaction.response.send_message("❌ Selection is not in a game.", ephemeral=True)
        
        webbrowser.open(f"roblox://placeId={data['place']}&gameInstanceId={data['job']}")
        await interaction.response.send_message(f"🚀 Joining {data['place']}...", ephemeral=True)

    # 3. Handle Rejoin Button
    elif cid == "vex_rejoin_btn":
        if not bot.connected_clients:
            return await interaction.response.send_message("❌ No Lua clients connected.", ephemeral=True)
        
        # Broadcast via WebSocket
        payload = json.dumps({"type": "rejoin"})
        for ws in list(bot.connected_clients):
            try:
                await ws.send(payload)
            except:
                bot.connected_clients.remove(ws)
        
        await interaction.response.send_message("🔄 Rejoin broadcast sent.", ephemeral=True)

if __name__ == "__main__":
    bot.run(TOKEN)
