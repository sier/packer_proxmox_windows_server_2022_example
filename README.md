# packer_proxmox_windows_server_2022_example
An example for setting up Windows VMs using Packer for Proxmox

## Pre-requisites
- *[Packer](https://www.packer.io/downloads) (I recommend using [Chocolatey](https://chocolatey.org/install))
- *[VirtIO Drivers ISO](https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/archive-virtio/)
- [Proxmox](https://www.proxmox.com/en/downloads)
- [Windows Server 2022 ISO](https://www.microsoft.com/en-us/evalcenter/evaluate-windows-server-2022)
- imgburn (or similar) to create the autounattend ISO

\* = Required


## Commands & Installation
Run the following commands to build your Windows Server 2022 Proxmox template:

Initialize Packer:
```powershell
packer init -var-file "variables.pkrvars.hcl" ./windows-2022.pkr.hcl
```

Validate the Packer template configuration:
```powershell
packer validate -var-file "variables.pkrvars.hcl" ./windows-2022.pkr.hcl
```

Build the Packer template:
```powershell
packer build -var-file "variables.pkrvars.hcl" ./windows-2022.pkr.hcl
```

Tip: You can also use just a single .  if you want to automate without knowing the name of the packer configuration.
```powershell
packer build -var-file "variables.pkrvars.hcl" .
```

## Debugging & Troubleshooting
You can set the debug flag in powershell using:
```powershell
$Env:PACKER_LOG="1"
```

You will then see debug log messages in the terminal and get a text copy in the same directory as where you ran packer.
