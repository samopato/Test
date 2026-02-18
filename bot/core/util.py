# util.py
from core.logger import setup_logger
from colorama import Fore
import requests
import os

log = setup_logger("Roblox")

def upload_to_litterbox(file_path, duration="1h"):
    """
    Uploads a file to Litterbox with a progress bar.
    Durations: '1h', '12h', '24h', '72h'
    """
    url = "https://litterbox.catbox.moe/resources/internals/api.php"
    file_size = os.path.getsize(file_path)
    file_name = os.path.basename(file_path)

    # Prepare the data fields for Litterbox
    data = {
        "reqtype": "fileupload",
        "time": duration
    }

    print(f"Uploading {file_name} ({file_size / (1024*1024):.2f} MB)...")

    # We use a context manager to ensure the file closes properly
    with open(file_path, "rb") as f:
        files = {"fileToUpload": (file_name, f)}
        
        # We wrap the request in a try-except to handle connection issues
        try:
            # Note: Requests doesn't have a built-in progress bar for uploads.
            # For 100MB, this will 'pause' for a few seconds while it sends.
            response = requests.post(url, data=data, files=files)
            
            if response.status_code == 200:
                link = response.text.strip()
                print(f"\n✅ Upload Complete!")
                print(f"🔗 Link: {link}")
                return link
            else:
                print(f"\n❌ Upload failed with status: {response.status_code}")
                return None
                
        except Exception as e:
            print(f"\n❌ Error during upload: {e}")
            return None

def get_auth_id(cookie: str):
    """Fetch authenticated Roblox user ID from cookie."""
    try:
        response = requests.get(
            "https://users.roblox.com/v1/users/authenticated",
            cookies={".ROBLOSECURITY": cookie},
            timeout=5
        )
        if response.status_code == 200:
            user_id = response.json().get('id')
            log.info(f"{Fore.GREEN}Successfully authenticated with Roblox (User ID: {user_id})")
            return user_id
        else:
            log.error(f"Failed to authenticate with Roblox: {response.status_code}")
            return None
    except Exception as e:
        log.error(f"Error getting auth ID: {e}", exc_info=True)
        return None

def fetch_friends() -> list[dict[str, str]]:
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