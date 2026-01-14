# Running Journal of learnings

## 09/11/2025

- [hetzner-k3s](https://vitobotta.github.io/hetzner-k3s/) is awesome, you can create an HA Kubernetes cluster on Hetzner for very cheap
  - The configuration file is relatively simple as well, with a lot of good documentation on the site, i've included a sample documentation [here](./kubernetes/self-hosted/cloud/hetzner/configuration/hetzner-k3s.yaml)

## 09/12/2025

- [cloudnativepg](https://cloudnative-pg.io/documentation/1.27) is a great product from what I am seeing right now. It was super easy to setup and configure with great documentation
  - The purpose of `cloudnativepg` is to run PostgreSQL within Kubernetes with ease. The idea being your compute and storage can be as collocated as possible without having to use an external service like RDS or something
  - It also documents that it is advisable to reserve nodes for your PostgreSQL cluster, basically only run Postgres workloads on a certain set of nodes [here](https://cloudnative-pg.io/documentation/1.27/architecture/#reserving-nodes-for-postgresql-workloads). You can do this via taints/tolerations, or node selectors
  - You can configure backups via Object store or native Kubernetes volume snapshots and that is documented [here](https://cloudnative-pg.io/documentation/1.27/backup/)
  - [Important documentation](https://cloudnative-pg.io/documentation/1.27/appendixes/backup_volumesnapshot/#how-to-configure-volume-snapshot-backups) on how to configure `VolumeSnapshot` backups
  - [Important documentation](https://cloudnative-pg.io/plugin-barman-cloud/docs/usage/) for using the new way of backing up data to the cloud
  - I learned how to do backups and recovery from an s3 bucket/object store
- k3s
  - You can rotate certificates manually via [here](https://docs.k3s.io/cli/certificate#rotating-client-and-server-certificates)
  - Certificates will automatically rotate if they are within 120 days of expiry

## 09/13/2025

- k3s
  - Learned how to backup and restore etcd data, it seems like the `--node-ip` argument is important because that is where the `k3s` program looks for listening services
    - The script sample is [here](./kubernetes/useful/scripts/k3s-cluster-reset-backup.sh)

## 09/16/2025

- kubeadm
  - Backing up and restoring etcd instructions [here](https://devopscube.com/backup-etcd-restore-kubernetes/)
  - The script to backup `etcd` for `kubeadm` is located [here](./kubernetes/useful/scripts/etcd-kubeadm-backup.sh)
  - The script to restore a backup for `etcd` is located [here](./kubernetes/useful/scripts/etcd-kubeadm-restore.sh)
  - It seems as though if you want to stop the Kubernetes API server so that you can restore etcd, you can do so by moving the manifests out of the `/etc/kubernetes/manifests` directory
    ```bash
    sudo mv /etc/kubernetes/manifests/kube-apiserver.yaml /tmp/
    ```
  - And to resume the service, you would just move the manifest back to the `/etc/kubernetes/manifests` directory
  - You can compress the backup file by using `gzip` or `zstd`, this is to incur lower storage costs on s3
  - To scrape metrics for all the control plane components, you should actually just run an agent within the cluster. My opinion is that you should just use the `otel` collector as a `daemonset`
- Some overall thoughts
  - I think that backing up and restoring etcd is way simpler with `k3s` than `kubeadm`, because it is built into `k3s`. You can provide configuration for automated backups when starting a `k3s` cluster
  - With `kubeadm` it is a whole lot more manual. You'd have to provide your own scripts for backing up and restoring

## 09/17/2025

- `ReplicaSet`
  - `ReplicaSet` is usually not used directly, but is indirectly provisioned via a `Deployment` which manages the `ReplicaSet`'s
  - It can own a non-homogeneous set of pods, as long as the selectors match
  - The reason to use a `Deployment` is because the `ReplicaSet`'s are managed for you (during rolling updates). For instance during rolling updates, if you use `ReplicaSet` directly, you'd need to write custom logic for replacing old pods with new ones
- `StatefulSet`
  - A [headless service](https://kubernetes.io/docs/concepts/services-networking/service/#headless-services) publishes the IP Addresses of the pods in a particular `StatefulSet`, so you can address each pod like so:
    ```
    <pod-name>.<service-name>.<namespace>.svc.cluster.local
    ```
  - A use case of a `StatefulSet` is for addressing individual pods (if that is your use case), instead of addressing a `Service` that points to a `Deployment` and load balances across pods
  - If you want to network to a random pod instead of a particular pod, you can just point to the headless service
    ```
    <service-name>.<namespace>.svc.cluster.local
    ```

## 09/24/2025

- `talos`
  - Learned how to bootstrap talos on AWS EC2 instances. It was pretty seamless, within about 10 minutes I was able to get a Kubernetes cluster up and running
  - It is a bit weird though that you cannot ssh into the instances, since the Talos machine image doesn't have an ssh server

## 10/01/2025

- `Next.js`
  - `next.js` automatically optimizes fonts in the application when you use the `next/font` module. It will download font files at build time and host them with other static assets. You can eliminate unnecessary network requests with this
  - `next/image` optimizes images in a lot of ways
  - Make sure to set width and height on images identical to the aspect ratio of the original image
  - **Question**: What is layout shift in FE development?
  - pages are automatically nested in a layout if you have a `layout.tsx`, then any `page.tsx` nested under the layout will use the layout. On navigation only the page component re-renders not the layout
  - `next/link` allows for doing client side navigation to prevent full page refreshes when trying to navigate. The `Link` component also prefetches the page, so navigations to that said page will appear near instant
  - You can only use React Hooks in client components
  - Server components are default in `next.js` and they can be `async`
  - `loading.tsx` is a special file in `next.js` for rendering a component while data is being rendered
  - **Question**: What is `Suspense` and how would I use it?
    - Seems like it allows you to provide a fallback component while a wrapped component is fetching its data
    - You should look to use `Suspense` when a component relies on data fetching if you want that effect for the user

## 10/02/2025

- `Next.js`
  - You should move data fetching down to the components that need it
  - Debouncing is used when you need to limit the rate at which a function is firing

## 10/10/2025

- Networking
  - The first 24 bits (first three numbers in an IP Address), determine the network, while the last 8 bits determine the actual host
  - `192.168.123.255` and `192.168.123.0` are invalid IP Addresses because the host octect can not contain all 0s or all 1s
  - You can further divide a network into subnets by providing a subnet mask
  - CIDR notation `192.168.10.15/24`. This means the first 24 bits belong to the network portion leaving 8 bits for the host
    - The Broadcast Address is represented where all the host bits are set to 1, so in this case `192.168.10.255`
    - The Network Address is represented where all the host bits are set to 0, so in this case `192.168.10.0`. This identifies the network
    - The Address Range for this would be `192.168.10.1` -> `192.168.10.254`
    - The Subnet mask in this case will be `255.255.255.0`

## 10/15/2025

- OpenAI Agents SDK
  - The agents SDK allows for you to create multiple agents and chain them together for a coordinated purpose
  - This [here](https://openai.github.io/openai-agents-js/) is a great guide for using the Agents SDK in TypeScript

## 10/31/2025

- RAG (Retrieval-Augmented Generation)
  - To implement RAG you will use a Vector Database and embed relevant text for whatever is of interest
  - The you will make the model aware of the extra context within the vector database
  - What I am seeing is that `LangChain` makes this really easy (Python)
    - [This](https://www.youtube.com/watch?v=E4l91XKQSgw) is a great video showing the basics

## 11/06/2025

- Clickhouse DB cluster system design
  - Have a general Postgres/MySQL database to manage metadata of cluster creations, users, etc
  - Orchestrate the creation of the cluster on Kubernetes with a `ClickHouseDB` operator. So you can report the status of the cluster creation accurately
    - The actual ClickHouse DB needs to get created
    - Volumes need to be provisioned via PVC
    - TLS certs need to be generated via `cert-manager`
    - DNS records need to be created on whatever DNS provider
  - The CRD will report to us in the `status` when the cluster is ready/not ready, and we can have an external service that watches for the status, and writes to the database that the cluster is ready with whatever information needed for the customer to access the instance
  - ChatGPT link: https://chatgpt.com/share/690cc9a8-2600-8009-b10f-abc6a445e669

## 11/08/2025

- PKI in Kubernetes
  - The Root CA consists of a private key (`ca.key`) and public certificate (`ca.crt`)
  - The private key is kept secret while to public certificate is distributed cluster wide. This is because any client connecting over HTTPS needs to provide the `ca.crt`
  - You would then create a private key and a certificate signing request for each component that needs to verify its identity with the root CA (`kubelet`, `kube-scheduler`)
  - From the `csr`, you would then actually sign a certificate which will create a `{kubelet, api-server}.crt`
  - Any client that trust the `ca.crt` will trust the API server when communicating with it. The client would need to provide the `ca.crt` when sending requests to the api server
  - 1. The client validates the server's certificate (either publicly trusted or provided by the client `--cacert`) 2. The server requests the client's certificate and the client sends its public certificate 3. The client proves it owns the matching private key by cryptographically signing part of the handshake

## 11/14/2025

- Deployment vs. StatefulSet
  - In the `PodSpec` of a Deployment you can only specify 1 `persistentVolumeClaim`. So if you want pods to use different PVCs, you have to create multiple Deployment
  - For a `StatefulSet` you can achieve an affect of 1 PV per pod all within the definition of a `StatefulSet`. You'd use `volumeClaimTemplates`, and this would create unique PVCs with an ordinal number per pod

## 12/12/2025

- What is the difference between AI/ML/Neural Networks/LLMs?
  - AI is the general field which encompasses many subfields like NLP, computer vision, and Machine Learning, etc.
  - Machine Learning is a subfield of AI that focuses on learning from data to find patterns, make predictions, and improve performance, etc.
  - Neural Network is a specific Machine Learning algorithm that where it's modeled after a human brain to detect patterns powered by adjustable weights, and biases
  - LLMs is an example of a Deep Nerual Network with numerous hidden layers, allowing them to learn complex patterns from vast amounts of data

## 12/15/2025

- Unix vs. Linux
  - They are both operating systems
  - Linux is a Unix-like operating system
- Linux Distributions
  - OS built on top of GNU/Linux that adds additional pieces of software catering to a specific user group
  - Ubuntu is part of the Debian Family and CentOS stream is part of the Red Hat family

## 12/16/2025

- Datadog
  - Metrics
    - For count metrics, you have to examine the rollup which represents the time bucket width. It seems to default to 60s
    - The timestamps usually represent the end of the time period with the configured rollup. So a timestamp of 12:00:00, with a value of 15 means that there were 15 discrete events that occurred from 11:59:00 - 12:00:00
    - Usually for a gauge metric it is common to do averages where as for count metrics it is common to do sums and rates
- Linux
  - `touch` is an upsert command. If the file already exists it updates its timestamp, otherwise it will create the file specified
  - `mv` can move and rename a file in one command, and `cp` can copy and rename at the same time as well
  - filename expansion is the process in which your shell will rewrite a command before it is actually executed
  - For globbing, wildcard characters should not be quoted. Quoting is a good way to disable globbing for particular commands, depending on your use case
  - `wc` will tell you how many lines, words, and bytes are in a file by default. The expanded command is `wc -lwc`
  - POSIX standard defines how a Unix system should act
  - The redirection `>` either creates or overwrites, whereas `>>` appends to or creates a file
  - `stdin` is channel 0, `stdout` is channel 1, and `stderr` is channel 2
- vLLM
  - `--tensor-parallel-size` specifies how vLLM should shard the model weights and layers across multiple GPUs
  - `--gpu-memory-utilization` specifies the amount of total GPU memory vLLM will pre-allocate for weights, KV cache, activations
  - `--max-model-len` specifies the maximum total (prompt + generation tokens) that a model can process. A strict upper bound on number of tokens for a single request
  - `--max-num-seqs` specifies how many concurrent requests vLLM can process within a single batch
  - Personal notes:
    - For a larger `--max-model-len` usually that has a negative effect on `--max-num-seqs` since the GPU memory is being used for processing a bigger request
    - Increasing `--max-model-len` and `--max-num-seqs` usually requires more GPU memory
    - Increasing `--tensor-parallel-size` allows for more memory to be used on the KV cache and other important factsrs during inference time

## 12/17/2025

- Linux
  - The `tee` command will write to stdout, and write to a file at the same time
  - `tee -a` will append instead of overwrite
  - `tr` is a character replacement utility, and it works with character ranges as well
  - `tr -d` is for deleting characters
  - `cut` allows for processing and extracting data from a file or stdin
  - `cut -b` is cutting by bytes, and `cut -c` is cutting by characters
  - `cut -d ' ' -f` is cutting by fields
  - `sed` can be used to delete, insert, or replace lines
  - The shell is the outer layer of the operating system. It takes commands from users and translates them into a form the kernel can understand
  - So even if you click to open a program, it uses a shell to execute that "command"
  - Possible variable expansions: $HOME, ${HOME}, "$HOME", "${HOME}". We should prefer using double quotes (to avoid word splitting), and curly braces (to make it clear where the variable ends)
  - word splitting happens at every character listed in the `IFS`. That can be a newline, space, or tab
  - You can disable word splitting by wrapping parts of the commands into quotes
  - no quoting vs. single quotes vs. double quotes
    - no quoting means all available shell expansions are applied
    - single quotes: all expansions are disabled and word splitting is disabled. Even escaping is disabled
    - double quotes: most expansions are disabled, and word splitting is disaled. However, some expansions are enabled like variable expansions
  - Always try to use the quoting style that is the most restrictive and serves your use case fine

## 12/18/2025

- Linux
  - Brace expansion (available in Bash 4), handy features if you want to create lots of files, or do other things in bulk, etc.
  - Process substitution:
    - To use output of a process as a temporary file: <(command)
    - Allows you to remove the need to create a file in order to do further processing
  - What is a file?
    - A container for storing, accessing and managing data
    - Can have various attributes which are stored in an inode
  - How is data stored in a file in Linux?
    - inode stores metadata: file type, access rights, num of hardlinks, file size, and where data is physically stored on disk
  - Different types of files
    - ordinary files, directories, symlinks, character device, block device, named pipes, sockets
  - What is a symlink?
    - Serves as a reference to another file or directory
    - A good use case is to use a different drive or disk to store data that has more space that another drive or disk
  - What is a hard link?
    - Hard link is a directory entry or reference to an existing inode
    - Data is only deleted f all the hardlinks are removed
  - The inode limit
    - During the creation of a filesystem, space is reserved for inodes, and that space can not be used for anything else
    - `df -ih` will tell you the usage of your inodes on the various filesystems
    - You can theoretically reach this limit by creating a lot of smaller files
  - Unbuffered vs. Buffered I/O
    - Unbuffered directly handles data between the I/O device and the program
    - Buffered uses a temporary storage area to hold data before it's being received by the I/O device
  - What is a device?
    - A physical or virtual entity that can be accessed through a file-like interface
    - Pseudo devices: `/dev/null`, `/dev/random` (produces stream of random numbers)

## 12/19/2025

- Linux
  - `/proc` folder allows us to inspect our system, the resources, and other important information on it
  - `/proc/cpuinfo` shows information about the vendor and other CPU information
  - `/boot` contains files for the bootloader
  - `/etc` contains system-wide configuration
  - `/mnt` contains mount points for additional filesystems
    - Usually if you attach drive and want to mount it as a filesystem, you would mount it on a subdirectory of the `/mnt` directory
  - `/opt` for optional software packages are stored here
  - `/run` meant for run-time data
  - `/sys` meant for information about devices, drivers, and kernel
  - `/usr` contains shareable, read-only data
  - `/var` for variable data. Such as logs, databases, websites
  - Different types of users on a Linux system:
    - root, regular, service users
    - User information is stored in various files: `/etc/passwd`
    - `/etc/passwd` contains basic information about users such as usernames, user ID, group ID, home directory and default shell
    - `/etc/shadow` stores encrypted user passwords and additional information
    - `/etc/group` contains additional information about the groups on a Linux system
  - Groups
    - All users have a primary group, and they can be assigned to unlimited groups

## 12/20/2025

- Linux
  - `useradd` is a command to add new users to the Linux system
  - You can modify user's details with `usermod` command
  - With `usermod` you can change the default shell, description, home directory, username, or group
  - With `userdel` command youn can delete users, the `-r`, or `-f` option will delete the home directory and mails. `-f` is a little more forceful
  - The file `/etc/group` will tell you the groups on a Linux system
  - To run `sudo`, the user must be in the `sudo` group
  - `usermod -aG` will add a user to a secondary group
  - sudoers
    - You should be careful when editing the `sudoers` file directly. You should instead use `visudo`, as it is safer
    - A `%` in front of a name specifies a group
    - You can also specify the commands the users can run when having sudo permissions
  - You should be careful who you give sudo access to on your system, because that gives them a lot of power over the machine

## 12/21/2025

- Linux
  - `chown user:group file.txt`
  - Only owners of files are allowed to change the permissions of it
  - File permissions for directories:
    - (r) to access directory contents
    - (w) adding or removing files from a directory
      - Also need (x) permissions for this too
    - (x) traversing a directory
  - `chown` and `chmod` with `-R` can recursively do what they need to do within directories. Either change permissions or change owners
  - `umask` allows us to specify who should be able to access new files, for default permissions for new files or directories
    - Default value for directories is 777 and files is 666, and you would subtract the umask values from both of those
  - `SUID` and `SGID` bits are used for allowing executables to be ran in the context of the executing user or group
  - Prefer groups for managing privileges instead of regular users
  - Follow the principle of least privilege
  - Minimize the amount of users with elevated privileges
  - Processes:
    - They are instances of programs
    - Independent execution unit with its own resources
    - The Kernel manages processes and assigning resources to them
    - We can list processes in the shell with the `ps` command
    - `ps --forest` can show process hierarchy as an ASCII art tree

## 12/22/2025

- Linux
  - Niceness
    - ranges from -20 to 19 for processes
    - Default niceness for processes is 0
  - `pgrep` is a command for searching for processes on a Linux machine based on a name
  - Signals
    - ctrl-c uses the `SIGINT` signal to a running process
    - `kill -s {SIGNAL} PROCESS_ID` allows you to send signals to processes
  - Processes
    - When a child process terminated, the kernel will send a `SIGCHLD` signal to the parent
    - The parent process uses a syscall to collect the child's exit status
    - Orphan process is where a parent process ends before a child. In this case the child becomes adopted by the init process
    - Zombie process is one that has finished executing but still has an entry in the process table
      - usually occurs when the parent process has not read the child's exit status
    - A process usually goes into an uninterruptable sleep (D) state, when it is doing I/O

## 12/23/2025

- Linux
  - `top`
    - `-u` can view processes from a particular user
    - `-d` set the delay between updates
  - Jobs, foreground, and background
    - If you start a process with `&`, you will get a job ID and a PID back as output
    - jobs can represent multiple processes running
    - The `jobs` command will show you all the jobs running on the machine
    - The `fg` command is able to bring a process to the foreground
    - Only foreground jobs/processes can receive keyboard input
    - With the `wait` command you can wait for background jobs to finish executing

## 12/24/2025

- Linux
  - `nohup`
    - disables the program from receiving the `SIGHUP` signal
  - `apt` vs. `apt-get`
    - `apt-get` is considered more stable, so it is preferred for shell scripts. It has a stable API
    - The repository files are stored in `/etc/apt/sources.list`, and third party repositories are stored in `/etc/apt/sources.list.d/*`
  - The boot process
    - The bootloader is the first software to load run on startup to load the operating system
  - Kernel
    - Key functions of the kernel: process management, memory management, file system management, networking stack
    - Kernel modules are pieces of code that can be loaded into the kernel on demand

## 12/25/2025

- Linux
  - `systemd`
    - On most Linux systems this is the initial process that runs, pid 1
    - You can launch timers, services, etc.
    - targets
      - groups units logically to a goal
  - cgroup
    - Organizes processes hierarchically
    - allows us to evenly distribute resources
    - can span multiple processes
    - a `slice` allows you to define constraints around resource usage for processes

## 12/26/2025

- Linux
  - `systemd`
    - To edit unit files its preferred to edit them by using `systemctl edit {unit}`, because it will create an extension/override for the main unit files
    - The above is better for maintainability of the unit files especially if they were installed via a package manager
    - `timers` to me seem like cron jobs. It seems as though you can run another `systemd` unit with a timer, and specify an interval for it, with a resolution
  - `journalctl`
    - You can use it to output logs from different boots of the system
    - The `-f` option will follow logs in real time
  - storage
    - Partition table
      - MBR
        - limited to 4 primary partitions
        - limited to 2TiB disk size
    - Look out for things that use the JEDEC standard
    - Decimal vs. Binary
      - Gibibytes (1024^3), gigabyte (1000^3)

## 12/27/2025

- Linux
  - Filesystems
    - types
      - ext3
      - ext4
      - fat32
        - can usually only store files up to 4GB
      - xfs
        - proficient in managing large files
    - `parted`
      - used for maintaining partitions on a volume/drive
  - Volumes
    - A logical storage unit on a computer
  - Mount
    - Connecting a filesystem of a volume to our directory tree
      - optimized for parallel I/O
      - snapshot support
    - The `mount` command will show you all the filesystems and where they are mounted at
    - `/etc/fstab`
      - defines how storage devices and partitions should be mounted
      - read during boot, and allows for auto mounting volumes
      - There is a specific format for this, but usually when you mount a volume as a filesystem and do not define it in this file the mount will be lost
- Drive vs. Volume vs. Filesystem
  - A drive is a physical device, so an HDD/SSD, etc
    - it can expose blocks or sectors
    - knows nothing about files or directories
  - A volume is a logical section of a drive that the OS can manage independently
    - They are usually created via partitioning
    - One drive can have many volumes
  - A filesystem defines how files and directories are stored and retrieved
    - There are different formats for filesystems that the OS makes use of. Each one has different properties
  - Think about it like this:
    - Drive is: `/dev/sda`
    - Volume is: `/dev/sda1`
    - Filesystem is: an ext4 filesystem on `/dev/sda1`

## 12/28/2025

- Linux
  - Resizing a filesystem
    - The filesystem must support resizing
    - For example `ext4` is a filesystem that can be resized
    - You should unmount the volume first before you resize it
    - For expanding FS and partitions you need to
      - resize the partition to a larger size and then the filesystem
    - For shrinking FS and partitions you need to
      - resize the filesystem to a smaller size then the partition
  - LVM
    - The idea is to span a volume over multiple drives, and adjust the filesystem accordingly

## 12/29/2025

- Linux
  - Networking
    - MAC Address
      - Unique identifier for network interfaces
      - Assigned by manufacturers
      - Used for telling machines what network interface to send packets to
    - OSI Model
      - Layer 1
        - Physical layer, ethernet cables
        - The unit that is transmitted on this layer is called bits
      - Layer 2
        - Provides data transfer between adjacent network nodes (Ethernet, MAC Addresses)
        - The unit that is sent on this layer is called frames
        - Premise here is that there is a reliable connection between devices on the same network
        - Devices that operate on this layer are bridges, switches, wireless access point
      - Layer 3
        - Provides data routing between networks (IP Addresses, routers)
      - Layer 4
        - Transport Layer between hosts (TCP, UDP)
      - Layer 5
        - Controls the sessions between applications
      - Layer 6
        - Translates, encrypts and compresses data (SSL, TLS)
      - Layer 7
        - Provides interface for applications to communicate over the internet (HTTP, FTP)
- Claude code
  - subagents
    - allows you to create dedicated AI agents for specific tasks. Can do it with `/agents`
    - You can give agents access to specific tools, MCP servers, etc.

## 12/31/2025

- Linux
  - Can you send a packet to another machine within the LAN?
    - You need to calculate the logical AND of the subnet mask and the source and destination IP addresses, if the result is the same the packets can be sent directly
  - ARP (Address Resolution Protocol)
    - This is used to map an IP Address to a physical MAC Address on a LAN
    - It answers the question of "I know the IP Address, what MAC Address should I send this packet to?"
    - It is only used within a LAN
  - It seems as though if you want to send packets to devices in the same LAN, you can just consult the ARP table for addressing the destination device
  - If you want to send packets to the internet (google.com), the destination MAC address would be that of your internet GW, or your router
  - The `ip route` command will show you how exactly you can reach the destination IP, whether it is via a GW or any other means
  - DHCP (Dynamic Host Configuration Protocol)
    - Server
      - Stores IP Address pool
      - Manages IP address leases
    - Client
      - Requests IP Address and configuration
      - Renews or releases leases

## 01/01/2026

- Linux
  - Layer 4 (OSI)
    - RST packet means that a port is closed on a remote host
    - NAT (Network Address Translation)
      - The router rewrites the source destination of the packet when a connection is initiated by a machine within a LAN
      - The router remembers which machine initiated a connection and uses NAT to rewrite headers to send packets to the respective machine within the LAN
      - This is usually for connections initiated within a LAN to the outside world, but not the other way around

## 01/02/2026

- Linux
  - DNS
    - When translating a domain name to IP, the OS reaches out to several nameservers
    - NS records list authoritative nameservers for a domain
    - From my understanding, DNS queries first reach out to the TLD nameservers which would contain information for authoritative nameservers for a specific domain. Then the query continues by asking the authoritative nameservers about a domain and all of its records: A, AAAA, MX, CNAME, etc.
    - mDNS
      - designate a special domain `.local` just for local networks
      - Using this could mitigate us having to assign static IP Addresses to machines within our local network
  - Hostname
    - You can change your hostname by editing the file `/etc/hostname`. You'd need a reboot for changes to propagate
  - IPv6
    - if multiple blocks with only zeros follow each other you can omit the number part of the address, but only allowed to do this once `::` in the address
    - Can remove the need for NAT, since there are enough addresses to go around to every device
    - Dual stack means network supports both IPv4 or IPv6
  - Linux Distributions
    - Red Hat Family includes CentOS Stream, RHeL, Fedora
    - Order of stability (more stable to less stable): RHEL, CentOS Stream, Fedora
    - The RHEL source code is open source under the GPL license
    - The Debian Family: Ubuntu, Kali Linux, Raspberry Pi OS, Linux Mint
      - Ubuntu LTS release cycle occurs every two years
    - The SUSE family: SUSE Linux Enterprise, openSUSE
      - Aimed at businesses and enterprise environments
      - openSUSE is a community driven project driven by SUSE
    - Arch Linux
      - Always provided the latest software versions
      - Not really made for production use
    - Gentoo Linux
      - Extremely flexible
      - Steep learning curve

## 01/09/2026

- Postgres
  - Uses process-per-user client/server model
  - Postmaster is the process that receives requests from clients
  - A process is forked to process the actual query
  - Seems like reads and writes go through the shared buffer first before disk
  - Postmaster
    - first process that gets started when starting PostgreSQL
    - responsible for:
      - Authz, authn
      - performing recovery
      - initializing shared memory
  - Checkpointer process
    - ensures that all dirty buffers created up to a certain point are sent to disk for the WAL recycle process
  - You can configure memory settings, sizes of components used by processes, etc in a `postgresql.conf` file
  - Postgres Page
    - All data is stored in pages
    - Fixed block of data
    - 8KB in size
    - smallest unit of data storage
    - every table and index is stored as an array of pages of fixed size
  - Segment
    - made of multiple pages
    - 1GB in size

## 01/13/2026

- Postgres
  - You can map OS usernames to Postgres usernames in the identity file
  - The `pg_hba.conf` file will allow you to specify how connections should be allowed to your Postgres server

## 01/14/2026

- Postgres
  - Schemas
    - Namespaces in database
    - You should not create your main tables/objects in the public schema, it seems to be only for system level objects
