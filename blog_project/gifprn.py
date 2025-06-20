import requests

# URL of the empty GIF image
url = "https://media.giphy.com/media/3oEjI6SIIHBdRxXI40/giphy.gif"

# Download the image
response = requests.get(url)

# Check if the download was successful
if response.status_code == 200:
    # Save the image to the current directory
    with open("empty_gif.gif", "wb") as f:
        f.write(response.content)
    print("Image downloaded successfully!")
else:
    print(f"Failed to download the image. Status code: {response.status_code}")
