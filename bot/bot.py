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
from typing import Dict, Set, Optional, List

# -----------------------------------
# -- Setup & Configuration
# -----------------------------------
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

load_dotenv()

# Environment variables with validation
TOKEN = os.getenv('DISCORD_TOKEN')
ROBLOX_COOKIE = os.getenv('ROBLOX_COOKIE')
LOG_CHANNEL_ID = int(os.getenv('LOG_CHANNEL_ID', '1462534721517916465'))
WS_HOST = os.getenv('WS_HOST', '127.0.0.1')
WS_PORT = int(os.getenv('WS_PORT', '8765'))

if not TOKEN:
    raise ValueError("DISCORD_TOKEN not found in environment variables")
if not ROBLOX_COOKIE:
    raise ValueError("ROBLOX_COOKIE not found in environment variables")

# Local state to track user selections
# Format: { owner_id: {"place": str, "job": str, "val": str} }
selection_state: Dict[int, Dict[str, str]] = {}

# -----------------------------------
# -- Roblox Data Helpers
# -----------------------------------

def get_auth_id(cookie: str) -> Optional[int]:
    """Fetch authenticated Roblox user ID from cookie."""
    try:
        response = requests.get(
            "https://users.roblox.com/v1/users/authenticated",
            cookies={".ROBLOSECURITY": cookie},
            timeout=5
        )
        if response.status_code == 200:
            return response.json().get('id')
        else:
            logger.error(f"Failed to authenticate with Roblox: {response.status_code}")
            return None
    except Exception as e:
        logger.error(f"Error getting auth ID: {e}")
        return None

MY_ROBLOX_ID = get_auth_id(ROBLOX_COOKIE)
if not MY_ROBLOX_ID:
    logger.warning("Could not authenticate with Roblox. Friend features may not work.")

def fetch_friends() -> List[Dict[str, str]]:
    """Fetches online friends and returns them as select menu options."""
    if not MY_ROBLOX_ID:
        return []
    
    try:
        headers = {".ROBLOSECURITY": ROBLOX_COOKIE}
        
        # Get friends list
        friends_resp = requests.get(
            f"https://friends.roblox.com/v1/users/{MY_ROBLOX_ID}/friends",
            cookies=headers,
            timeout=5
        )
        
        if friends_resp.status_code != 200:
            logger.error(f"Failed to fetch friends: {friends_resp.status_code}")
            return []
        
        friend_ids = [friend["id"] for friend in friends_resp.json().get("data", [])]
        
        if not friend_ids:
            return []
        
        # Get presence information
        presence_resp = requests.post(
            "https://presence.roblox.com/v1/presence/users",
            json={"userIds": friend_ids},
            cookies=headers,
            timeout=5
        )
        
        if presence_resp.status_code != 200:
            logger.error(f"Failed to fetch presence: {presence_resp.status_code}")
            return []
        
        options = []
        for presence in presence_resp.json().get("userPresences", []):
            # Only show online or in-game users
            if presence["userPresenceType"] in [1, 2]:  # 1=Online, 2=In-Game
                icon = "🟢" if presence["userPresenceType"] == 2 else "🔵"
                place_id = presence.get('placeId', 0)
                game_id = presence.get('gameId', '0')
                
                # Value format: UserID|PlaceID|JobID
                value = f"{presence['userId']}|{place_id}|{game_id}"
                
                options.append({
                    "label": presence.get('lastUserName', 'Unknown')[:100],
                    "value": value,
                    "description": f"{icon} {presence.get('lastLocation', 'Online')[:100]}"
                })
        
        # Discord has a limit of 25 options per select menu
        return options[:25]
    
    except Exception as e:
        logger.error(f"Error fetching friends: {e}")
        return []

# -----------------------------------
# -- V2 Component Builder
# -----------------------------------

