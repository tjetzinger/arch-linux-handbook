# 10 - External GPU (eGPU)

Configuration for Razer Core X enclosure with NVIDIA RTX 3060 via Thunderbolt 4 for compute workloads (Ollama/LLM).

## Hardware

| Component | Specification |
|-----------|---------------|
| Enclosure | Razer Core X |
| GPU | NVIDIA GeForce RTX 3060 (12GB VRAM) |
| Connection | Thunderbolt 4 (USB-C) |
| Driver | nvidia-open 590.48.01 |
| CUDA | 13.1 |
| Mode | Compute-only (no display) |

## Installed Packages

```bash
# Core packages
bolt                      # Thunderbolt device manager
nvidia-open               # Open-source NVIDIA kernel modules
nvidia-utils              # NVIDIA driver utilities
nvidia-settings           # GUI configuration tool
nvidia-container-toolkit  # Docker GPU support
```

## Kernel Configuration

### Boot Parameters

**File:** `/boot/loader/entries/arch.conf`

```bash
options ... nvidia_drm.modeset=0 rw
```

**Note:** `modeset=0` for compute-only usage (no display attached to eGPU). Use `modeset=1` if connecting a monitor to the eGPU.

### Initramfs Modules

**File:** `/etc/mkinitcpio.conf` (mainline kernel)

```bash
MODULES=(usb_storage uas ext4 i915 btrfs aesni_intel nvidia nvidia_uvm)
```

**File:** `/etc/mkinitcpio-lts.conf` (LTS kernel - no NVIDIA)

```bash
MODULES=(usb_storage uas ext4 i915 btrfs aesni_intel)
```

**File:** `/etc/mkinitcpio.d/linux-lts.preset`

```ini
ALL_config="/etc/mkinitcpio-lts.conf"
```

**Important:** NVIDIA modules only available for mainline kernel. Boot with `arch.conf` (not `arch-lts.conf`) when using eGPU.

## Thunderbolt Management

### bolt Service

```bash
# Status (D-Bus activated, no enable needed)
systemctl status bolt.service

# List devices
boltctl list

# Authorize device (temporary)
boltctl authorize <uuid>

# Enroll device (persistent across reboots)
boltctl enroll <uuid>

# Forget device
boltctl forget <uuid>
```

### Enrolled Device

```
Razer Core X
├─ uuid: <TPM-UUID>
├─ generation: Thunderbolt 3
├─ policy: iommu
└─ speed: 40 Gb/s (2 lanes × 20 Gb/s)
```

## Connection Method

### Cold Boot (Required)

1. Power off laptop completely
2. Connect Razer Core X via Thunderbolt cable
3. Power on laptop
4. Boot into mainline kernel (arch.conf)

**Note:** Hot-plug is not reliable with nvidia-open driver. Always cold boot with eGPU connected.

### Verification

```bash
# Check Thunderbolt connection
boltctl list
# Should show: status: authorized

# Check GPU on PCI bus
lspci | grep -i nvidia
# 22:00.0 VGA compatible controller: NVIDIA Corporation GA106 [GeForce RTX 3060]

# Check driver
nvidia-smi
```

## Docker GPU Configuration

### nvidia-container-toolkit Setup

```bash
# Install
sudo pacman -S nvidia-container-toolkit

# Configure Docker runtime
sudo nvidia-ctk runtime configure --runtime=docker

# Restart Docker
sudo systemctl restart docker

# Verify runtime
docker info | grep -i runtime
# Should show: nvidia runtime available
```

### Docker Daemon Configuration

**File:** `/etc/docker/daemon.json`

```json
{
    "runtimes": {
        "nvidia": {
            "args": [],
            "path": "nvidia-container-runtime"
        }
    }
}
```

### Docker Compose GPU Configuration

**File:** `docker-compose.yml`

```yaml
services:
  ollama:
    image: ollama/ollama:latest
    container_name: ollama
    shm_size: '1gb'
    volumes:
      - ./ollama:/root/.ollama
    environment:
      - OLLAMA_FLASH_ATTENTION=true
      - OLLAMA_KV_CACHE_TYPE=q8_0
      - OLLAMA_NUM_PARALLEL=1
      - OLLAMA_KEEP_ALIVE=10m
    deploy:
      resources:
        reservations:
          devices:
            - driver: nvidia
              count: all
              capabilities: [gpu]
```

### Verify GPU in Container

```bash
# Check nvidia-smi inside container
docker exec ollama nvidia-smi

# Check Ollama GPU detection
docker logs ollama 2>&1 | grep -i "inference compute"
# Should show: NVIDIA GeForce RTX 3060, CUDA, 12.0 GiB
```

## Ollama Configuration

**Location:** `~/Workspace/containers/open-webui-stack/`

| Service | Purpose |
|---------|---------|
| ollama | LLM inference with GPU |
| open-webui | Web interface |
| litellm | API proxy |
| postgres | Database |

### Test GPU Inference

```bash
# Run a model
docker exec -it ollama ollama run llama3.2

# Check GPU usage during inference
nvidia-smi
# Should show ollama process using GPU memory
```

## Verification Commands

```bash
# System checks
lspci | grep -i thunderbolt      # Thunderbolt controller
boltctl list                      # eGPU connection status
lspci | grep -i nvidia            # GPU on PCI bus
nvidia-smi                        # Driver and GPU status
lsmod | grep nvidia               # Loaded modules

# Docker checks
docker info | grep -i runtime     # nvidia runtime
docker exec ollama nvidia-smi     # GPU inside container

# GPU info
cat /proc/driver/nvidia/gpus/*/information
```

