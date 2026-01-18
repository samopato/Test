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
load_dotenv()

TOKEN = os.getenv('DISCORD_TOKEN')
ROBLOX_COOKIE = os.getenv('ROBLOX_COOKIE')

# Webhook/Channel IDs
LOG_CHANNEL_ID = 1462534721517916465

# -----------------------------------
# -- Roblox Data Helpers
# -----------------------------------

def get_auth_id(cookie):
    try:
        r = requests.get("https://users.roblox.com/v1/users/authenticated", cookies={".ROBLOSECURITY": cookie}, timeout=5)
        return r.json().get('id') if r.status_code == 200 else None
    except: return None

MY_ROBLOX_ID = get_auth_id(ROBLOX_COOKIE)

def get_friend_options():
    """Fetches online friends for the dropdown."""
    try:
        f_resp = requests.get(f"https://friends.roblox.com/v1/users/{MY_ROBLOX_ID}/friends", cookies={".ROBLOSECURITY": cookie}, timeout=5)
        ids = [f["id"] for f in f_resp.json()["data"]]
        p_resp = requests.post("https://presence.roblox.com/v1/presence/users", json={"userIds": ids}, cookies={".ROBLOSECURITY": cookie}, timeout=5)
        
        options = []
        for p in p_resp.json()["userPresences"]:
            if p["userPresenceType"] in [1, 2]:
                icon = "🟢" if p["userPresenceType"] == 2 else "🔵"
                val = f"{p['userId']}|{p.get('placeId', 0)}|{p.get('gameId', '0')}"
                options.append({"label": f"{icon} {p['lastUserName']}", "value": val, "description": p.get("lastLocation", "Online")[:100]})
        return options[:25]
    except: return []

def create_panel_json(color, options, selected_val=None, place_id="None", game_id="None"):
    """
    Constructs the experimental Type 17 Panel.
    Includes the new Stats section for PlaceID and GameID.
    """
    if not options:
        options = [{"label": "No friends online", "value": "null"}]
    
    if selected_val:
        for opt in options:
            opt["default"] = (opt["value"] == selected_val)

    return [{
        "type": 17, 
        "accent_color": color,
        "components": [
            {"type": 12, "items": [{"media": {"url": "https://cdn.discohook.app/tenor/trump-laugh-gif-16069436437887441139.gif"}}]},
            {"type": 14, "divider": True},
            {"type": 10, "content": f"📊 **SESSION STATS**\n**PlaceID:** `{place_id}`\n**GameID:** `{game_id}`"},
            {"type": 14, "divider": True},
            {"type": 1, "components": [{"type": 3, "custom_id": "player_select", "options": options, "placeholder": "Select target player..."}]},
            {"type": 1, "components": [
                {"type": 2, "style": 1, "label": "Start Join", "custom_id": "start_btn"},
                {"type": 2, "style": 4, "label": "Force Rejoin", "custom_id": "rejoin_btn"}
            ]}
        ]
    }]

# -----------------------------------
# -- Bot Core
# -----------------------------------

class VexBot(commands.Bot):
    def __init__(self):
        super().__init__(command_prefix="!", intents=discord.Intents.all())
        self.connected_clients = set()
        self.current_selection = {} # Stores {user_id: {place, job, val}}

    async def setup_hook(self):
        self.loop.create_task(self.start_ws())
        await self.tree.sync()

    async def start_ws(self):
        try:
            async with websockets.serve(self.ws_handler, "127.0.0.1", 8765, reuse_address=True):
                await asyncio.Future()
        except Exception as e:
            logging.error(f"WebSocket Server Error: {e}")

    async def ws_handler(self, ws):
        self.connected_clients.add(ws)
        log_ch = self.get_channel(LOG_CHANNEL_ID)
        if log_ch: await log_ch.send("🔗 **Client linked to VEX WebSocket**")
        try:
            await ws.wait_closed()
        finally:
            self.connected_clients.remove(ws)
            if log_ch: await log_ch.send("❌ **Client unlinked from WebSocket**")

bot = VexBot()

# -----------------------------------
# -- Commands & Logic
# -----------------------------------

@bot.tree.command(name="panel", description="Owner Only: Deployment of the VEX Panel")
async def panel(interaction: discord.Interaction):
    # Owner Security Check
    if not await bot.is_owner(interaction.user):
        return await interaction.response.send_message("🚫 Developer access only.", ephemeral=True)

    await interaction.response.defer()
    options = get_friend_options()
    
    # Color Red (16711680) - Idle State
    components = create_panel_json(16711680, options)
    
    # Use Webhook Route for Type 17 rendering
    route = discord.http.Route("POST", f"/webhooks/{bot.user.id}/{interaction.token}")
    await bot.http.request(route, json={"components": components})

@bot.event
async def on_interaction(interaction: discord.Interaction):
    if interaction.type != discord.InteractionType.component:
        return

    cid = interaction.data.get("custom_id")
    uid = interaction.user.id

    # -- HANDLE SELECT MENU --
    if cid == "player_select":
        val = interaction.data.get("values")[0]
        if val == "null": return
        
        parts = val.split("|")
        p_id, j_id = parts[1], parts[2]
        
        # Determine UI color: Green if in-game, Blue if online
        new_color = 3447003 if int(p_id) > 0 else 32526
        
        # Update local bot state
        bot.current_selection[uid] = {"place": p_id, "job": j_id, "val": val}

        # Update the Panel with Stats and Color
        options = get_friend_options()
        new_comps = create_panel_json(new_color, options, val, p_id, j_id)
        
        try:
            await interaction.response.edit_message(components=new_comps)
        except discord.HTTPException:
            # Fallback for experimental component timeout
            pass

    # -- HANDLE START BUTTON --
    elif cid == "start_btn":
        data = bot.current_selection.get(uid)
        if not data or int(data["place"]) == 0:
            return await interaction.response.send_message("❌ Target not in a joinable session.", ephemeral=True)
        
        # Use roblox protocol to join
        webbrowser.open(f"roblox://placeId={data['place']}&gameInstanceId={data['job']}")
        await interaction.response.send_message(f"🚀 Launching Join: {data['place']}", ephemeral=True)

    # -- HANDLE REJOIN BUTTON --
    elif cid == "rejoin_btn":
        if not bot.connected_clients:
            return await interaction.response.send_message("❌ No Lua clients connected.", ephemeral=True)
        
        # WebSocket Broadcast
        disconnected = set()
        for ws in bot.connected_clients:
            try:
                await ws.send(json.dumps({"type": "rejoin"}))
            except:
                disconnected.add(ws)
        
        bot.connected_clients -= disconnected
        await interaction.response.send_message("🔄 Rejoin request sent to all clients.", ephemeral=True)

# -----------------------------------
# -- Error Handling
# -----------------------------------
@bot.tree.error
async def on_app_command_error(interaction: discord.Interaction, error: app_commands.AppCommandError):
    logging.error(f"Interaction Error: {error}")
    if not interaction.response.is_done():
        await interaction.response.send_message("⚠️ An internal error occurred.", ephemeral=True)

if __name__ == "__main__":
    if not TOKEN:
        print("CRITICAL: DISCORD_TOKEN is missing from .env")
    else:
        bot.run(TOKEN)
