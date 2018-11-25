---
layout: doc
title: "Resplendent RPCs"
submissions:
- title: Entire Assignment
  due_date: 12/5/2018 11:59pm
  graded_files:
  - dns_query_svc_impl.c
  - dns_query_clnt_impl.c
learning_objectives:
  - Learn about RPCs with rpcgen
  - Learn basic UDP networking
  - Learn about DNS
wikibook:
  - "Networking, Part 1: Introduction"
  - "Networking, Part 2: Using getaddrinfo"
  - "Networking, Part 6: Creating a UDP server"
  - "RPC, Part 1: Introduction to Remote Procedure Calls"
---
## Warning
Before you begin this lab, remember to run `rpcinfo`, then `rpcgen dns_query.x`!
This call generates a C version of `dns_query.x`, the server stub, and the client stub.
If you do not run this command, your implementations will not compile with `make`!

## RPCs?
This lab will serve as an introduction to remote procedure calls. Remote procedure calls, as the name suggests, are a way to execute a procedure (in C, a function) that exists in a different address space and in any language. (In this lab our client in C executes a procedure in C, but it could execute a procedure written in python as well).
In order to accomplish this, the server will agree to take in a 'request' or 'query' from a client and send a 'response' back, and the client will agree to send a 'request' or 'query' and receive a 'response'.
 In rpcgen, the request and response are defined in a .x file in XDR, which is a language that is useful for encoding data that is to be transferred between different machines. It is easy to translate this file into any language, so in this lab it is translated into a C-language .h file with rpcgen.
 Server and client stubs can be generated as well from this .x file in any language (both in C in this lab), and these stubs deal with the networking between the server and client. 