## Performance Optimization

### Ollama Environment Variables

| Variable | Value | Purpose |
|----------|-------|---------|
| `OLLAMA_FLASH_ATTENTION` | true | Faster attention computation |
| `OLLAMA_KV_CACHE_TYPE` | q8_0 | Quantized KV cache (uses less VRAM than f16) |
| `OLLAMA_NUM_PARALLEL` | 1 | Concurrent request limit |
| `OLLAMA_KEEP_ALIVE` | 10m | Model unload timeout |

### Model Sizing for 12GB VRAM

| Model Size | Quantization | GPU Layers | Performance |
|------------|--------------|------------|-------------|
| 7B | Q4_K_M | Full (all layers) | Excellent |
| 13B | Q4_K_M | Full (all layers) | Very good |
| 33B | Q4_K_M | Partial (~55%) | CPU/GPU split, slower |
| 70B | Q4_K_M | Minimal (~20%) | Mostly CPU, slow |

**Recommendation:** Use models ≤13B for full GPU acceleration. Larger models require CPU offload due to Thunderbolt bandwidth limitations.

### Thunderbolt Bandwidth Limitation

- TB4 provides ~32 Gbps PCIe bandwidth (PCIe 3.0 x4 equivalent)
- Internal GPU would be PCIe 4.0 x16 (~256 Gbps)
- Impact: CPU↔GPU layer splits are slower due to bandwidth bottleneck

## Systemd Services

### NVIDIA Persistence Daemon

The `nvidia-persistenced` daemon keeps the NVIDIA driver loaded and GPU initialized, improving startup time for containers and compute workloads.

**Service:** `/usr/lib/systemd/system/nvidia-persistenced.service` (provided by `nvidia-utils`)

```bash
# Enable and start
sudo systemctl enable --now nvidia-persistenced.service

# Verify daemon is running
systemctl status nvidia-persistenced

# Verify persistence mode
nvidia-smi --query-gpu=persistence_mode --format=csv,noheader
# Should show: Enabled
```

**Note:** The upstream service runs the proper `nvidia-persistenced` daemon. Do not use custom overrides with `nvidia-smi -pm 1` as this method is deprecated.

### NVIDIA Suspend/Resume (Auto-configured)

```bash
nvidia-suspend.service
nvidia-resume.service
nvidia-hibernate.service
```

## Known Issues

| Issue | Cause | Solution |
|-------|-------|----------|
| Hot-plug fails | nvidia-open limitation | Always cold boot |
| "No devices found" | Wrong kernel | Boot mainline (arch.conf) |
| DRM errors in dmesg | No display connected | Use `nvidia_drm.modeset=0` |
| Container can't see GPU | Missing toolkit | Install nvidia-container-toolkit |
| CUDA init fails in container | Boot race condition | `docker compose restart ollama` |

## Troubleshooting

### GPU Not Detected After Boot

```bash
# Check kernel
uname -r
# Must be mainline (6.x.x-arch), not LTS

# Check Thunderbolt
boltctl list
# Should show "authorized"

# If not authorized
boltctl authorize <TPM-UUID>
```

### nvidia-smi Fails

```bash
# Check modules loaded
lsmod | grep nvidia

# If empty, load manually
sudo modprobe nvidia
sudo modprobe nvidia_uvm

# Check dmesg for errors
sudo dmesg | grep -i nvidia
```

### Docker Container Can't Access GPU

```bash
# Verify runtime configured
cat /etc/docker/daemon.json

# Restart Docker
sudo systemctl restart docker

# Recreate container
docker compose up -d --force-recreate ollama
```

### Container Shows GPU but CUDA Fails

**Symptoms:**
- `ollama ps` shows "100% GPU" but uses Intel iGPU instead of eGPU
- Container logs show: `ggml_cuda_init: failed to initialize CUDA: no CUDA-capable device is detected`
- `docker exec ollama nvidia-smi` fails with: `Failed to initialize NVML: Unknown Error`

**Cause:** Container started before GPU was fully available (race condition during boot).

**Solution:**
```bash
# Restart the container to rebind to GPU
cd ~/Workspace/containers/open-webui-stack
docker compose restart ollama

# Verify GPU access inside container
docker exec ollama nvidia-smi

# Check logs for successful CUDA detection
docker logs ollama 2>&1 | grep "inference compute"
# Should show: NVIDIA GeForce RTX 3060, CUDA, 12.0 GiB
```

## Quick Reference

```bash
# Cold boot checklist
1. Power off laptop
2. Connect Razer Core X
3. Power on, boot arch.conf (mainline kernel)

# Verify system
boltctl list                      # TB connection
nvidia-smi                        # GPU status
systemctl status nvidia-persistenced  # Persistence daemon

# Verify container GPU
docker exec ollama nvidia-smi     # Should show RTX 3060
docker logs ollama 2>&1 | grep "inference compute"

# If container CUDA fails, restart it
docker compose -f ~/Workspace/containers/open-webui-stack/docker-compose.yml restart ollama

# Ollama
docker exec -it ollama ollama run llama3.2
docker logs ollama | tail -20

# Monitor GPU during inference
watch -n 1 nvidia-smi
```

## Related

- [04-DISPLAY-GRAPHICS](./04-DISPLAY-GRAPHICS.md) - Intel iGPU configuration
- [08-PERIPHERALS](./08-PERIPHERALS.md) - External devices
- [../docker/](../docker/) - Docker and Traefik configuration
