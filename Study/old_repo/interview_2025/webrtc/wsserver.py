import asyncio
import websockets

async def hello(websocket):
    name = await websocket.recv()
    print(f"< {name}")

    greeting = f"Hello {name}!"

    await websocket.send(greeting)
    print(f"> {greeting}")

async def main():
    async with websockets.serve(hello, "localhost", 8765):
        await asyncio.Future()  # run forever   

if __name__ == "__main__":
    asyncio.run(main())

## client
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