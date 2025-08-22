# AWS Cost Estimation - Unity WebRTC Streaming

## Overview

Cost breakdown for single-instance Unity WebRTC streaming sessions lasting 2-6 hours continuously.

## Instance Pricing

### GPU Instance Options (US East 1)

| Instance Type | Specifications | Hourly Cost | 
|--------------|----------------|-------------|
| g4dn.xlarge | 1 GPU, 4 vCPU, 16GB RAM | £0.41 |
| g4dn.2xlarge | 1 GPU, 8 vCPU, 32GB RAM | £0.59 |
| g4dn.4xlarge | 1 GPU, 16 vCPU, 64GB RAM | £0.95 |

## Session Cost Breakdown

### Single Streaming Session (2-6 hours)

#### Infrastructure Costs
**2-Hour Session:**
- Instance (g4dn.xlarge): £0.82
- Data transfer (20GB @ £0.07/GB): £1.40
- Total: **£2.22**

**6-Hour Session:**
- Instance (g4dn.xlarge): £2.46
- Data transfer (60GB @ £0.07/GB): £4.20
- Total: **£6.66**

#### Production Configuration (g4dn.2xlarge)
**2-Hour Session:**
- Instance: £1.18
- Data transfer: £1.40
- Total: **£2.58**

**6-Hour Session:**
- Instance: £3.54
- Data transfer: £4.20
- Total: **£7.74**

## Data Transfer Calculations

### Streaming Bandwidth
- Resolution: 1920x1080 @ 60fps
- Bitrate: 10 Mbps
- Data per hour: 4.5GB
- AWS egress cost: £0.07/GB (after 100GB free tier)

### Session Data Usage
| Duration | Data Transfer | Cost |
|----------|--------------|------|
| 2 hours | 9GB | £0.63 |
| 4 hours | 18GB | £1.26 |
| 6 hours | 27GB | £1.89 |

## Monthly Usage Scenarios

### Occasional Use (20 hours/month)
- Instance costs: £11.80
- Data transfer (90GB): £6.30
- Storage (100GB EBS): £6.30
- **Total: £24.40/month**

### Regular Use (60 hours/month)
- Instance costs: £35.40
- Data transfer (270GB): £18.90
- Storage (100GB EBS): £6.30
- **Total: £60.60/month**

### Intensive Use (120 hours/month)
- Instance costs: £70.80
- Data transfer (540GB): £37.80
- Storage (100GB EBS): £6.30
- **Total: £114.90/month**

## Additional Costs

### Storage
- EBS GP3 SSD: £0.063/GB per month
- Minimum 100GB recommended: £6.30/month

### Fixed Monthly Services
- Route 53 DNS: £0.40/month
- CloudWatch monitoring: £2.35/month

## Quick Reference

### Cost Per Session
| Instance | 2 Hours | 4 Hours | 6 Hours |
|----------|---------|---------|---------|
| g4dn.xlarge | £2.22 | £4.44 | £6.66 |
| g4dn.2xlarge | £2.58 | £5.16 | £7.74 |

## Notes
- Prices in GBP (converted at £1 = $1.27)
- First 100GB egress free per month
- Costs exclude VAT
- Based on AWS pricing January 2025