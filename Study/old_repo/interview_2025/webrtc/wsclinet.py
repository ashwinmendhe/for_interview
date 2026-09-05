import asyncio
import websockets

async def hello():
    async with websockets.connect("ws://localhost:8765") as websocket:
        name = input("Enter your name: ")
        await websocket.send(name)
        print(f"Client sent: {name}")
        

        greeting = await websocket.recv()
        print(f"client received: {greeting}")


if __name__ == "__main__":
    asyncio.run(hello())

