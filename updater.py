import requests
import os

REPO = "Test"

def download_file(path, filename):
    url = f"https://raw.githubusercontent.com/samopato/{REPO}/main/{path}/{filename}"
    response = requests.get(url)
    if response.status_code == 200:
        with open(filename, "wb") as f:
            f.write(response.content)
        print(f"Successfully updated {filename}")

download_file("bot", "bot.py")

download_file("bot", "requirements.txt")
