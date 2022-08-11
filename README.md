# Ring Buffers in P4
##### Katarina Cheng

A ring buffer is a circular queue, which enqueues at the tail pointer index of the queue and dequeues at the head. It is usually implemented as a linear queue where the head and tail are just incremented modulo the buffer capacity. It is a popular way to store data in networks, like queueing incoming packets or requests to a switch.

### ring_buffer.p4
This file contains 94 lines of P4 for an enqueue control block and 72 lines of P4 for a dequeue control block. There are also 5 register arrays:
```
Register<bit<32>, bit<32>> (1, 0) head;
Register<bit<32>, bit<32>> (1, 0) tail;
Register<bit<32>, bit<32>> (1, 0) buffer_size;
Register<bit<1>, bit<32>> (1, 0) first;
Register<bit<32>, bit<32>> (CAPACITY, 0) ring_buffer;
```

```first``` is used to make sure the tail pointer is incremented properly the first time. The user can define CAPACITY in include/define.p4 to set the capacity of the ring buffer register array. 

```Enqueue(in bit<32> enq_value)``` takes in a 32 bit value to enqueue at ```tail```. The match-action tables in this control incremement ```tail``` pointer modulo the buffer capacity, increment ```buffer_size```, and write ```enq_value``` to the buffer tail index of ```ring_buffer```.
```Dequeue(out bit<32> deq_value)``` takes in a 32 bit value that is set to the dequeued item.The match-action tables in this control, on the condition that ```buffer_size > 0```, increment ```head``` pointer modulo the buffer capacity, decrement ```buffer_size```, and read the element at the buffer head index to ```deq_value```.

### multiple_buffers.p4
If we want to have multiple ring buffers in our program, there are two methods for implementing this. In both methods, the enqueue and dequeue operations (control blocks) are implemented in the same way as in ring_buffer.p4.

multiple_buffers.p4 contains multiple copies of ring buffer registers labeled ```rb1, rb2, etc```, along with register arrays holding all the heads, tails, and sizes. The information about buffer ```i``` is at index ```i-1``` of these register arrays. Now, ```Enqueue(in bit<k> rb_id, in bit<ELT_SIZE> enq_value)``` and ```Dequeue(in bit<k> rb_id, out bit<ELT_SIZE> deq_value)``` take an additional parameter ```rb_id``` with size to be inputted by the user (should be log # buffers). When enqueuing or dequeuing, this parameter indicates which buffer is being used. 

### opt_buffers.p4 (+ opt_gen.py)
In opt_buffers.p4, there will only be one ```ring_buffer``` register array containing all the buffers. This shared buffer is used so that a smaller number of register arrays is used, and thus fewer pipeline stages are used (as we are allowed 4 register arrays per pipeline stage). Further, there is a register array ```lefts``` containing the left bound of each register. 

![alt text](https://github.com/katcheng902/ring-buffer-hw/blob/master/shared_buffer.png?raw=true)

To generate opt_buffers.p4, run the command ```python3 opt_gen.py [ELEMENT SIZE] [NUMBER OF BUFFERS] [BUFFER CAPACITY]```. This will properly define the register arrays in the file registers.p4. After connecting to the switch, run ```python3 setup_ports.py opt_buffers``` to set up ports and initialize ```lefts``` based on the number of buffers and buffer capacity. Use ```Enqueue``` and ```Dequeue``` in the same way as in multiple_buffers.p4.

### Multiple Buffers v. Shared Buffer
Comparing the resource usage of the two methods, the SRAM usage is similar, but as the number of buffers increases, the shared buffer method uses less pipeline stages, as can be seen in the graphs below. If the user wants to have < 4 ring buffers, this optimization is not necessary, but otherwise, it lessens the number of pipeline stages utilized by the ring buffers.

![alt text](https://github.com/katcheng902/ring-buffer-hw/blob/master/comparison.png?raw=true)

