import requests
import os
import sys

REPO_NAME = "Test"

ROOT_PATH = "/sdcard/Android/data/com.roblox.client/files/gloop/external/Workspace/vex"
BOT_FOLDER = os.path.join(ROOT_PATH, "bot")
FILES_TO_GET = ["bot.py", "requirements.txt"]

def update_vex_project():
    if not os.path.exists(ROOT_PATH):
        try:
            os.makedirs(BOT_FOLDER, exist_ok=True)
        except Exception as e:
            return

    os.makedirs(BOT_FOLDER, exist_ok=True)

    for filename in FILES_TO_GET:
        raw_url = f"https://raw.githubusercontent.com/samopato/{REPO_NAME}/main/bot/{filename}"
        local_path = os.path.join(BOT_FOLDER, filename)

        try:
            response = requests.get(raw_url, timeout=10)
            
            if response.status_code == 200:
                with open(local_path, "wb") as f:
                    f.write(response.content)
            elif response.status_code == 404:
                print("❌ FAILED (File not found on GitHub. Check your folder names!)")
            else:
                print(f"❌ FAILED (Status Code: {response.status_code})")
                
        except Exception as e:
            print(f"ERROR: {e}")

## Run
if __name__ == "__main__":
    update_vex_project()
