---
layout: doc
title: "Ideal Indirection"
learning_objectives:
  - Virtual Memory
  - The virtual address translation process
  - Memory Management Unit (MMU)
  - Page Tables
  - Translation Lookaside Buffer (TLB)
wikibook:
  - "Virtual Memory, Part 1: Introduction to Virtual Memory"
---

## Background

Congrats! Due to your recent excellent performance in _\<insert hot tech company here\>_, the head honchos have decided to put you in the development team for the company's new console project! Since this is a huge project, and it involves developing a new kernel, the project manager decides to first do a day camp on some systems topics with some toy assignments. You've been tasked to complete a simulation of a Memory Management Unit (MMU). It's time to show that you don't just know how to interface with systems, you also _know systems_!

## Overview

In this assignment, you will be working on managing a mapping of 32-bit virtual address spaces to a 32-bit physical address space with 4 KB (kilobyte) pages.
Each component of virtual and physical memory has been split up into several files to help you build a mental model of virtual memory.
Reading through these files can start to help you understand the roles of the different hardware and software involved in managing virtual memory.
You will only have to write two functions in `mmu.c`, but it requires
- a good understanding of the virtual memory to physical memory translation process
- familiarity with the simulation's overall structure, the layout of the structs provided, as well as the functionality of each part of the simulation

The rest of this documentation will provide a high level overview of each file and give you a high level understanding of virtual memory.
The details of each function are documented in each of the header files.
It is your responsibility to read every header file before starting this assignment.
You are not required to read the implementation of each part of the simulation, but you are free to read them if you are curious on how things work.

**Warning**: The documentation below is not a replacement for reading the header files. Reading the header files is mandatory to completing the assignment (and is a good habit to practice that for any assignment). Only begin to write code after you've completed the pre-requisites above. Plan out the steps first, and use provided functionality when available.

## Representation of 32-bit Addresses (`types.h`)

In this simulation, we will be using `addr32` to represent the virtual and physical addresses of the simulation (which is a `typedef` of `uint32_t`). Note that the physical addresses of the simulated machine cannot be read directly - you will need to translate that to an address of your actual machine before reads and writes can be done.

## Page Tables (`page_table.h`)

Each process has two levels of paging:

