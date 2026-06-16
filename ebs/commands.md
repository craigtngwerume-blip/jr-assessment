# Task C — EBS Attach, Mount & Online Expand

## Step 1 — After Terraform apply, SSH into the instance
```bash
ssh -i ~/.ssh/id_rsa ec2-user@<public_ip>
```

## Step 2 — Verify volume is attached
```bash
lsblk
# Expected output shows xvdf as 4G unpartitioned disk
```

## Step 3 — Format as XFS
```bash
sudo mkfs.xfs /dev/xvdf
```

## Step 4 — Create mount point and mount
```bash
sudo mkdir -p /data
sudo mount /dev/xvdf /data
```

## Step 5 — Get UUID and add to /etc/fstab
```bash
UUID=$(sudo blkid -s UUID -o value /dev/xvdf)
echo "UUID=${UUID}  /data  xfs  defaults,nofail  0  2" | sudo tee -a /etc/fstab
```

## Step 6 — Verify mount
```bash
df -h /data
lsblk
sudo blkid | grep xvdf
```

## Step 7 — Reboot test
```bash
sudo reboot
# After reboot:
df -h /data   # should still show /data mounted
```

---

## Step 8 — Grow volume online to 8 GiB (via AWS CLI or Console)

### Via AWS CLI (from your local machine)
```bash
# Get the volume ID from Terraform output
VOLUME_ID=$(terraform -chdir=iac output -raw ebs_volume_id)

aws ec2 modify-volume \
  --volume-id $VOLUME_ID \
  --size 8 \
  --region af-south-1

# Wait for modification to complete
aws ec2 describe-volumes-modifications \
  --volume-ids $VOLUME_ID \
  --region af-south-1
```

## Step 9 — Expand filesystem online (no unmount needed for XFS)
```bash
# SSH back in
sudo xfs_growfs /data

# Verify
df -h /data
lsblk
```

### Expected before/after:
| | lsblk | df -h |
|---|---|---|
| Before grow | xvdf 4G | /data 4.0G |
| After grow  | xvdf 8G | /data 8.0G |

---

## Why UUID in fstab (not device name)?
Device names like `/dev/xvdf` can change across reboots or instance types.
UUID is stable and guaranteed to identify the correct volume — safer and more resilient.

The `nofail` option ensures the instance boots even if the volume is temporarily unavailable.
