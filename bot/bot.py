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
from colorama import Fore, Back, Style, init

# Initialize colorama for cross-platform colored output
init(autoreset=True)

# -----------------------------------
# -- Colored Logging Setup
# -----------------------------------

class ColoredFormatter(logging.Formatter):
    """Custom formatter with colors for different log levels."""
    
    COLORS = {
        'DEBUG': Fore.CYAN,
        'INFO': Fore.GREEN,
        'WARNING': Fore.YELLOW,
        'ERROR': Fore.RED,
        'CRITICAL': Fore.RED + Back.WHITE + Style.BRIGHT,
    }
    
    def format(self, record):
        # Add color to levelname
        levelname = record.levelname
        if levelname in self.COLORS:
            record.levelname = f"{self.COLORS[levelname]}{levelname}{Style.RESET_ALL}"
        
        # Add color to logger name
        record.name = f"{Fore.MAGENTA}{record.name}{Style.RESET_ALL}"
        
        # Format timestamp in blue
        result = super().format(record)
        return result

# Setup logging with colors
handler = logging.StreamHandler(sys.stdout)
handler.setFormatter(ColoredFormatter(
    '%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    datefmt='%Y-%m-%d %H:%M:%S'
))

logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)
logger.addHandler(handler)

# Also set up discord.py logger with colors
discord_logger = logging.getLogger('discord')
discord_logger.setLevel(logging.INFO)
discord_logger.addHandler(handler)

load_dotenv()

# -----------------------------------
# -- Environment Variables
# -----------------------------------

TOKEN = os.getenv('DISCORD_TOKEN')
ROBLOX_COOKIE = os.getenv('ROBLOX_COOKIE')
LOG_CHANNEL_ID = int(os.getenv('LOG_CHANNEL_ID', '1462534721517916465'))
WS_HOST = os.getenv('WS_HOST', '127.0.0.1')
WS_PORT = int(os.getenv('WS_PORT', '8765'))

if not TOKEN:
    logger.critical("DISCORD_TOKEN not found in environment variables")
    raise ValueError("DISCORD_TOKEN not found in environment variables")
if not ROBLOX_COOKIE:
    logger.critical("ROBLOX_COOKIE not found in environment variables")
    raise ValueError("ROBLOX_COOKIE not found in environment variables")

# Local state to track user selections
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
            user_id = response.json().get('id')
            logger.info(f"{Fore.GREEN}Successfully authenticated with Roblox (User ID: {user_id})")
            return user_id
        else:
            logger.error(f"Failed to authenticate with Roblox: {response.status_code}")
            return None
    except Exception as e:
        logger.error(f"Error getting auth ID: {e}", exc_info=True)
        return None

MY_ROBLOX_ID = get_auth_id(ROBLOX_COOKIE)
if not MY_ROBLOX_ID:
    logger.warning("Could not authenticate with Roblox. Friend features may not work.")