def build_v2_panel(
    accent_color: int,
    options: List[Dict[str, str]],
    place_id: str = "None",
    game_id: str = "None",
    selected_val: Optional[str] = None
) -> List[Dict]:
    """Builds the Type 17 component structure for the control panel."""
    
    if not options:
        options = [{
            "label": "No friends online",
            "value": "null",
            "description": "None of your friends are currently online"
        }]
    
    # Mark the selected option as default
    if selected_val:
        for opt in options:
            opt["default"] = (opt["value"] == selected_val)
    
    return [
        {
            "type": 17,  # Container
            "accent_color": accent_color,
            "components": [
                {
                    "type": 12,  # Media Gallery
                    "items": [{
                        "media": {
                            "url": "https://cdn.discohook.app/tenor/trump-laugh-gif-16069436437887441139.gif"
                        }
                    }]
                },
                {
                    "type": 14,  # Divider
                    "divider": True
                },
                {
                    "type": 10,  # Text Section
                    "content": f"📊 **SESSION STATS**\n**PlaceID:** `{place_id}`\n**GameID:** `{game_id}`"
                },
                {
                    "type": 1,  # Action Row
                    "components": [
                        {
                            "type": 3,  # Select Menu
                            "custom_id": "vex_player_select",
                            "placeholder": "Select a target player...",
                            "options": options,
                            "min_values": 1,
                            "max_values": 1
                        }
                    ]
                },
                {
                    "type": 1,  # Action Row
                    "components": [
                        {
                            "type": 2,  # Button
                            "style": 3,  # Green
                            "label": "Start",
                            "custom_id": "vex_start_btn"
                        },
                        {
                            "type": 2,  # Button
                            "style": 1,  # Blurple
                            "label": "Rejoin",
                            "custom_id": "vex_rejoin_btn"
                        },
                        {
                            "type": 2,  # Button
                            "style": 5,  # Link
                            "label": "Join BOT",
                            "url": "https://discohook.app",
                            "disabled": True
                        }
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
        intents = discord.Intents.default()
        intents.message_content = True
        intents.guilds = True
        
        super().__init__(
            command_prefix="!",
            intents=intents
        )
        
        self.connected_clients: Set[websockets.WebSocketServerProtocol] = set()
        self.ws_server = None

    async def setup_hook(self):
        """Called when the bot is starting up."""
        # Start WebSocket server as background task
        self.loop.create_task(self.start_websocket_server())
        
        # Sync slash commands
        try:
            await self.tree.sync()
            logger.info("Slash commands synced successfully")
        except Exception as e:
            logger.error(f"Failed to sync commands: {e}")

    async def start_websocket_server(self):
        """Start the WebSocket server for Lua client connections."""
        try:
            # Important: Remove reuse_address parameter to fix IP reuse issues
            # Instead, we'll handle it with proper cleanup
            self.ws_server = await websockets.serve(
                self.ws_handler,
                WS_HOST,
                WS_PORT,
                ping_interval=20,
                ping_timeout=10,
                close_timeout=5
            )
            logger.info(f"WebSocket server started on {WS_HOST}:{WS_PORT}")
            
            # Keep server running
            await asyncio.Future()  # Run forever
            
        except OSError as e:
            if e.errno == 98:  # Address already in use
                logger.error(f"Port {WS_PORT} is already in use. Please choose a different port or stop the existing process.")
            else:
                logger.error(f"Failed to start WebSocket server: {e}")
        except Exception as e:
            logger.error(f"WebSocket server error: {e}")

    async def ws_handler(self, websocket: websockets.WebSocketServerProtocol):
        """Handle individual WebSocket client connections."""
        client_addr = websocket.remote_address
        logger.info(f"WebSocket client connecting from {client_addr}")
        
        self.connected_clients.add(websocket)
        
        # Log connection in Discord
        log_channel = self.get_channel(LOG_CHANNEL_ID)
        if log_channel:
            try:
                await log_channel.send(f"🔗 **WebSocket Client Connected** from `{client_addr}`")
            except Exception as e:
                logger.error(f"Failed to send connection log: {e}")
        
        try:
            # Keep connection alive and handle incoming messages
            async for message in websocket:
                try:
                    data = json.loads(message)
                    logger.info(f"Received from {client_addr}: {data}")
                    
                    # Handle client messages here if needed
                    # For example, status updates from Lua client
                    
                except json.JSONDecodeError:
                    logger.warning(f"Invalid JSON from {client_addr}: {message}")
                except Exception as e:
                    logger.error(f"Error processing message from {client_addr}: {e}")
        
        except websockets.exceptions.ConnectionClosed:
            logger.info(f"WebSocket connection closed normally for {client_addr}")
        except Exception as e:
            logger.error(f"WebSocket handler error for {client_addr}: {e}")
        finally:
            # Clean up on disconnect
            if websocket in self.connected_clients:
                self.connected_clients.remove(websocket)
            
            if log_channel:
                try:
                    await log_channel.send(f"❌ **WebSocket Client Disconnected** from `{client_addr}`")
                except Exception as e:
                    logger.error(f"Failed to send disconnection log: {e}")
            
            logger.info(f"WebSocket client {client_addr} cleaned up")

    async def close(self):
        """Clean up resources when bot shuts down."""
        logger.info("Shutting down bot...")
        
        # Close all WebSocket connections
        for ws in list(self.connected_clients):
            try:
                await ws.close()
            except Exception as e:
                logger.error(f"Error closing WebSocket: {e}")
        
        # Close WebSocket server
        if self.ws_server:
            self.ws_server.close()
            await self.ws_server.wait_closed()
        
        await super().close()

# Create bot instance
bot = VexBot()

# -----------------------------------
# -- Slash Commands
# -----------------------------------

@bot.tree.command(name="panel", description="Spawn the V2 Control Panel (Owner Only)")
async def panel_command(interaction: discord.Interaction):
    """Create a new control panel for managing game sessions."""
    if not await bot.is_owner(interaction.user):
        await interaction.response.send_message("🚫 Access Denied. This command is owner-only.", ephemeral=True)
        return

    await interaction.response.defer()
    
    try:
        # Fetch online friends
        options = fetch_friends()
        
        # Build panel with red accent (no selection)
        components = build_v2_panel(16711680, options)  # Red: 16711680
        
        # Send using raw HTTP request (required for Type 17 components)
        route = discord.http.Route("POST", f"/webhooks/{bot.user.id}/{interaction.token}")
        await bot.http.request(route, json={"components": components})
        
        logger.info(f"Panel created by {interaction.user}")
    
    except Exception as e:
        logger.error(f"Error creating panel: {e}")
        await interaction.followup.send(
            "❌ Failed to create panel. Ensure the bot has proper permissions and V2 component access.",
            ephemeral=True
        )

@bot.tree.command(name="status", description="Check bot and WebSocket status")
async def status_command(interaction: discord.Interaction):
    """Display current bot status including WebSocket connections."""
    ws_count = len(bot.connected_clients)
    ws_status = f"✅ {ws_count} client(s) connected" if ws_count > 0 else "❌ No clients connected"
    
    embed = discord.Embed(
        title="🤖 Bot Status",
        color=discord.Color.green() if ws_count > 0 else discord.Color.red()
    )
    embed.add_field(name="WebSocket Server", value=f"{WS_HOST}:{WS_PORT}", inline=False)
    embed.add_field(name="Connected Clients", value=ws_status, inline=False)
    embed.add_field(name="Roblox Auth", value="✅ Authenticated" if MY_ROBLOX_ID else "❌ Not authenticated", inline=False)
    
    await interaction.response.send_message(embed=embed, ephemeral=True)

# -----------------------------------
# -- Component Interaction Handler
# -----------------------------------

@bot.event
async def on_interaction(interaction: discord.Interaction):
    """Handle button clicks and select menu interactions."""
    if interaction.type != discord.InteractionType.component:
        return
    
    custom_id = interaction.data.get("custom_id")
    user_id = interaction.user.id
    
    try:
        # Handle Player Selection
        if custom_id == "vex_player_select":
            values = interaction.data.get("values", [])
            if not values or values[0] == "null":
                await interaction.response.send_message("❌ Invalid selection.", ephemeral=True)
                return
            
            value = values[0]
            parts = value.split("|")
            
            if len(parts) != 3:
                await interaction.response.send_message("❌ Malformed selection data.", ephemeral=True)
                return
            
            user_id_str, place_id, job_id = parts
            
            # Determine color based on game status
            # Green if in-game (placeId > 0), Blue if just online
            new_color = 3447003 if int(place_id) > 0 else 32526  # Green: 3447003, Blue: 32526
            
            # Store selection
            selection_state[user_id] = {
                "place": place_id,
                "job": job_id,
                "val": value
            }
            
            # Update panel with new color and stats
            options = fetch_friends()
            updated_components = build_v2_panel(new_color, options, place_id, job_id, value)
            
            await interaction.response.edit_message(components=updated_components)
            logger.info(f"User {interaction.user} selected PlaceID: {place_id}, JobID: {job_id}")
        
        # Handle Start Button
        elif custom_id == "vex_start_btn":
            user_data = selection_state.get(user_id)
            
            if not user_data:
                await interaction.response.send_message("❌ Please select a player first.", ephemeral=True)
                return
            
            place_id = user_data.get("place", "0")
            job_id = user_data.get("job", "0")
            
            if int(place_id) == 0:
                await interaction.response.send_message("❌ Selected player is not in a game.", ephemeral=True)
                return
            
            # Open Roblox game
            roblox_url = f"roblox://placeId={place_id}&gameInstanceId={job_id}"
            webbrowser.open(roblox_url)
            
            await interaction.response.send_message(
                f"🚀 Joining game...\n**PlaceID:** `{place_id}`\n**JobID:** `{job_id}`",
                ephemeral=True
            )
            logger.info(f"User {interaction.user} joining PlaceID: {place_id}")
        
        # Handle Rejoin Button
        elif custom_id == "vex_rejoin_btn":
            if not bot.connected_clients:
                await interaction.response.send_message("❌ No Lua clients connected to WebSocket.", ephemeral=True)
                return
            
            # Broadcast rejoin command to all connected clients
            payload = json.dumps({"type": "rejoin", "timestamp": asyncio.get_event_loop().time()})
            
            sent_count = 0
            failed_clients = []
            
            for ws in list(bot.connected_clients):
                try:
                    await ws.send(payload)
                    sent_count += 1
                except Exception as e:
                    logger.error(f"Failed to send to WebSocket client: {e}")
                    failed_clients.append(ws)
            
            # Remove failed clients
            for ws in failed_clients:
                if ws in bot.connected_clients:
                    bot.connected_clients.remove(ws)
            
            await interaction.response.send_message(
                f"🔄 Rejoin command sent to {sent_count} client(s).",
                ephemeral=True
            )
            logger.info(f"Rejoin broadcast sent to {sent_count} clients")
    
    except Exception as e:
        logger.error(f"Error handling interaction: {e}")
        try:
            await interaction.response.send_message(f"❌ An error occurred: {str(e)}", ephemeral=True)
        except:
            pass

# -----------------------------------
# -- Bot Events
# -----------------------------------

@bot.event
async def on_ready():
    """Called when the bot successfully connects to Discord."""
    logger.info(f"Bot logged in as {bot.user} (ID: {bot.user.id})")
    logger.info(f"Connected to {len(bot.guilds)} guild(s)")
    
    # Set bot status
    activity = discord.Activity(
        type=discord.ActivityType.watching,
        name="for /panel"
    )
    await bot.change_presence(activity=activity, status=discord.Status.online)

@bot.event
async def on_error(event, *args, **kwargs):
    """Global error handler for events."""
    logger.error(f"Error in event {event}", exc_info=sys.exc_info())

# -----------------------------------
# -- Main Entry Point
# -----------------------------------

if __name__ == "__main__":
    try:
        bot.run(TOKEN, log_handler=None)  # We're using our own logging config
    except KeyboardInterrupt:
        logger.info("Received keyboard interrupt, shutting down...")
    except Exception as e:
        logger.error(f"Fatal error: {e}")
    finally:
        logger.info("Bot shutdown complete")
