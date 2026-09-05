import threading
import time

loop=10000000

def method1():
    for _ in range(1, loop):
        pass

def method2():
    for _ in range(1, loop):
        pass

def method3():
    for _ in range(1, loop):
        pass

def sequntial_execution():
    start_time= time.time()
    method1()
    method2()
    method3()
    end_time = time.time()
    print("squential execution",end_time-start_time)

def multithreding_execution():
    start_time=time.time()

    th1 = threading.Thread(target=method1)
    th2 = threading.Thread(target=method2)
    th3 = threading.Thread(target=method3)

    th1.start()
    th2.start()
    th3.start()

    th1.join()
    th2.join()
    th3.join()

    end_time=time.time()
    print("multithreding time", end_time-start_time)

if __name__=="__main__":
    sequntial_execution()
    multithreding_execution()
