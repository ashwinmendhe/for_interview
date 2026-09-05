import asyncio
import time

async def counter():
    print("1")
    await asyncio.sleep(2)
    print("2")

async def main():
    await asyncio.gather(counter(), counter(), counter())

if __name__ == "__main__":
    start_time = time.time()
    asyncio.run(main())
    end_time = time.time()
    print((end_time-start_time))
