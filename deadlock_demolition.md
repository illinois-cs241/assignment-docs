---
layout: doc
title: "Deadlock Demolition"
learning_objectives:
  - Synchronization Primitives
  - Deadlock Detection using a Resource Allocation Graph
---

## Overview

You will be building a library for deadlock-resitant mutex (drm) locks. A drm should behave like a pthread_mutex_t but not allow itself to be locked by a thread if the attempt to lock it would result in deadlock. To detect deadlock, you will need to maintain a Resource Allocation Graph and be able perform cycle detection on it. See [this page](http://cs241.cs.illinois.edu/coursebook/Deadlock#resource-allocation-graphs) for more information about Resource Allocation Graphs.

Good luck!


## Testing

**Testing is ungraded, but highly recommended**

Please test this on your own in a variety of ways. Be careful of race conditions! They can be hard to find!  We've given you a `libdrm_tester.c` file to write tests in.

## Testing Tips




### Thread Sanitizer

We have another target executed by typing `make tsan`. This compiles your code with Thread Sanitizer.

ThreadSantizer is a race condition detection tool. See [this page](https://github.com/angrave/SystemProgramming/wiki/C-Programming%2C-Part-5%3A-Debugging#tsan) for more information.

**We will be using ThreadSanitizer to grade your code! If the autograder detects a data race, you won't automatically get 0 points, but a few points will be deducted.**


## Helpful Hints and Notes

*   Make sure you thoroughly test your code! Race conditions can be hard to spot!
*   Attempting to visualize your code or diagram it in certain cases can sometimes be a huge aid and is highly recommended!

** In any of `semamore.c`, `barrier.c`, or `queue.c` you may not use semaphores or pthread_barriers **

**ANYTHING not specified in these docs is considered undefined behavior and we will not test it**
For example, calling queue_push(NULL, NULL) can do whatever you want it to. We will not test it.