def fetch_friends() -> List[Dict[str, str]]:
    """Fetches online friends and their profile names correctly."""
    if not MY_ROBLOX_ID:
        logger.warning("Not authenticated")
        return []
    
    try:
        headers = {".ROBLOSECURITY": ROBLOX_COOKIE}
        
        # 1. Get Friend IDs
        friends_resp = requests.get(
            f"https://friends.roblox.com/v1/users/{MY_ROBLOX_ID}/friends/online",
            cookies=headers, timeout=5
        )
        friend_ids = [f["id"] for f in friends_resp.json().get("data", [])]
        if not friend_ids: return []

        # 2. Get Names from Profile API (The Fix is here)
        # We request multiple name fields to be safe
        profile_url = "https://apis.roblox.com/user-profile-api/v1/user/profiles/get-profiles"
        profile_resp = requests.post(
            profile_url,
            json={
                "userIds": friend_ids, 
                "fields": ["names.combinedName", "names.displayName", "names.username"]
            },
            cookies=headers
        )
        
        names_map = {}
        if profile_resp.status_code == 200:
            profiles = profile_resp.json().get("userProfiles", [])
            for p in profiles:
                uid = p.get("userId")
                names = p.get("names", {})
                # Try combinedName first, then displayName, then username
                resolved_name = names.get("combinedName") or names.get("displayName") or names.get("username")
                if uid and resolved_name:
                    names_map[uid] = resolved_name

        # 3. Get Presence and Build Options
        pres_resp = requests.post(
            "https://presence.roblox.com/v1/presence/users",
            json={"userIds": friend_ids}, cookies=headers
        )
        
        options = []
        for presence in pres_resp.json().get("userPresences", []):
            if presence["userPresenceType"] in [1, 2]:
                uid = presence['userId']
                # If name_map failed, we use the Presence API's lastUserName as a backup
                name = names_map.get(uid) or presence.get('lastUserName') or f"User {uid}"
                
                icon = "🟢" if presence["userPresenceType"] == 2 else "🔵"
                val = f"{uid}|{presence.get('placeId', 0)}|{presence.get('gameId', '0')}"
                
                options.append({
                    "label": name[:100],
                    "value": val,
                    "description": f"{icon} {presence.get('lastLocation', 'Online')[:100]}"
                })
        
        return options[:25]
        
    except Exception as e:
        logger.error(f"Fetch failed: {e}")
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
        self.ws_task = None

    async def setup_hook(self):
        """Called when the bot is starting up."""
        logger.info(f"{Fore.YELLOW}Setting up bot...")
        
        # Start WebSocket server as background task
        self.ws_task = self.loop.create_task(self.start_websocket_server())
        
        # Sync slash commands
        try:
            synced = await self.tree.sync()
            logger.info(f"{Fore.GREEN}✓ Synced {len(synced)} slash command(s)")
        except Exception as e:
            logger.error(f"Failed to sync commands: {e}", exc_info=True)

    async def start_websocket_server(self):
        """Start the WebSocket server for Lua client connections."""
        try:
            logger.info(f"{Fore.YELLOW}Starting WebSocket server on {WS_HOST}:{WS_PORT}...")
            
            self.ws_server = await websockets.serve(
                self.ws_handler,
                WS_HOST,
                WS_PORT,
                ping_interval=20,
                ping_timeout=10,
                close_timeout=5
            )
            logger.info(f"{Fore.GREEN}✓ WebSocket server started successfully")
            
            # Keep server running
            await asyncio.Future()  # Run forever
            
        except OSError as e:
            if e.errno == 98 or "already in use" in str(e).lower():
                logger.error(f"{Fore.RED}✗ Port {WS_PORT} is already in use!")
                logger.error(f"{Fore.YELLOW}Solutions:")
                logger.error(f"{Fore.YELLOW}  1. Change WS_PORT in your .env file to a different port (e.g., 8766)")
                logger.error(f"{Fore.YELLOW}  2. Find and stop the process using port {WS_PORT}:")
                logger.error(f"{Fore.CYAN}     Linux/Mac: lsof -ti:{WS_PORT} | xargs kill -9")
                logger.error(f"{Fore.CYAN}     Windows: netstat -ano | findstr :{WS_PORT}")
            else:
                logger.error(f"Failed to start WebSocket server: {e}", exc_info=True)
        except Exception as e:
            logger.error(f"WebSocket server error: {e}", exc_info=True)

    async def ws_handler(self, websocket):
        """Handle individual WebSocket client connections."""
        client_addr = websocket.remote_address
        logger.info(f"{Fore.CYAN}New WebSocket connection from {client_addr}")
        
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
                    logger.info(f"{Fore.CYAN}Received from {client_addr}: {data}")
                    
                except json.JSONDecodeError:
                    logger.warning(f"Invalid JSON from {client_addr}: {message}")
                except Exception as e:
                    logger.error(f"Error processing message from {client_addr}: {e}", exc_info=True)
        
        except websockets.exceptions.ConnectionClosed as e:
            logger.info(f"{Fore.YELLOW}WebSocket connection closed for {client_addr} (code: {e.code})")
        except Exception as e:
            logger.error(f"WebSocket handler error for {client_addr}: {e}", exc_info=True)
        finally:
            # Clean up on disconnect
            if websocket in self.connected_clients:
                self.connected_clients.remove(websocket)
            
            if log_channel:
                try:
                    await log_channel.send(f"❌ **WebSocket Client Disconnected** from `{client_addr}`")
                except Exception as e:
                    logger.error(f"Failed to send disconnection log: {e}")
            
            logger.info(f"{Fore.YELLOW}WebSocket client {client_addr} cleaned up")

    async def close(self):
        """Clean up resources when bot shuts down."""
        logger.info(f"{Fore.YELLOW}Shutting down bot...")
        
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
        
        # Cancel WebSocket task
        if self.ws_task and not self.ws_task.done():
            self.ws_task.cancel()
            try:
                await self.ws_task
            except asyncio.CancelledError:
                pass
        
        await super().close()
        logger.info(f"{Fore.GREEN}✓ Bot shutdown complete")

