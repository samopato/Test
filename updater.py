import subprocess
import requests
import os

## Delta
ROOT_PATH = "/sdcard/Android/data/com.roblox.client/files/gloop/external/Workspace/vex"
BOT_FOLDER = os.path.join(ROOT_PATH, "bot")

script_dir = os.path.dirname(os.path.join(BOT_FOLDER, "bot.py"))
os.chdir(script_dir)

def download_latest_file(user, repo, filename, branch="main"):
    api_url = f"https://api.github.com/repos/{user}/{repo}/commits/{branch}"
    
    response = requests.get(api_url)
    if response.status_code != 200:
        print(f"Error fetching metadata: {response.status_code}")
        return False
        
    latest_sha = response.json()['sha']
    
    raw_url = f"https://raw.githubusercontent.com/{user}/{repo}/{latest_sha}/{filename}"
    
    headers = {
        'Cache-Control': 'no-cache',
        'Pragma': 'no-cache'
    }
    
    print(f"Downloading fresh version (Commit: {latest_sha[:7]})...")
    file_response = requests.get(raw_url, headers=headers)

    if file_response.status_code == 200:
        with open(os.path.join(BOT_FOLDER, "bot.py"), 'wb') as f:
            f.write(file_response.content)
            print("Update successful!")

        return True
    else:
        print(f"Failed to download file: {file_response.status_code}")
        return False


success = download_latest_file("samopato", "Test", "bot/bot.py")

if success:
    choice = input("\nWould you like to start the bot now? (Y/N): ").lower()

    if choice == 'y':
        print("Starting...")
        subprocess.Popen(['python', 'bot.py'])


