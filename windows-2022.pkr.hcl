packer {
    required_plugins {
        proxmox = {
            version = ">= 1.1.5"
            source  = "github.com/hashicorp/proxmox"
        }
    }
}

variable "iso_file" {
  type    = string
  default = "https://software-download.microsoft.com/download/sg/20348.169.210806-2348.fe_release_svc_refresh_SERVER_EVAL_x64FRE_en-us.iso"
}

# If you want to use a local ISO file, comment out the above variable and uncomment the below variable
#variable "iso_file" {
#    type    = string
#    default = "disks:iso/Windows_Server_2022.iso"
#}

variable "iso_checksum" {
    type    = string
    default = "4f1457c4fe14ce48c9b2324924f33ca4f0470475e6da851b39ccbf98f44e7852"
}

# You can find the latest version of the virtio drivers here: https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/archive-virtio/?C=M;O=D
variable "virtio_iso_path" {
    type    = string
    default = "disks:iso/virtio-win-0.1.229.iso"
}

variable "proxmox_api_user" {
    type = string
}

variable "proxmox_api_token" {
    type      = string
    sensitive = true
}

variable "proxmox_host" {
    type = string
}

variable "proxmox_node" {
    type = string
}

variable "vm_interface" {
    type    = string
    default = "Ethernet"
}

variable "vm_name" {
    type    = string
    default = "packer-windows"
}

# The VLAN that you use for your VMs. If you don't use VLANs, set this to 0
variable "network_vlan" {
    type    = string
    default = "4094"
}

# The number of vCPUs you want the VM to have.
variable "cores" {
    type    = string
    default = "2"
}

# The disk format you want to use. Valid options are: raw, qcow2, vmdk
variable "disk_format" {
    type    = string
    default = "qcow2"
}

# The size of the disk you want to create.
variable "disk_size" {
    type    = string
    default = "120G"
}

# The storage pool you want to use for the disk. This is the name of the storage pool in Proxmox.
variable "disk_storage_pool" {
    type    = string
    default = "disks"
}

# The amount of RAM you want to give the VM.
variable "memory" {
    type    = string
    default = "4096"
}

# The  machine type you want to use. I recommend keeping this at q35.
variable "machine_type" {
    type    = string
    default = "q35"
}

source "proxmox-iso" "windows" {
    proxmox_url              = "https://${var.proxmox_host}/api2/json"
    insecure_skip_tls_verify = true
    username                 = var.proxmox_api_user
    token                    = var.proxmox_api_token

    template_description = "Built from ${basename(var.iso_file)} on ${formatdate("YYYY-MM-DD hh:mm:ss ZZZ", timestamp())}"
    node                 = var.proxmox_node
    pool                 = "packer"

    network_adapters {
        # vmbr0 is the default first bridge created. If you have multiple bridges or use another type of network, change this to the correct bridge.
        bridge   = "vmbr0"
        firewall = false
        # You can change the below to "virtio" if you want to use the virtio drivers. I've found that the e1000 drivers work just fine unless you have a very large network.
        model    = "e1000"
        vlan_tag = var.network_vlan
    }
    # Note that I am using the scsi controller. If you want to use IDE I would highly recommend against it as the performance difference is day and night.
    disks {
        disk_size    = var.disk_size
        format       = var.disk_format
        io_thread    = true
        storage_pool = var.disk_storage_pool
        type         = "scsi"
    }
    scsi_controller = "virtio-scsi-single"

    # UEFI STUFF - DO NOT USE! UEFI is... iffy at best with Proxmox. I've found that it's best to just use seabios. As long as you don't require disk encryption you should be fine.
    #bios            = "ovmf"
    #efi_config {
    #    efi_storage_pool = "disks"
    #    pre_enrolled_keys = true
    #    efi_type = "4m"
    #}

    iso_file        = var.iso_file

    vm_interface    = var.vm_interface
    boot_wait       = "0s"
    # Yes, this is silly. Yes, it works. No further comments.
    boot_command = ["<enter><enter><enter><enter><enter><enter><enter><enter><wait1><enter><enter><enter><enter><enter><enter><enter><enter><enter><enter><enter><enter><wait1><enter><enter><enter><enter><enter><enter><enter><enter><enter><enter>"]
    vm_name         = var.vm_name

    # I have found that simply creating your own unattend ISO using for example ImgBurn is the easiest way to deal with the autounattend stuff. Dealing with the floppy and getting it to mount correctly is more hassle than it's worth.
    additional_iso_files {
        unmount = true
        device = "sata0"
        iso_storage_pool = "disks"
        iso_file = "disks:iso/autounattend.iso"
        #cd_files = ["scripts/autounattend.xml", "scripts/configure.ps1", "scripts/cleanup.ps1"]
    }

    # The virtio drivers are required for the network adapter to work. You can find the latest version of the virtio drivers here: https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/archive-virtio/?C=M;O=D
    additional_iso_files {
        unmount = true
        device = "sata1"
        iso_storage_pool = "disks"
        iso_file = "disks:iso/virtio-win-0.1.229.iso"
    }

    cpu_type        = "host"
    os              = "win11"
    memory          = var.memory
    cores           = var.cores
    sockets         = 1
    machine         = var.machine_type
    qemu_agent      = true

    communicator    = "winrm"
    winrm_use_ssl   = true
    winrm_insecure  = true
    winrm_username  = "Administrator" # This is set in the autounattend xml file. If you change it there, change it here as well.
    winrm_password  = "packer" # This is set in the autounattend xml file. If you change it there, change it here as well. Or better yet, use a secret variable and reset the account password after the build is done via for example powershell.

}

# I highly recommend using some type of provisioner as packer does not like it when you don't have any provisioners.
# If you are having issues, it is very likely IPv6 related. Or you rebooted the machine and WinRM is not ready yet. Or WinRM is just having a bad day. It is very moody like that.
build {
    sources = [
        "source.proxmox-iso.windows"
    ]

    provisioner "powershell" {
        inline = ["dir c:/"]
    }
}