The implementation logic, AKA what the server and client decide to do with these requests and responses they send back and forth, is left up to you.
Effectively, using RPCs abstracts away the complex networking calls that are usually necessary to complete this task (i.e. it's one layer above TCP/UDP). The only thing you have to do is serialize and deserialize to/from the request and response objects defined in the .x file.

## Overview
In this lab, we will create a client that queries a server for an IPv4 address for a given domain over RPC. The server that receives this query over RPC is essentially a recursive DNS server which either checks its cache for the IP or queries several namesevers in the DNS resolution hierarchy via UDP.

## DNS overview
As you know, domains are not useful as-is; they need to be translated into an IP address. The IP addresses are not stored all at one place; they are distributed hierarchically through multiple servers responsible for them, called authoritative nameservers. A recursive DNS server (which is usually provided by your ISPs) does the work of contacting all the necessary nameservers in this hierarchy.  Here's an overview of how it does this:
 First it goes to the root nameserver, the server responsible for '.' AKA the root of all domains (fun fact; all domains have an implicit . at the end, so www.microsoft.com is also www.microsoft.com.). This server will hold the nameservers responsible for top-level domains like .com, .org, and .net, so the appropriate nameserver is returned to the recursive server. The recursive server then goes to the top-level nameserver it just got, which is responsible for holding nameservers responsible for domains registered under the top-level domain, so .com is responsible for nameservers for reddit.com, tumblr.com, twitter.com, etc, so the appropriate nameserver is returned. The nameserver just received is authoritative for your initial domain, so when you contact it it will return your final answer! The recursive server returns this final answer and the query is finished.
This recursive DNS server is the server you will implement in the lab.

## Say that again? / Format UDP input and output
For example, let's walk through how 'www.microsoft.com' would be resolved by our lab's recursive DNS server. In this lab, we will always contact exactly 3 servers in this manner to complete a request. 

- We need to find a server responsible for '.', the root of all domains. One is stored locally in `domain_to_nameserver/root_servers` in the format ".;www.xxx.yyy.zzz:qqqq", where the information to the right of the semicolon is the IPv4 address and port. 
- Send that root nameserver address (hint: check out `inet_pton`) and port ".com" via UDP to get the server responsible for ".com", and you will receive the bytes 'www.xxx.yyy.zzz:qqqq' representing the ".com" nameserver's IPv4 address and port.  
- Send that .com nameserver address and port "microsoft.com" via UDP to get the server responsible for "microsoft.com", and you will receive the bytes 'www.xxx.yyy.zzz:qqqq' representing the "microsoft.com" nameserver's IPv4 address and port.
- Send that microsoft.com nameserver address and port "www.microsoft.com" via UDP to get an IPv4 address for "www.microsoft.com". You will receive the bytes 'www.xxx.yyy.zzz' representing the final IPv4 address for www.microsoft.com and your answer.
    
Note that all data is handled in plaintext that the maximum # of bytes to represent an IPv4 address is 15 and the maximum # of bytes to represent a port is 5.

### Failure
In this lab, if a server ever fails to retrieve a result, it will return "-1.-1.-1.-1:-1" if it is a root or top level nameserver and will return "-1.-1.-1.-1" if it is a regular authoritative nameserver. Make sure to check for this and set the success field in the server response accordingly!
Like in chatroom's `read_all_from_socket`/`write_all_to_socket`, remember to check errno when sendto() and recvfrom() return -1; certain error codes need you to call sendto() or recvfrom() again. If you don't get an error code that prompts you to restart, exit with error code 1.

## Why UDP?
In chatroom, a TCP connection made sense because you wanted to stay in contact with the chatting server for a long time, never lose messages, and receive messages in a particular order. 
When it comes to querying nameservers for DNS resolution in this lab, you only send one packet and receive one packet per server and then you're done.
The overhead in using TCP for this purpose is not necessary, so we opt to use the faster and less complex UDP.

## What to do
Below is a figure demonstrating the architecture and data flow of the entire lab.
![Architecture](../images/rpc.png)
As the warning at the top states, run `rpcinfo` then `rpcgen dns_query.x`. This generates the aforementioned client and server stub functions that deal with networking as well as `dns_query.h`. Look at `dns_query.h`, which is a C translation of `dns_query.x` and contains the structs that you and your client/server stubs use.

- In the client, serialize information into `query` to put into your client stub and deserialize and print information from `response` from your client stub. Implement a function that checks the local cache for the domain's IP address (you never need to write to the cache).
- In the server, deserialize information from `query` and serialize information into `response` to put into your server stub. Implement a function that checks the local cache for the domain's IP address (you never need to write to the cache). Implement a function that sends 3 UDP packets and receives 3 UDP packets to the appropriate nameservers to resolve the domain. 

## What to write
### `dns_query_clnt_impl.c`
`create_query()`: Return a pointer to a `query` on the heap, with the host argument as the query's host. `struct query` is defined in `dns_query.h`, so make sure to examine that file. 
`print_dns_query_response()`: Deserialize the information from `response`. Call `print_success()` with the appropriate information if response has success set to true, and call `print_failure()` if the response has success set to false. Note that success should be set on the server side!
`check_cache_for_address()`: Check through all the lines in the open file `"cache_files/rpc_client_cache"`; if one of them matches the hostname in the query, put the associated ipv4_address after the semicolon into the ipv4_address argument. The format of each line in `"rpc_client_cache"` is this: "[domain];[ipv4 address]", where each ipv4 address has a maximum length of 15 bytes. Return -1 if it's not in the cache and 0 otherwise.
### `dns_query_svc_impl.c`
`create_response()`: Fill in a pointer to a static `response`, allocating its fields on the heap as necessary. Fields are filled in with the requested domain and its resolved ipv4 address. 
`check_cache_for_address()`: Same as in `dns_query_clnt_impl.c`, but you check the lines in `"cache_files/rpc_server_cache"`.
`contact_authoritative_dns_servers()`: Contact 3 authoritative nameservers to complete a query for a domain's IPv4 address. See the header file or "Say that again? / Format UDP input and output" for detailed information. When the IPv4 address is obtained, copy it into the memory pointed to by argument ipv4_address.

## Testing
To make 3 toy nameservers for testing, run `./authoritative_nameservers` which by default runs a root nameserver on port 9000 that serves records from `domain_to_nameserver/top_level_servers`, a .com nameserver on port 9001 that serves records from `domain_to_nameserver/dot_com_servers`, and a google.com nameserver on port 9002 that serves records from `domain_to_ipv4_address/google_dot_com_addresses`. This will let you fully complete a DNS lookup of the IPv4 address of "www.google.com" given that you have a complete implementation. 
(This shouldn't be necessary to create a complete implementation, but if you want to test your implementation out with other domains, you can supply your own files as arguments. Check the usage of `./authoritative_nameservers` with the -h flag. Make sure to follow the format exactly and make sure that you reference the correct & existing servers and ports in the files you create!)
### Example
This command will set up the 3 toy nameservers:

```
    ./authoritative_nameservers
    Top level domain nameserver running on port 9001
    Root nameserver running on port 9000
    Authoritative nameserver running on port 9002
```

Run your server:
```
    ./server
```

Then send a query for a domain through the client. (Note that client requires two arguments. The first is the IP address of the server that will accept its RPC and the second is the domain to resolve.):

```
    ./client 127.0.0.1 www.google.com
    www.google.com has ipv4 address 129.122.2.4
```

## Extra stuff
- Things this lab didn't cover on DNS:
    - DNS communications usually happen on port 53, so records don't need to specify a port to send packets to (unlike in this lab)
    - IPv4 addresses in a cache need to have a valid time to live (they can’t be too old or you have to requery!)
    - DNS has more details; you can do queries that specifically ask for a nameserver or a mailserver, for example.
    - There can be multiple IP addresses for one domain, but not in this lab.
    - This lab only covers the case where the domain is defined as [something].[something].[top-level]., but as you know there can be more subdomains as well e.g. www.cs.illinois.edu
- DNS has some weak points as it is...
    - A particular nameserver can be DDOSed so that all caches of a domain expire and no one can access it
    - You can mess with any computer's DNS resolution so that it returns invalid IPs for a domain. A good way to mess with your friends is making it so that www.google.com always directs to an IP address for www.bing.com.
- Mentioned before, but keep in mind how simple it is to send data between 2 programs written in 2 different languages with RPCs
- If you're curious about more modern frameworks for RPCs, check out gRPC (https://grpc.io/).

## Graded Files
*   `dns_query_svc_impl.c`
*   `dns_query_clnt_impl.c`

