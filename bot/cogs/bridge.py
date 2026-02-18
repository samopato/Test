# bridge.py
import uuid
import discord
from discord.ext import commands
from discord import app_commands
from core.logger import setup_logger
import websockets
import asyncio
import json

log = setup_logger("Bridge")

class Bridge(commands.Cog):
    def __init__(self, bot):
        self.bot = bot
        self.connections = set()
        self.pending_responses = {} # Stores {request_id: asyncio.Future}

    async def handler(self, websocket):
        self.connections.add(websocket)
        try:
            async for message in websocket:
                data = json.loads(message)
                
                # Check if this is a response to a Discord command
                request_id = data.get("request_id")
                if request_id in self.pending_responses:
                    future = self.pending_responses.pop(request_id)
                    future.set_result(data.get("payload")) # Send the data back to the command
        finally:
            self.connections.remove(websocket)

    @app_commands.command(name="cmds", description="Get a list of in-game commands")
    async def get_cmds(self, interaction: discord.Interaction):
        if not self.connections:
            return await interaction.response.send_message("❌ Roblox is not connected!", ephemeral=True)

        await interaction.response.defer() # Give us time to wait for Roblox

        # 1. Create a unique ID for this request
        request_id = str(uuid.uuid4())
        
        # 2. Create a "Future" (The Waiter)
        future = self.bot.loop.create_future()
        self.pending_responses[request_id] = future

        # 3. Ask Roblox for the list
        payload = json.dumps({
            "action": "GET_COMMANDS",
            "request_id": request_id
        })
        
        for conn in self.connections:
            await conn.send(payload)

        try:
            # 4. Wait for Roblox to reply (with a 5-second timeout)
            cmd_list = await asyncio.wait_for(future, timeout=5.0)
            
            # 5. Format and send the response
            formatted_list = "\n".join([f"• `{c}`" for c in cmd_list])
            await interaction.followup.send(f"**Roblox Commands:**\n{formatted_list}")

        except asyncio.TimeoutError:
            self.pending_responses.pop(request_id, None)
            await interaction.followup.send("⏳ Roblox took too long to respond.")

async def cog_unload(self):
        """Clean up the server when the Cog is reloaded."""
        print("Stopping WebSocket Server...")
        if hasattr(self, 'server'):
            self.server.close()
            await self.server.wait_closed()
            
async def setup(bot):
    await bot.add_cog(Bridge(bot))