# Create bot instance
bot = VexBot()

# -----------------------------------
# -- Slash Commands
# -----------------------------------

@bot.tree.command(name="panel", description="Spawn the V2 Control Panel (Owner Only)")
async def panel_command(interaction: discord.Interaction):
    """Create a new control panel for managing game sessions."""
    try:
        if not await bot.is_owner(interaction.user):
            await interaction.response.send_message("🚫 Access Denied. This command is owner-only.", ephemeral=True)
            logger.warning(f"{Fore.YELLOW}User {interaction.user} attempted to use /panel (not owner)")
            return

        # Respond immediately to acknowledge the interaction
        await interaction.response.send_message("✅ Creating panel...", ephemeral=True)
        
        # Fetch online friends
        options = fetch_friends()
        
        # Build panel with red accent (no selection)
        components = build_v2_panel(16711680, options)  # Red: 16711680
        
        # Send via raw HTTP request (V2 components require this method)
        payload = {
            "flags": 32768,
            "components": components
        }
        
        route = discord.http.Route("POST", f"/channels/{interaction.channel.id}/messages")
        await bot.http.request(route, json=payload)
        
        logger.info(f"{Fore.GREEN}✓ Panel created by {interaction.user}")
    
    except discord.errors.InteractionResponded:
        logger.error(f"{Fore.RED}Interaction already responded to")
    
    except discord.errors.Forbidden as e:
        logger.error(f"{Fore.RED}Permission error: {e}", exc_info=True)
        try:
            if not interaction.response.is_done():
                await interaction.response.send_message("❌ I don't have permission to send messages in this channel.", ephemeral=True)
        except:
            pass
    
    except discord.errors.HTTPException as e:
        logger.error(f"{Fore.RED}Discord HTTP Error: {e.status} - {e.text}", exc_info=True)
        try:
            if not interaction.response.is_done():
                await interaction.response.send_message(f"❌ Failed to create panel: {e.text}", ephemeral=True)
        except:
            pass
    
    except Exception as e:
        logger.error(f"{Fore.RED}Error creating panel: {e}", exc_info=True)
        try:
            if not interaction.response.is_done():
                await interaction.response.send_message("❌ Failed to create panel. Check bot logs for details.", ephemeral=True)
        except:
            pass