The top level page table is known as a `page_directory` and has entries (page directory entries) that hold the base address of page tables (beginning of a `page_table`).
Each of these page tables hold entries (page table entries) that hold the base address of an actual frame in physical memory, which you will be reading from and writing to.
The actual layout of the page tables is taken directly from a real 32 bit processor and operating system, which you can read more about in the ["IA-32 Intel® Architecture Software Developer’s Manual"](http://flint.cs.yale.edu/cs422/doc/24547212.pdf#page=88).

For illustrative purposes a Page Table Entry looks like the following:

![Page Table Entry](/images/assignment-docs/lab/ideal_indirection/page_table_entry.png)

Each entry is represented as a struct with bit fields whose syntax you can learn about in a [tutorial](http://www.tutorialspoint.com/cprogramming/c_bit_fields.htm).
The bit fields basically allows us to squeeze multiple flags into a single 32 bit integer.
This means that each entry has not only the physical address to the lower level paging structure, but also metadata bits/flags which are documented in the header file.
However for the purpose of this lab you are only responsible for knowing how the following fields works:

* Page base address, bits 12 through 32
* Present (P) flag, bit 0
* Read/write (R/W) flag, bit 1
* User/supervisor (U/S) flag, bit 2
* Accessed (A) flag, bit 5
* Dirty (D) flag, bit 6

More detailed information about the function of each permission bit is described `page_table.h`. Here are some helpful
guidelines for correctly setting the bits:

* Once a `page_directory` or `page_table` is created, it will remain in physical memory and will not be swapped to disk.
* Each segmentation has a `permissions` field, and there is a permissions struct in `segments.h`. 
If `permissions & WRITE` is not `0`, then it has write permission. Same is true for `READ` and `EXEC`.
* `page_directory_entry`'s should always have read and write permission
* For the purposes of this lab, all `page_table_entry`s and `page_directory_entry`s will have the `user_supervisor` flag
set to `1`
* You only need to keep track of Accessed and Dirty flags for each `page_table_entry`, based on any reading or writing that
has occurred to the `base_addr` stored by the `page_table_entry`.

## Translation Lookaside Buffer (`tlb.c` and `tlb.h`)

The Translation Lookaside Buffer will cache the base virtual address of a virtual page to the corresponding page table entry pointer.
The implementation and header is provided to you.
Make note of the use of double pointers.

The reason why our TLB caches page table entry pointers instead of physical addresses of frames is because you will need to set metadata bits in the `page_table_entry`s when translating addresses.

## Segments (`segments.c` and `segments.h`)

A process's virtual address space is divided into several segments. You are familiar with many of these:

* Stack
* Heap
* BSS
* Data
* Code

For this lab, a processes' address space is split into memory segments like so:

![Virtual Address Space Layout](http://static.duartes.org/img/blogPosts/linuxFlexibleAddressSpaceLayout.png)

Photo Cred: http://duartes.org/gustavo/blog/post/anatomy-of-a-program-in-memory/

Notice how some of the memory segments like the stack and mmap have an arrow pointing down.
This indicates that these regions "grow down" by decreasing their end boundary's virtual address as you add elements to them.
This is so that the stack and heap can share the same address space, but grow in different directions.
It is now easy to see that if you put too many elements onto the stack, it will eventually run into heap memory leading to the classic Stack Overflow<sup>TM</sup>.

The reasons why this external structure is needed for this lab is to answer the question: "How do you know when an address is invalid?".
You cannot rely on the present bit of a page table entry, since that page may be valid, but just happens to be paged to disk.
The solution is to check if an address is in any memory segment with `address_in_segmentations(vm_segmentations *segmentations, uint32_t address)`.
If the address is not in any of the process' segments, then you get one of the possible instances of the dreaded segmentation fault (segfault).
Note that you will need to perform this check before attempting to translate virtual addresses to physical addresses.

## Kernel (`kernel.c` and `kernel.h`)

For this assignment, all the physical memory allocations will be abstracted by `kernel.c`.

This file will maintain a global array of pages that you will use to model all of physical memory.
That is to say that all virtual addresses get translated to an address in:

`char physical_memory[PHYSICAL_MEMORY_SIZE] __attribute__((aligned(PAGE_SIZE)));`

This array of physical memory will be divided into frames of size `PAGE_SIZE`.
The kernel comes with functionality to
- request and free up frames
- swap frames to and from disk

You will be using these functions to obtain physical memory frames for the page tables and user data, as well as reading pages that have been swapped out to disk.

The caveat to this lab is that it is all done in user space.
That means you are technically mapping a virtual address in the simulated user space to a virtual address in your user space in the actual machine. However, all the concepts involved remain the same in a real operating system's memory management software. Thus, the address translation is as follows:

Simulated virtual address $$\rightarrow$$ Simulated physical address $$\rightarrow$$ Virtual address $$\rightarrow$$ Physical address

Note that the final transation to actual physical address will be done by the system.

We use a global `char` array for our simulated physical memory as it so happens that global variables such as these are stored in some of the lowest addresses in virtual memory.
Because of this, the array, despite existing in a 64-bit environment, only needs the 32 lower bits of a 64-bit address to address it.
This is great because it allows us to use the 32 lower bits to refer to a simulated physical memory location, despite being on a 64 bit system.
The downside is that we will need to convert the 32-bit simulated physical memory addresses into a 64-bit pointer in your actual user space before we actually try to access the simulated physical memory at that address.
To assist you with this, we have provided a few helper functions to perform this translation: 

```
void *get_system_pointer_from_pte(page_table_entry *entry);
void *get_system_pointer_from_pde(page_directory_entry *entry);
void *get_system_pointer_from_address(addr32 address);
```

Documentation on these functions can be found in the header files. A good example of using these functions can be found in 
`mmu.c`'s `mmu_add_process()` function.

A word of caution: shifting signed numbers can produce unexpected behavior, as it will always extend the
sign, meaning if the most significant bit is `1`, the "leftmost" bits after shifting right will all be `1`s instead of `0`s. 
Do yourself a favor, work with unsigned values.

## Memory Management Unit (`mmu.c` and `mmu.h`)

This is where the logic of an MMU is contained in. Familiarize yourself with the provided utilities above, as well as the `struct mmu` before proceeding. For this assignment you are responsible for handling reads to and writes from virtual addresses.

The functions you are to complete are:

```
void mmu_read_from_virtual_address(mmu *this, uintptr_t virtual_address, size_t pid, void *buffer, size_t num_bytes);
void mmu_write_to_virtual_address(mmu *this, uintptr_t virtual_address, size_t pid, const void *buffer, size_t num_bytes);
```

These two functions will first translate simulated virtual memory addresses into simulated physical memory addresses. Then, you will read from, or write to these simulated physical memory addresses. During the reading and writing process, you will need to:
- Update any page directory and page table entries as necessary
- Update the TLB as necessary
- Request for frames, or read pages from disk as necessary
- Raise any TLB misses, page faults or segfaults that you encounter

Note: For any virtual address, you should check whether the result has been already cached in the TLB (see `tlb.h`). If not, you must search the page tables.

Note: No reads or writes should occur if you encounter a segfault

The following illustration demonstrates how to translate from a virtual address to a physical address:

![Virtual Address Translation](/images/assignment-docs/lab/ideal_indirection/virtual_address_translation.png)

That this image is saying is that you are to take the top 10 bits of the provided virtual address to index an entry in the page directory of the process.
That entry should contain the base address of a page table.
You are to then take the next 10 bits to index an entry in the page table you got in the previous step, which should point to a frame in physical memory.
Finally you are to use the last 12 bits to offset to a particular byte in the 4kb frame.

## Testing

Make sure you throughly test your code as usual. We have provided some tests cases, but we encourage you to write your own as well. Use the provided test cases as a reference to learn to create tests with good coverage.
