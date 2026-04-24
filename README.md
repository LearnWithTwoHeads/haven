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

## 02/24/2026

- CoreDNS and DNS Resolution in Kubernetes
  - DNS search domains and `ndots`
    - A pod's `/etc/resolv.conf` contains a `search` list of domain suffixes and an `ndots` value
    - `ndots` controls whether a name is treated as fully qualified based on the number of dots it contains
    - With `ndots:2`, names with fewer than 2 dots get the search suffixes tried first, names with 2+ dots are tried as-is first
    - For example, resolving `my-service` with `ndots:2` causes the resolver to walk the entire search list: `my-service.default.svc.cluster.local`, `my-service.svc.cluster.local`, etc.
  - Search domain leakage
    - If `resolvconf_mode: host_resolvconf` is set in kubespray, pods inherit the node's search domains
    - On OpenStack hosts with Tailscale, this can inject non-Kubernetes search domains like `openstacklocal`, `warg-pancake.ts.net`, etc.
    - These cause cluster-internal names to be queried with useless suffixes (e.g., `my-svc.namespace.svc.cluster.local.openstacklocal`) and forwarded to upstream DNS, resulting in timeouts
    - Setting `resolvconf_mode: docker_dns` generates a clean resolv.conf with only `cluster.local` search domains
  - CoreDNS Corefile server blocks (zones)
    - The Corefile is organized into server blocks, each handling a specific DNS zone
    - A query is matched to the most specific zone. For example, `foo.openstacklocal` matches an `openstacklocal:53 {}` block over the catch-all `.:53 {}` block
    - The `.:53` block (root zone) is the catch-all that handles everything not matched by a more specific block
    - You can add zone-specific blocks to short-circuit queries that should never reach upstream:
      ```
      openstacklocal:53 {
          errors
          cache 3600
          template ANY ANY openstacklocal {
              rcode NXDOMAIN
          }
      }
      ```
    - The `template` plugin with `rcode NXDOMAIN` immediately returns a "name does not exist" response without forwarding upstream
  - `autopath @kubernetes` plugin
    - Optimizes DNS search path resolution by walking the search list server-side in CoreDNS instead of the client (pod) making multiple round trips
    - Side effect: CoreDNS itself generates suffixed queries internally, so if non-Kubernetes search domains are present they get forwarded upstream
  - NodeLocalDNS
    - A DaemonSet that runs a DNS cache on every node, listening on `169.254.25.10` (link-local)
    - Pods query the local cache first, which dramatically reduces load on centralized CoreDNS pods
    - Uses iptables rules to bypass conntrack for DNS traffic
    - Enabled via `enable_nodelocaldns: true` in kubespray's `k8s-cluster.yml`
    - After enabling, kubelet must be reconfigured to point `clusterDNS` at `169.254.25.10` (requires kubelet restart, but does not kill running pods)
  - Forward plugin tuning
    - `prefer_udp` avoids TCP overhead for upstream queries
    - `expire` cleans up stale upstream connections
    - `policy random` distributes queries across upstream servers
    - `health_check` periodically verifies upstream servers are reachable

## 02/26/2026

- Kubernetes CSI Drivers and StorageClasses
  - CSI (Container Storage Interface) is a standard that exposes block and file storage to container orchestrators like Kubernetes
  - A CSI driver is deployed as pods in the cluster and handles the full volume lifecycle: creating, attaching, mounting, snapshotting, and deleting volumes on the underlying storage backend
  - A `StorageClass` references a CSI driver via the `provisioner` field and passes driver-specific configuration through `parameters`
  - Multiple `StorageClass` resources can reference the same CSI driver with different parameters (e.g., `fast-ssd` vs `cheap-hdd`)
  - CSI driver architecture consists of two components:
    - **Controller plugin** (Deployment): handles `CreateVolume`, `DeleteVolume`, `ControllerExpandVolume`, `CreateSnapshot`, etc. Runs with sidecar containers (`external-provisioner`, `external-attacher`, `external-resizer`, `external-snapshotter`)
    - **Node plugin** (DaemonSet): handles `NodeStageVolume` and `NodePublishVolume` (mount/unmount). Runs on every node with a `node-driver-registrar` sidecar
  - Dynamic provisioning flow:
    1. A PVC is created referencing a `StorageClass`
    2. The `csi-provisioner` sidecar in the controller pod watches for unbound PVCs matching its driver
    3. It sends a `CreateVolume` gRPC call over a local Unix socket to the CSI driver container in the same pod
    4. The CSI driver talks to the storage backend to provision the volume
    5. A PV is automatically created and bound to the PVC
    6. When a pod mounts the PVC, the kubelet calls the node plugin's `NodeStageVolume`/`NodePublishVolume` RPCs
  - Key `StorageClass` fields:
    - `provisioner`: must match the CSI driver's registered name
    - `parameters`: passed directly to the driver's `CreateVolume` call
    - `reclaimPolicy`: `Delete` or `Retain` — controls what happens to the backing volume when the PV is released
    - `volumeBindingMode`: `Immediate` (provision right away) or `WaitForFirstConsumer` (wait for pod scheduling, useful for topology-aware provisioning)
    - `allowVolumeExpansion`: if `true`, the driver's `ControllerExpandVolume` RPC is called when a PVC is resized
  - In the `renewed-escargot` cluster, the `rook-ceph.rbd.csi.ceph.com` provisioner is handled by two controller plugin pods (`rook-ceph.rbd.csi.ceph.com-ctrlplugin`), each running 5 containers: `csi-rbdplugin`, `csi-provisioner`, `csi-resizer`, `csi-attacher`, `csi-snapshotter`
  - The controller pods use leader election so only one actively processes provisioning requests at a time

