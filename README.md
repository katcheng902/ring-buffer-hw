# Ring Buffer in P4
##### Katarina Cheng

### Ring Buffers
*include image and brief explanation*

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

### opt_buffers.p4 (+ opt_gen.py)