@bot.tree.command(name="status", description="Check bot and WebSocket status")
async def status_command(interaction: discord.Interaction):
    """Display current bot status including WebSocket connections."""
    try:
        ws_count = len(bot.connected_clients)
        ws_status = f"✅ {ws_count} client(s) connected" if ws_count > 0 else "❌ No clients connected"
        
        embed = discord.Embed(
            title="🤖 Bot Status",
            color=discord.Color.green() if ws_count > 0 else discord.Color.red()
        )
        embed.add_field(name="WebSocket Server", value=f"{WS_HOST}:{WS_PORT}", inline=False)
        embed.add_field(name="Connected Clients", value=ws_status, inline=False)
        embed.add_field(name="Roblox Auth", value="✅ Authenticated" if MY_ROBLOX_ID else "❌ Not authenticated", inline=False)
        
        if MY_ROBLOX_ID:
            embed.add_field(name="Roblox User ID", value=str(MY_ROBLOX_ID), inline=False)
        
        await interaction.response.send_message(embed=embed, ephemeral=True)
        logger.info(f"{Fore.CYAN}Status command used by {interaction.user}")
    
    except Exception as e:
        logger.error(f"{Fore.RED}Error in status command: {e}", exc_info=True)
        await interaction.response.send_message("❌ Error retrieving status", ephemeral=True)

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
                logger.error(f"{Fore.RED}Malformed selection data: {value}")
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
            logger.info(f"{Fore.GREEN}User {interaction.user} selected PlaceID: {place_id}, JobID: {job_id}")
        
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
            logger.info(f"{Fore.GREEN}User {interaction.user} joining PlaceID: {place_id}")
        
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
                    logger.error(f"{Fore.RED}Failed to send to WebSocket client: {e}")
                    failed_clients.append(ws)
            
            # Remove failed clients
            for ws in failed_clients:
                if ws in bot.connected_clients:
                    bot.connected_clients.remove(ws)
            
            await interaction.response.send_message(
                f"🔄 Rejoin command sent to {sent_count} client(s).",
                ephemeral=True
            )
            logger.info(f"{Fore.CYAN}Rejoin broadcast sent to {sent_count} clients")
    
    except discord.errors.NotFound:
        logger.error(f"{Fore.RED}404 Unknown Interaction in component handler")
    except Exception as e:
        logger.error(f"{Fore.RED}Error handling interaction: {e}", exc_info=True)
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
    # Print banner without logger formatting for cleaner output
    print(f"\n{Fore.GREEN}{'='*40}")
    print(f"{Fore.GREEN}✓ {bot.user}")
    print(f"{Fore.GREEN}✓ {bot.user.id}")
    print(f"{Fore.GREEN}✓ Connected to {len(bot.guilds)} guild(s)")
    print(f"{Fore.GREEN}{'='*40}{Style.RESET_ALL}\n")
    
    # Set bot status
    activity = discord.Activity(
        type=discord.ActivityType.watching,
        name="https://discord.gg/EqVFdatk5Y"
    )
    await bot.change_presence(activity=activity, status=discord.Status.online)

@bot.event
async def on_error(event, *args, **kwargs):
    """Global error handler for events."""
    logger.error(f"{Fore.RED}Error in event '{event}'", exc_info=sys.exc_info())

@bot.event
async def on_command_error(ctx, error):
    """Handle command errors."""
    if isinstance(error, commands.CommandNotFound):
        return  # Ignore unknown commands
    
    logger.error(f"{Fore.RED}Command error in {ctx.command}: {error}", exc_info=error)
    
    if isinstance(error, commands.MissingPermissions):
        await ctx.send("❌ You don't have permission to use this command.")
    elif isinstance(error, commands.BotMissingPermissions):
        await ctx.send("❌ I don't have the required permissions to execute this command.")
    else:
        await ctx.send(f"❌ An error occurred: {str(error)}")

# -----------------------------------
# -- Main Entry Point
# -----------------------------------

if __name__ == "__main__":
    try:
        print(f"\n{Fore.CYAN}{'='*40}")
        print(f"{Fore.CYAN}Starting VEX Discord Bot...")
        print(f"{Fore.CYAN}{'='*40}{Style.RESET_ALL}\n")
        bot.run(TOKEN, log_handler=None)  # We're using our own logging config
    except KeyboardInterrupt:
        logger.info(f"{Fore.YELLOW}Received keyboard interrupt, shutting down...")
    except Exception as e:
        logger.critical(f"{Fore.RED}Fatal error: {e}", exc_info=True)
    finally:
        logger.info(f"{Fore.GREEN}Bot shutdown complete")