## 03/03/2026

- Debugging Cilium VXLAN tunnel failures and disk space issues on Kubernetes bastion nodes
  - If `apt-get update` fails with "No space left on device", check `/var/log` for bloated syslog files. A single misconfigured service (e.g., Grafana Alloy logging at `info` level to syslog) can fill an entire disk with tens of millions of log lines
  - You can safely remove rotated log files (`syslog.1`, `btmp.1`) and truncate the current syslog to reclaim space immediately
  - When Kubernetes cluster DNS (`.svc.cluster.local`) fails on a node but works on others, check Cilium's VXLAN overlay connectivity
  - Use `ip -s link show cilium_vxlan` to check RX/TX counters. If RX is zero but TX is non-zero, the VXLAN tunnel is one-way broken — the node can send but never receives return traffic
  - Cilium uses the Kubernetes node `InternalIP` (set by kubelet's `--node-ip`) as the VXLAN tunnel endpoint. Other nodes send encapsulated traffic to this IP
  - If `--node-ip` is set to a public IP and the network firewall blocks inbound UDP 8472 (VXLAN port) to that public subnet, return VXLAN traffic will be silently dropped
  - You can verify this by checking the `tunnelendpoint` in Cilium's ipcache on a peer node: `cilium bpf ipcache list | grep <pod-cidr>`
  - The fix is to change `--node-ip` in `/etc/kubernetes/kubelet.env` to the private IP that is directly reachable from all cluster nodes, then restart kubelet and the Cilium agent pod
  - Use `tcpdump -i <interface> udp port 8472` to confirm whether VXLAN packets are arriving. Test on all interfaces (`-i any`) to rule out traffic landing on the wrong NIC
  - Use `bpftool net list` (not `tc filter show`) to verify Cilium's BPF programs are attached — newer Cilium versions use TCX attachment which is invisible to `tc filter`
  - Run Cilium CLI commands from inside the agent container (`crictl exec <container> cilium ...`) since the host-level `cilium` binary may not have access to the BPF maps
  - General lesson: when two identical nodes behave differently, compare their network paths methodically — same config does not mean same reachability if the underlying network treats their subnets differently

## 03/05/2026

- Networking Troubleshooting
  - This is a typical troubleshooting scenario for TCP networking:
    - Try to see if you can reach the host (using domain DNS) at a port using `nc -zv`
    - If `nc` command hangs, it usually means that the host is unreachable, or the port is not receiving TCP traffic. If the `nc` command exits 1, it usually means the host is reachable but the port on the destination host is not capable of receiving TCP traffic
    - If that doesn't work use `dig` to see how many A records are listed for that particular domain name
    - Try each of those IP address A records with `nc -zv` to see if a particular IP address is the problem
    - If the other end is expected to be an http(s) server and you are making an HTTP request use the following structure of a curl request:
      ```
      curl -v --connect-to registry-1.docker.io:443:52.54.160.207:443 https://registry-1.docker.io/v2/
      ```
      substitute in the IP address you are trying to test and the host of interest, and see if any particular IP address is a problem there
  - Traceroute
    - You can use `traceroute` to debug latency issues between two hosts, or connection issues between two hosts
    - It will show you the round trip time between each "hop" and the host you initiated the `traceroute` command from
    - The latency numbers are recorded three times for each hop between your host and the destination
    - Keep note of the `***` that you see in `traceroute` output it could mean one of two things:
      - The hop/router just deliberately not respond to `traceroute` probes (ICMP)
      - Packets are actually being dropped
      - Usually the `***` in the middle of `traceroute` output is harmless meaning that that hop could be a subject of the first scenario listed. But if you see those at the end of `traceroute` output that means that packets could actually be getting dropped and not reaching the destination

## 03/06/2026

- TCP
  - Not all TCP stacks are the same between source and origin, so to account for their differences, during the handshake parameters are negotiated
- Network interface
  - When traffic comes in or leaves your computer, it does so through a specific network interface. Depending on the IP address and how your routes are configured (via `ip route show`), you can see which network interface is targeted
  - Network interfaces can be either physical (NIC) or virtual (docker bridge, loopback interface)
  - You can use the command `ip route get {IP_ADDR}` to see which network interface packets will travel through to get to a specific IP address

## 03/10/2026

- Linux Networking
  - Gateway
    - In a home environment the router's IP address will be the IP address of the gateway
  - NIC
    - These define the network interface card that is associated with a network interface
    - `ethtool` is the command to use to get more information about a network interface
      - It can tell you the bandwidth of the network interface
      - It can also tell you if the network interface is duplexed, can send and receive packets
    - NIC Bonding
      - aggregation of multiple NICs into a single interface for redundancy and availability

## 03/11/2026

- Linux Networking (ssh)
  - sshd (daemon) configuration settings for security
    - configure idle timeout interval to avoid having unattended sessions
    - disabling root login (PermitRootLogin)
    - disabling empty passwords
    - limiting users' ssh access (AllowUsers)
  - ss command (prints statistical information about sockets)
  - sockets
    - unix socket
      - a way for programs on the same computer to talk to each other
      - uses a special file for message exchange
- CCNA
  - router is a device that connects a LAN to the internet
  - switches connects devices to the same LAN
  - A WAN is created by using a dedication connection between two or more LAN
  - OSI model
    - Acronym
      - Please do not take sales peoples advice

## 03/13/2026

- Cilium
  - Packets that are addressed to IPs that are in the cilium range will go out through the cilium_host network interface
  - The eBPF program attached to the network interface runs as it receives packets
  - If the destination of the packet is on the same machine it will get redirected via a veth
  - If the destination of the packet is on another machine, the packet will get VXLAN encapsulated, and sent out through the `cilium_vxlan` network interface to a physical NIC
- Network Interfaces
  - If you route packets to a ip address in the same subnet that the network interface shows, then the kernel will route traffic directly to that network interface

## 03/18/2026

- Cilium L2 announcement
  - If you want to send traffic to a VIP `10.0.250.251`, this is what happens:
    - Your host looks at the routing table and will see that the VIP is in the local subnet so it can reach directly at L2, no gateway needed
    - The kernel checks the ARP cache, if the IP -> MAC Address pairing isn't in the cache an ARP broadcast message is sent to all hosts in the subnet
    - Once the IP -> MAC address pairing is figured out, the ethernet frames are then sent to the node on the L2 layer
    - cilium on the node receives the frames and the BPF program sees it is a known VIP and does load balancing
    - packet is then forwarded to the specific pod picked from load balancing
- Networking
  - Switches operates on the L2 layer, while routes operate on the L3 layer. Routers can connect two or more subnets together
  - The ethernet frame is then constructed and sent over the network to the lease-holding node
  - Switches forward frames based on MAC addresses
  - Routers forward packets based on IP addresses
  - IPs that do not match any route go through the default route which is the router

## 03/23/2026

- Node troubleshooting
  - It is pretty useful to use `journalctl` without any specific service filters when inspecting a node level issue (spike in memory/network packets/CPU)
    - You can use `journalctl` like `journalctl --since "9 hours ago"`

## 04/01/2026

- Grafana
  - UI/UX experience around installing predefined dashboards/alerts and trying to tune them is terrible
    - It seems as though you can not edit the metric queries that power the predefined dashes/alerts
    - Seems as though you can not delete/uninstall the predefined dashboards and alerts once you install them
      - edit: it seems as though you can uninstall the integration, but cannot edit which is frustrating
    - For custom alert rules, you can pause evaluations of the alert. For the predefined ones you cannot do that

## 04/02/2026

- Data Center
  - Colocation
    - Entity that provides managed power, cooling, security and bandwidth
    - They rent their space for businesses to house their own servers and networking hardware

## 04/04/2026

- Virtualization
  - Proxmox
    - Open source solution that acts as a Hypervisor for provisioning VMs on a Bare metal node
    - You have to install the .iso file which will act as a bootable partition from a USB
  - Every node which will hosts VMs will need to install Proxmox and run as a Proxmox host
    - Doing this with 100s - 1000s of nodes can be unwieldly
      - To mitigate the above you can have Proxmox be installed at PXE boot

## 04/06/2026

- Data Center Knowledge
  - Data centers try to maximize their PUE
  - Cooling
    - Immersion cooling: servers are submerged in liquid
    - Direct air cooling
      - bring outside air to cool the servers
      - Good for cold climates
    - Location dependent
      - Nordics do very well since climate is favorable
  - How does funding work?
    - In a mature market, you get clients that are committed to using the data center before you can get funding to build it
    - Building speculatively (based on demand)
  - You can outsource expertise of building server rooms, data centers for clients
  - Energy
    - You get energy from the utility company
    - UPS piece of hardware that makes sure the energy is clean
    - Backup generators in case of failures
      - Diesel generators usually
  - Value chain
    - Colo's
      - Companies that buy land in order to allow others to lease space
    - IaaS
      - Usually customers of data centers
      - You can deploy OpenStack, or roll your own solution with Proxmox, etc
      - Depending on the customers needs, they can rent Bare Metal or VMs/Containers
    - What are commodities in this value chain?
      - Data centers
      - Raw VMs
    - Seems like the diversity of ISPs are important for the data center market

## 04/08/2026

- Kubernetes
  - The kube-apiserver depends on etcd, so if etcd is not reachable it will crash
  - The kubelet is in charge of watching the kube-apiserver manifest and restarting the kube-apiserver pod once it detects that it is not running anymore

## 04/13/2026

- Kubernetes Networking Benchmarks
  - If the goal is to measure intra-cluster network performance, the primary benchmark should be pod-to-pod traffic, not pod-to-service traffic
    - pod-to-service measures more than raw network performance because it includes service load balancing behavior and kube-proxy or eBPF service handling
  - Benchmark target selection should be deterministic so repeated runs hit the same peers unless topology changes
  - It is important to emit explicit metadata with the benchmark results
    - useful labels/fields: protocol, path type, parallel streams, duration, source pod IP, destination target
  - It is useful to emit skipped metrics explicitly when a topology requirement can not be satisfied
    - For example, if there is no valid cross-node target the benchmark should say "skipped" instead of silently omitting the metric
  - Benchmark pods should request enough CPU to avoid severe throttling, but if requests are too large the workload may not schedule at all on smaller clusters
  - Benchmarking should be worker-only for fairness
    - If `iperf3` targets land on control plane nodes, the results can be misleading because those nodes also run control plane workloads
  - After restricting the benchmark to worker nodes only, the AWS cluster still outperformed the other cluster on both same-node and cross-node throughput
- Networking
  - Jumbo frames can materially improve throughput and reduce CPU overhead for sustained bulk traffic like `iperf3`
    - This is because larger MTU means fewer packets need to be processed for the same amount of data
    - Fewer packets usually means fewer interrupts, fewer headers, and less per-packet work in the kernel and NIC
    - This often improves sustained TCP throughput because the hosts spend less CPU time processing packet overhead
    - This can also improve effective throughput per CPU core, which matters when the bottleneck is packet processing rather than link speed
  - Jumbo frames do not usually make latency dramatically lower by themselves
    - Their biggest benefit is usually throughput and CPU efficiency
    - They can reduce queueing and software overhead in some environments, but they are not primarily a latency optimization
  - Jumbo frames are most useful for large sequential transfers and east-west data movement
    - For example: `iperf3`, storage replication, database replication, large model/data movement, and backup traffic
  - Jumbo frames are less important for small request/response traffic
    - If the application sends small messages, the packets may never approach the larger MTU anyway
  - If only part of the path supports jumbo frames, they can cause fragmentation or packet drops instead of improving performance
    - So the throughput benefit only appears when the entire path is configured consistently
  - Jumbo frames only help if the full end-to-end path supports them
    - NIC support alone is not enough. The switch, host network, bridge, hypervisor, VM/container network, and peer path must all allow the larger MTU
  - A good way to validate jumbo frame support on two hosts is:

    ```bash
    ping -M do -s 8972 <peer-ip>
    ```

    - If that succeeds repeatedly, the path supports roughly `9000` MTU without fragmentation

  - In AWS EKS, the pod datapath was effectively running at `MTU 9001`
    - The benchmark pod had `eth0 mtu 9001`
    - The AWS VPC CNI had `AWS_VPC_ENI_MTU=9001`
  - Standard DigitalOcean VPC networking does not support jumbo frames, so it is not a clean apples-to-apples comparison against an AWS environment using `9001` MTU

- Cilium
  - Cilium can use jumbo frames if the underlying network supports them, but the active routing mode matters a lot
  - In one bare-metal cluster, the worker data interfaces supported `MTU 9000`, but Cilium was still using a much smaller effective MTU because it was configured for `routing-mode: tunnel` with `vxlan`
    - In that setup `cilium_vxlan`, `cilium_host`, and pod veth interfaces were all `MTU 1280`
  - This means bare-metal jumbo-frame capability does not automatically translate into pod-level jumbo-frame performance
  - If the worker plane supports direct routing of pod CIDRs, native/direct routing is a better fit for high-performance east-west traffic than a VXLAN overlay
  - You should confirm that worker nodes can route each other's pod CIDRs over the underlay before switching to native/direct routing
  - Changing Cilium from VXLAN/tunnel mode to native/direct routing should be treated like a network migration
    - Re-running Kubespray with that kind of change can interrupt workloads because the Cilium agent and datapath will be rolled and reprogrammed
- Hardware / Environment Checks
  - When comparing cluster networking performance, check these first:
    - pod MTU
    - host interface MTU
    - CNI type and routing mode
    - whether the benchmark is hitting only worker nodes
    - node homogeneity (same instance type / same CPU class)
    - allocatable CPU on the workers
    - east-west latency between worker nodes
    - whether the environment supports jumbo frames end to end
  - If two clusters use materially different underlays, a benchmark difference may be infrastructure-driven rather than caused by the CNI alone

## 04/14/2026

- Networking
  - MTU stands for Maximum Transmission Unit
    - It is the largest Layer 3 packet size an interface can send in a single frame without needing fragmentation
    - If two nodes are communicating over interfaces with `MTU 1280`, that means they can exchange IP packets up to `1280` bytes on that path without fragmentation, assuming there is no smaller link in the middle
    - The actual application payload is smaller than the MTU because IP and transport headers consume part of that space
  - TCP MSS is related to MTU, but it is not the same thing
    - MSS is the maximum TCP payload size a side is willing to receive in a single TCP segment
    - MSS is commonly advertised in the TCP `SYN` during the handshake
    - A good rule of thumb is `MSS = MTU - IP header - TCP header`
    - So for `MTU 1280`, the MSS is usually `1240` for IPv4 TCP and `1220` for IPv6 TCP when there are no options
  - Two nodes connected to the same Ethernet switch on the same VLAN/subnet are typically communicating through Layer 2 switching, not Layer 3 routing
    - MTU still matters in that case because the hosts are still sending IP packets encapsulated inside Ethernet frames
    - The effective limit is still determined by the smallest MTU supported across the local path
  - Ethernet frames and IP packets are different layers of encapsulation
    - An Ethernet frame is Layer 2 and is used for local link delivery between devices on the same network segment
    - An IP packet is Layer 3 and is used for end-to-end delivery across networks
    - In a normal Ethernet network, the IP packet sits inside the Ethernet frame along with transport headers and application data
    - Typical encapsulation looks like this:
      ```text
      [ Ethernet header ][ IP header ][ TCP/UDP header ][ application data ][ Ethernet trailer ]
      ```
  - A bridge is a Layer 2 forwarding device or software component that connects network segments and forwards Ethernet frames based on MAC addresses
    - It learns which MAC addresses are reachable on which ports and only forwards frames where needed
    - Its significance is that it joins separate segments into one logical LAN while reducing unnecessary traffic compared with a hub
  - A Layer 2 switch is effectively a modern multi-port bridge
    - Both bridges and switches operate at Layer 2 and forward frames using MAC addresses
    - In practice, "bridge" usually refers to the underlying concept or a software bridge, while "switch" usually refers to the higher-port-count hardware implementation
  - In Proxmox, a Linux bridge such as `vmbr0` acts like a virtual Layer 2 switch for VMs on that host
    - Each VM gets a virtual NIC attached to the bridge
    - If two VMs are on the same bridge on the same Proxmox host, traffic stays on the host and the bridge forwards frames internally between their virtual ports
    - If the bridge is also attached to a physical NIC, that NIC behaves like another port on the same virtual switch
  - Two VMs on different Proxmox hosts communicate through both the local bridges and the physical LAN
    - Example path: `VM on Host A -> Host A bridge -> Host A physical NIC -> physical switch/LAN -> Host B physical NIC -> Host B bridge -> VM on Host B`
    - The bridges on separate hosts are not magically connected to each other; they are only connected because both hosts are attached to the same physical switch or VLAN
  - If the VMs are on the same VLAN and subnet, they can usually talk directly at Layer 2
    - The sender uses ARP to resolve the destination IP to a MAC address
    - Frames are then switched across the path without a router
  - If the VMs are on different VLANs or different IP subnets, they need Layer 3 routing to communicate
    - That routing could be done by a physical router, firewall, or another VM acting as a router

## 04/21/2026

- Cilium L2 announcements
  - L2 announcement leases are created in the namespace where Cilium runs, usually `kube-system`, and have names like `cilium-l2announce-<namespace>-<service>`
  - A missing L2 announcement lease does not always mean L2 announcements are broken. In the `romantic-anemone` cluster, the lease was missing because the `LoadBalancer` service did not have a VIP yet
  - Cilium only creates the L2 lease after LB IPAM writes an IP into `.status.loadBalancer.ingress` for the selected `LoadBalancer` service
  - The useful debug path was:
    ```bash
    kubectl -n kube-system get lease | grep cilium-l2announce
    kubectl get CiliumL2AnnouncementPolicy -o yaml
    kubectl get ippools -o yaml
    kubectl -n aranya get svc clusterping -o yaml
    kubectl -n kube-system exec ds/cilium -- cilium-dbg config --all
    ```
  - The key service condition was `cilium.io/IPAMRequestSatisfied`. When it was `False` with `reason: no_pool`, Cilium explained the exact issue: the service requested `172.16.0.201`, but the live `CiliumLoadBalancerIPPool` did not contain that IP
  - After correcting the `CiliumLoadBalancerIPPool` to include `172.16.0.201`, Cilium set `.status.loadBalancer.ingress` on `aranya/clusterping`, and the lease `cilium-l2announce-aranya-clusterping` appeared
  - The current `CiliumL2AnnouncementPolicy` selects only nodes with `node-role.kubernetes.io/cpu-worker`, so the elected announcer for the VIP is a CPU worker. That explains why the VIP was reachable from CPU workers, while control-plane node behavior can differ depending on routing/interface/device path
  - `curl http://172.16.0.201` working from a node confirms node-to-VIP reachability. The stronger L2 announcement validation is curling the VIP from a non-cluster host on the same L2 network

## 04/22/2026

- Public IPs, NAT, and Kubernetes VIPs
  - When exposing Kubernetes `LoadBalancer` services from a private bare-metal network, it is important to separate three concepts:
    - the public IP that internet clients connect to
    - the private VIP assigned to the Kubernetes service
    - the node currently advertising or owning that VIP on the local network
  - A common clean design is 1:1 NAT from a public IP to a single private VIP
    - Example: `199.104.31.120 -> 172.16.0.201`
    - Example: `199.104.31.121 -> 172.16.0.202`
  - In that model, each public IP maps to exactly one private IP
    - It is not "one public IP to a range of VIPs"
    - It is also not "multiple public IPs to one VIP" unless there is a very specific upstream load-balancing reason to do that
  - Cilium can provide the private VIP for a Kubernetes `LoadBalancer` service and announce it on the local Layer 2 network
    - The implementation is not necessarily classic VRRP, but the operational idea is similar: one node claims the VIP, and another node can claim it if the first node fails
    - Cilium uses L2 announcement behavior such as gratuitous ARP so the local network learns which node currently owns the VIP
  - The traffic path for internet-facing ingress usually looks like:
    ```text
    internet client
      -> public IP
      -> gateway/firewall NAT
      -> private Kubernetes VIP
      -> node currently advertising the VIP
      -> ingress controller
      -> Kubernetes service/pod
    ```
  - Port-based DNAT is a different design than 1:1 NAT
    - Port-based DNAT means the same public IP can send different ports to different private destinations
    - Example: `public-ip:6443` could forward to Kubernetes API load balancers, while `public-ip:80` and `public-ip:443` could forward to an ingress VIP
    - This is useful when public IPs are scarce, but it couples multiple services to the same public address
  - If enough public IPs are available, dedicating separate public IPs to separate roles is simpler to reason about
    - Existing public IPs can stay dedicated to Kubernetes API server access
    - New public IPs can be mapped 1:1 to ingress VIPs
  - Before asking the network team for NAT, be precise about the requested mapping
    - Say "one public IP to one private VIP" for 1:1 NAT
    - Say "same public IP, split by port" for port-based DNAT
    - Say which private VIPs are expected to be claimed by Cilium or another L2 failover mechanism
- Talos on Proxmox
  - A Proxmox VM for Talos should use enough resources for the intended role
    - For a lab, `2+` cores and `2 GB` RAM can work, but `4 GB` RAM is more comfortable for a control plane node
    - `cpu: host` is a good choice because Talos requires x86-64-v2 CPU features, but it reduces live-migration portability
    - `virtio` networking on a Linux bridge such as `vmbr0` is the expected network shape
    - `virtio-scsi-single` with a normal virtual disk is a good disk setup
  - Talos VM IPs can be found in a few places
    - The Proxmox VM console usually prints the DHCP address when Talos boots into maintenance mode
    - The Proxmox Summary tab may show the IP if the QEMU guest agent is installed and enabled
    - The VM Hardware tab exposes the NIC MAC address, which can be matched against the DHCP lease table on the router
  - The Talos ISO version and `talosctl` version should match
    - A newer `talosctl` can generate machine config keys that an older Talos installer does not understand
    - The `grubUseUKICmdline` field is an example of this kind of mismatch because it was introduced after the older v1.9-era config schema
    - When this happens, either use a matching Talos ISO or regenerate configs with a matching `talosctl`
  - Before applying config, verify the install disk path from maintenance mode
    ```bash
    talosctl get disks --insecure --nodes <node-ip>
    ```
    - The generated config may default to `/dev/sda`, but the VM disk name should be confirmed before installation
  - Bootstrap must be run against a control plane node
    - If `talosctl bootstrap` says bootstrap can only be performed on a control plane node, `talosctl` is probably targeting a worker IP or a VM that received `worker.yaml`
    - Set both the endpoint and node to the control plane IP before bootstrapping
    ```bash
    export TALOSCONFIG="_out/talosconfig"
    talosctl config endpoint <control-plane-ip>
    talosctl config node <control-plane-ip>
    talosctl bootstrap
    ```
  - It can be normal for `kubectl get nodes` to be empty for a short period right after bootstrap
    - If namespaces exist, the Kubernetes API server is responding
    - If nodes stay empty, check Talos health, services, and kubelet logs on the control plane node
    ```bash
    talosctl --talosconfig _out/talosconfig health --endpoints <control-plane-ip> --nodes <control-plane-ip>
    talosctl --talosconfig _out/talosconfig services --endpoints <control-plane-ip> --nodes <control-plane-ip>
    talosctl --talosconfig _out/talosconfig logs kubelet --endpoints <control-plane-ip> --nodes <control-plane-ip>
    ```
  - Cilium can be installed as the CNI on Talos with kube-proxy replacement and Kubernetes IPAM
    - For Talos, Cilium needs the cgroup settings to point at the host cgroup mount
    - Cilium also needs explicit Linux capabilities for the agent and cleanup job when running on Talos
    - The `k8sServiceHost` should be the control plane API server IP and `k8sServicePort` should be `6443`
    - L2 announcements and external IP support can be enabled at install time when the cluster will use Cilium for local network service advertisement
    ```bash
    helm install \
      cilium \
      oci://quay.io/cilium/charts/cilium \
      --version 1.19.3 \
      --namespace kube-system \
      --set l2announcements.enabled=true \
      --set ipam.mode=kubernetes \
      --set kubeProxyReplacement=true \
      --set securityContext.capabilities.ciliumAgent="{CHOWN,KILL,NET_ADMIN,NET_RAW,IPC_LOCK,SYS_ADMIN,SYS_RESOURCE,DAC_OVERRIDE,FOWNER,SETGID,SETUID}" \
      --set securityContext.capabilities.cleanCiliumState="{NET_ADMIN,SYS_ADMIN,SYS_RESOURCE}" \
      --set cgroup.autoMount.enabled=false \
      --set cgroup.hostRoot=/sys/fs/cgroup \
      --set k8sServiceHost=<control-plane-ip> \
      --set k8sServicePort=6443 \
      --set prometheus.enabled=true \
      --set prometheus.metricsService=true \
      --set externalIPs.enabled=true
    ```

## 04/23/2026

- Linux hardware inspection
  - `lspci` shows PCI and PCIe devices that the kernel can enumerate on the PCI bus. Use it to answer "what hardware is present?" for devices like GPUs, NICs, and storage controllers
  - `lsmod` shows kernel modules currently loaded in memory. Use it to answer "what drivers or kernel features are active right now?"
  - `lspci` and `lsmod` are related but different
    - A device can appear in `lspci` even if its driver is not loaded
    - A module can appear in `lsmod` even if it is not tied to one visible PCI device
  - `lspci -nnk` is usually the most useful PCI command because it shows numeric device IDs and the kernel driver or modules associated with each device
  - Other useful commands for understanding hardware on Linux
    - `lsusb` for USB devices
    - `lscpu` for CPU topology, threads, NUMA, and virtualization flags
    - `lsblk` for disks, partitions, and mount points
    - `blkid` for filesystem UUIDs and filesystem types
    - `free -h` and `/proc/meminfo` for RAM and swap
    - `dmidecode` for BIOS, motherboard, and memory slot details
    - `dmesg` for kernel detection messages, driver binding, and hardware errors
    - `/sys` and `/proc` for low-level kernel-exposed device state
  - A simple workflow for hardware debugging
    - Start with `lspci -nnk` or `lsusb` to identify the device
    - Use `lsmod` to confirm whether the expected driver module is loaded
    - Use `dmesg` to check whether the kernel detected the device cleanly or logged errors
    - Use subsystem-specific tools like `lsblk`, `lscpu`, or `udevadm info` for deeper inspection
- Linux networking
  - A machine with two NICs can be connected to two different subnets because each NIC is typically exposed as a separate network interface in Linux
  - Each interface can have its own IP address, subnet, and routing behavior
  - Two NICs do not automatically mean two subnets
    - Both NICs could be connected to the same subnet for redundancy, bonding, or specialized routing setups
  - One physical NIC can also carry multiple logical networks through VLAN interfaces
  - The routing table determines which interface traffic uses for a given destination
  - A host connected to two subnets is not automatically a router between them
    - It would need IP forwarding and routing or firewall rules configured to actually pass traffic between those networks

## 04/24/2026

- DNS resolution in Kubernetes pods
  - `/etc/resolv.conf` is the stub resolver config file read by libc (`getaddrinfo`) for name resolution
    - It specifies the `nameserver` IPs to query, a `search` list of domain suffixes, and `options` like `ndots:N`
    - Apps like `curl` and `ping` do not talk to DNS servers directly. They call into libc, which reads this file and sends the UDP/53 query
  - `dnsPolicy` is a top-level field on the `PodSpec` (not per-container)
    - For workload controllers like Deployments or StatefulSets, it goes in `spec.template.spec`, not the top-level controller spec
    - Valid values: `ClusterFirst`, `ClusterFirstWithHostNet`, `Default`, `None`
    - Default is `ClusterFirst` if omitted
    - `dnsPolicy` is NOT automatically upgraded to `ClusterFirstWithHostNet` when `hostNetwork: true` is set. Common gotcha — host-network pods silently use the node's resolver unless explicitly set
  - `dnsPolicy: ClusterFirst` behavior
    - Sets the pod's `/etc/resolv.conf` to point at the kube-dns Service ClusterIP (e.g. `10.96.0.10`)
    - Adds cluster search domains (`<ns>.svc.cluster.local`, `svc.cluster.local`, `cluster.local`) and `ndots:5`
    - All pod-side DNS logic is trivial. The actual routing of queries happens inside CoreDNS
  - Full DNS query flow for `google.com` from a pod with `ClusterFirst`
    - App calls `getaddrinfo("google.com")`
    - libc reads `/etc/resolv.conf` and sends UDP query to the CoreDNS Service IP
    - kube-proxy / CNI routes the query to an actual CoreDNS pod
    - CoreDNS runs the query through its Corefile plugin chain
      - `kubernetes cluster.local` plugin sees no match and passes
      - Falls through to `forward . <upstream>` which forwards to upstream resolvers
    - Upstream answers and CoreDNS caches and relays back to the pod
    - The pod never talks to the upstream directly. CoreDNS acts as a recursive forwarder
  - The "upstream" is determined by CoreDNS's Corefile
    - Default `forward . /etc/resolv.conf` inherits the CoreDNS pod's resolv.conf, which typically inherits from the node
    - Admins can override with explicit upstream IPs (`forward . 1.1.1.1 8.8.8.8`)
    - Admins can add stub domains for per-zone routing (e.g., `corp.internal:53 { forward . 10.0.0.53 }`)
  - Not all pod DNS queries go through CoreDNS
    - `dnsPolicy: Default` uses the node's resolv.conf directly, bypassing CoreDNS entirely
    - `hostNetwork: true` without `ClusterFirstWithHostNet` uses the node's resolver
    - `dnsPolicy: None` with custom `dnsConfig` can point anywhere
    - Apps that bypass libc (Go's `net.Resolver` with custom dial, c-ares, DoH/DoT libs) can query any server directly. Only NetworkPolicy blocking egress to non-cluster port 53 prevents this
    - `/etc/hosts` entries (including `spec.hostAliases`) resolve before DNS via nsswitch
  - Node hostname resolution from pods
    - Kubernetes DNS does NOT create records for node hostnames by default. `nslookup <node-hostname>` typically returns NXDOMAIN
    - It works when the node's hostname is registered in upstream DNS and CoreDNS forwards there
    - In homelab setups, this often works because the router registers DHCP hostnames in its local DNS, and CoreDNS forwards upstream to the router
    - The portable way to get a node's IP from a pod is the downward API with `fieldRef: status.hostIP`. Relying on node hostname DNS is environment-dependent
  - To inspect a cluster's CoreDNS behavior
    ```bash
    kubectl -n kube-system get configmap coredns -o yaml
    ```
    That ConfigMap is ground truth for how non-cluster queries are handled
- Seeing which DNS server a tool is using
  - `curl` does NOT expose the DNS server used, even with `-v` or `--trace`. It only shows the resolved IP
  - To see the server, use `dig` or `nslookup` — the `;; SERVER:` line identifies who answered
  - `cat /etc/resolv.conf` tells you what the resolver would use (unless the app bypasses libc)
  - `tcpdump -n -i any port 53` shows actual DNS traffic on the wire. Needs `NET_ADMIN`/`NET_RAW` in a pod
  - `strace -e trace=network -f curl ...` shows the `connect()` to the DNS server before the HTTPS connection
  - `curl --dns-servers 1.1.1.1` can pin DNS for debugging, but only if curl is built with c-ares (check `curl --version`)
  - `curl --resolve host:port:IP` bypasses DNS entirely. Useful diff test — if it works but plain curl does not, DNS is the problem
  - Practical debugging combo in a pod:
    ```bash
    cat /etc/resolv.conf     # who the pod thinks it should ask
    dig example.com          # confirm who actually answered
    curl -v https://example.com
    ```
