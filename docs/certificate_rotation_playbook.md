# Certificate Rotation Playbook
# For Re-Word Game

## Overview
This document describes the complete process for rotating SSL certificates with certificate pinning, ensuring zero downtime for users.

## Monitoring & Alerts
- **30 days before expiry:** First warning email (planning phase)
- **15 days before expiry:** Urgent warning email (action required)
- **7 days before expiry:** Critical alert (daily notifications)

Automated monitoring runs daily via: `/home/gameadmin/reword-utilities/cert-maintenance/manage-cert-rotation.sh`

---

## Rotation Process

### Phase 1: Preparation (90 days before expiry)

**Goal:** Purchase new certificate and prepare app update

**Steps:**
1. **Purchase/generate new certificate (Cert B)**
   - Let's Encrypt: `sudo certbot certonly --standalone -d rewordgame.net`
   - Commercial: Purchase from Sectigo/DigiCert (~$50/year)
   
2. **Store cert files securely**
   ```bash
   sudo cp /etc/letsencrypt/live/rewordgame.net/fullchain.pem /etc/ssl/certs/rewordgame_cert_b.pem
   sudo cp /etc/letsencrypt/live/rewordgame.net/privkey.pem /etc/ssl/private/rewordgame_key_b.pem
   sudo chmod 600 /etc/ssl/private/rewordgame_key_b.pem
   ```

3. **Extract Cert B fingerprint**
   ```bash
   openssl x509 -in /etc/ssl/certs/rewordgame_cert_b.pem -noout -fingerprint -sha256
   # Example: AB:12:34:CD:56:78:90:EF:...
   ```

4. **Update Flutter app config to pin [A, B]**
   - Edit `lib/config/config.dart`
   - Add Cert B fingerprint to `acceptedCertificateFingerprints` list
   - Keep Cert A in the list

5. **Test locally**
   - Build app: `flutter build apk` / `flutter build ios`
   - Test HTTPS connection to server
   - Verify cert pinning accepts both certs

6. **Submit app to stores**
   - Android: Google Play Console
   - iOS: App Store Connect
   - Release notes: "Security improvements"

7. **Wait for approval**
   - Android: Usually 1-3 days
   - iOS: Usually 2-7 days

**Timeline:** Complete by Day -90

---

### Phase 2: Adoption Period (60-30 days before expiry)

**Goal:** Release app and monitor user adoption

**Steps:**
1. **Release app update to users**
   - Staged rollout: 10% → 50% → 100% over 7 days
   - Monitor crash reports and reviews

2. **Monitor adoption metrics**
   - Firebase Analytics: Check version distribution
   - Target: 80%+ on new version within 30 days
   - Google Play Console: Check update statistics

3. **Wait for 80%+ adoption**
   - Week 1: Expect 40-50% adoption
   - Week 2: Expect 60-70% adoption
   - Week 3: Expect 75-85% adoption
   - Week 4: Should reach 80%+

4. **Daily monitoring of expiry countdown**
   - Check email alerts from manage-cert-rotation.sh
   - Review adoption progress daily
   - Plan rotation date when 80%+ achieved

**Decision Point:** 
- If 80%+ adoption: Proceed to Phase 3
- If < 80% adoption: See Emergency Procedures

**Timeline:** Day -60 to Day -30

---

### Phase 3: Rotation (15 days before expiry)

**Goal:** Switch server to new certificate

**Steps:**

1. **Pre-rotation checklist**
   - [ ] Verify 80%+ users on new app version
   - [ ] Backup current NGINX config
   - [ ] Test Cert B files exist and are readable
   - [ ] Schedule maintenance window (low-traffic time)
   - [ ] Notify team of planned rotation

2. **Install Cert B on server**
   ```bash
   # Backup current NGINX config
   sudo cp /etc/nginx/sites-available/rewordgame.net /etc/nginx/sites-available/rewordgame.net.backup

   # Update NGINX to use Cert B
   sudo nano /etc/nginx/sites-available/rewordgame.net
   
   # Change:
   # ssl_certificate /etc/letsencrypt/live/rewordgame.net/fullchain.pem;
   # ssl_certificate_key /etc/letsencrypt/live/rewordgame.net/privkey.pem;
   
   # To:
   # ssl_certificate /etc/ssl/certs/rewordgame_cert_b.pem;
   # ssl_certificate_key /etc/ssl/private/rewordgame_key_b.pem;
   ```

3. **Test NGINX configuration**
   ```bash
   sudo nginx -t
   # Must see: "configuration file /etc/nginx/nginx.conf test is successful"
   ```

4. **Reload NGINX** (zero downtime)
   ```bash
   sudo systemctl reload nginx
   ```

5. **Verify services work**
   ```bash
   # Test HTTPS connection
   curl -v https://rewordgame.net/health
   
   # Verify certificate fingerprint
   openssl s_client -connect rewordgame.net:443 -servername rewordgame.net < /dev/null 2>/dev/null | openssl x509 -noout -fingerprint -sha256
   
   # Should match Cert B fingerprint!
   ```

6. **Monitor for errors (24 hours)**
   - Check NGINX error logs: `sudo tail -f /var/log/nginx/error.log`
   - Monitor API errors (check daily maintenance report)
   - Watch for user complaints
   - Check app crash reports

**Rollback Plan:** If issues detected, revert to Cert A:
```bash
sudo cp /etc/nginx/sites-available/rewordgame.net.backup /etc/nginx/sites-available/rewordgame.net
sudo nginx -t && sudo systemctl reload nginx
```

**Timeline:** Day -15 to Day -14

---

### Phase 4: Cleanup (30 days after rotation)

**Goal:** Remove expired Cert A from app

**Steps:**

1. **Prepare next app update**
   - Remove Cert A fingerprint from `config.dart`
   - Keep Cert B
   - Add Cert C placeholder (commented out) for next rotation

2. **Generate Cert C (for 6-month strategy)**
   - Purchase next cert (expires 6 months after Cert B)
   - Extract fingerprint
   - Add to app config (commented out, ready for Day +150)

3. **Release update**
   - Submit to app stores
   - Release notes: "Performance improvements"
   - No urgency - users can update gradually

**Timeline:** Day +30 to Day +45

---

## Emergency Procedures

### Emergency 1: Cert A Expires Before Rotation

**Scenario:** Current cert expired, users with only Cert A pinned are locked out

**Symptoms:**
- Spike in connection errors
- Users report "can't connect"
- < 80% users updated to version with both certs

**Immediate Actions (within 1 hour):**

1. **Deploy emergency app hotfix**
   ```dart
   // In config.dart - TEMPORARY EMERGENCY MEASURE
   static const bool enableCertificatePinning = false;  // Disable pinning
   ```

2. **Submit emergency app release**
   - Mark as "Expedited Review" (iOS)
   - Request priority review (Android)
   - Include in release notes: "Critical connectivity fix"

3. **Deploy Cert B to NGINX immediately**
   ```bash
   sudo cp /etc/nginx/sites-available/rewordgame.net.backup /etc/nginx/sites-available/rewordgame.net
   # Update to use Cert B
   sudo nginx -t && sudo systemctl reload nginx
   ```

4. **Monitor emergency release adoption**
   - Track version numbers hourly
   - Expect 40-50% within 24 hours
   - 70-80% within 72 hours

5. **Re-enable pinning in next release**
   - After 80%+ on emergency version
   - Re-enable pinning with current cert
   - Test thoroughly before release

**Communication:**
- Send push notification: "Critical update required"
- Social media: "Experiencing connectivity issues? Update app"
- Email active users

**Post-mortem:**
- Document what went wrong
- Update monitoring thresholds
- Improve automation

---

### Emergency 2: App Pinning Breaks (Users Locked Out)

**Scenario:** Server cert is correct, but app rejects it anyway

**Symptoms:**
- All users suddenly can't connect
- Cert fingerprint matches expected
- NGINX serving correct cert

**Possible Causes:**
- Wrong fingerprint in app config (typo)
- Cert rotation completed, but app has old-only fingerprint
- NGINX serving intermediate cert instead of full chain

**Immediate Actions:**

1. **Verify server certificate**
   ```bash
   # Check what NGINX is actually serving
   openssl s_client -connect rewordgame.net:443 -servername rewordgame.net < /dev/null 2>/dev/null | openssl x509 -noout -fingerprint -sha256
   
   # Compare to app's expected fingerprint
   cat lib/config/config.dart | grep "acceptedCertificateFingerprints"
   ```

2. **If cert mismatch:**
   - Revert NGINX to previous working cert
   - Investigate why wrong cert was deployed

3. **If fingerprint mismatch in app:**
   - Emergency app release with correct fingerprint
   - Or temporarily disable pinning

4. **If intermediate cert issue:**
   ```bash
   # NGINX should serve fullchain, not just cert
   ssl_certificate /path/to/fullchain.pem;  # Not cert.pem!
   ```

**Prevention:**
- Always test cert rotation in staging first
- Verify fingerprints match before deploying
- Keep rollback plan ready

---

### Emergency 3: < 80% Adoption at Expiry Time

**Scenario:** Cert expiring in 7 days, but only 60% users updated

**Options:**

**Option A: Delay Rotation (Preferred if possible)**

1. **Extend current certificate**
   ```bash
   # For Let's Encrypt
   sudo certbot renew --force-renewal
   
   # Gets new 90-day cert with SAME fingerprint
   # Buys 90 more days for adoption
   ```

2. **Send push notification**
   - "Update available - improved security"
   - Deep link to app store

3. **Monitor adoption daily**
   - If 80%+ within extended window: Proceed normally
   - If still low: Consider forced update

**Option B: Proceed with Rotation (Accept some breakage)**

1. **Communicate planned downtime**
   - Email users on old version
   - In-app message: "Update required by [date]"
   - Social media announcement

2. **Proceed with rotation**
   - Accept that 20-40% users will break temporarily
   - They'll be forced to update when connection fails

3. **Support handling**
   - Prepare FAQ: "Can't connect? Update the app"
   - Monitor support tickets
   - Fast-track emergency app review if needed

**Option C: Implement Forced Update**

1. **Server-side version check**
   - API returns "update_required" for old versions
   - App shows blocking dialog: "Update required to continue"
   - Only allow access after update

2. **Monitor forced update adoption**
   - Expect rapid adoption (users need to play!)
   - 90%+ within 48 hours

**Decision Matrix:**
- Low expiry risk (>10 days): Choose Option A (delay)
- Medium risk (7-10 days): Choose Option B (proceed)
- High risk (<7 days): Choose Option C (force update)

---

## Complete Step-by-Step Checklist

### 90 Days Before Expiry

- [ ] Receive 30-day warning email from monitoring script
- [ ] Review current cert expiry date
- [ ] Decide: Let's Encrypt (free, 90 days) or Commercial ($50, 1 year)
- [ ] Purchase/generate new certificate (Cert B)
- [ ] Store Cert B files securely on server
- [ ] Extract Cert B SHA-256 fingerprint
- [ ] Document Cert B details (expiry date, fingerprint, location)

### 85 Days Before Expiry

- [ ] Clone Flutter app repository
- [ ] Create new branch: `feature/cert-rotation-[date]`
- [ ] Edit `lib/config/config.dart`
- [ ] Add Cert B fingerprint to `acceptedCertificateFingerprints` array
- [ ] Keep Cert A fingerprint in array
- [ ] Update cert metadata comments
- [ ] Test locally: `flutter run`
- [ ] Verify app connects to server successfully
- [ ] Commit changes: "Add Cert B to certificate pinning"

### 80 Days Before Expiry

- [ ] Build release APK: `flutter build apk --release`
- [ ] Build release iOS: `flutter build ios --release`
- [ ] Test on physical devices
- [ ] Verify HTTPS connections work
- [ ] Verify certificate pinning accepts both certs
- [ ] Run full test suite
- [ ] Fix any issues found

### 75 Days Before Expiry

- [ ] Update app version number
- [ ] Update changelog/release notes
- [ ] Create signed Android APK/AAB
- [ ] Create iOS archive
- [ ] Submit to Google Play Console
- [ ] Submit to App Store Connect
- [ ] Set release notes: "Security and stability improvements"

### 70 Days Before Expiry

- [ ] App approved by Google Play (usually 1-3 days)
- [ ] App approved by App Store (usually 3-7 days)
- [ ] Enable staged rollout: 10%
- [ ] Monitor crash reports for 24 hours
- [ ] Check user reviews for issues

### 65 Days Before Expiry

- [ ] Increase rollout to 50%
- [ ] Monitor adoption metrics in Firebase Analytics
- [ ] Check crash/error rates
- [ ] Respond to any user complaints

### 60 Days Before Expiry

- [ ] Increase rollout to 100%
- [ ] App available to all users
- [ ] Monitor adoption daily
- [ ] Send in-app notification: "Update available"

### 45 Days Before Expiry

- [ ] Check adoption rate (should be ~60-70%)
- [ ] If low adoption: Send push notification
- [ ] Review daily cert expiry monitoring emails
- [ ] Verify Cert B files still accessible on server

### 30 Days Before Expiry

- [ ] Receive 30-day warning email
- [ ] Verify adoption rate (target: 80%+)
- [ ] If < 80%: Implement additional nudges
  - [ ] Push notification
  - [ ] In-app banner
  - [ ] Email campaign
- [ ] If > 80%: Prepare for rotation

### 20 Days Before Expiry

- [ ] Final adoption check (must be 80%+)
- [ ] If < 80%: Consider emergency procedures
- [ ] If >= 80%: Schedule rotation date
- [ ] Notify team of planned rotation
- [ ] Prepare rollback plan

### 15 Days Before Expiry

**Rotation Day - Maintenance Window**

- [ ] Backup current NGINX config
- [ ] Verify Cert B files exist and readable
- [ ] Update NGINX config to use Cert B
- [ ] Test NGINX config: `sudo nginx -t`
- [ ] Reload NGINX: `sudo systemctl reload nginx`
- [ ] Verify HTTPS connection works
- [ ] Check cert fingerprint matches Cert B
- [ ] Monitor error logs for 1 hour
- [ ] Send test API requests
- [ ] Verify game works end-to-end

### 14 Days Before Expiry

- [ ] 24-hour monitoring complete
- [ ] No errors detected
- [ ] Review NGINX logs
- [ ] Check API error rates
- [ ] Review user complaints/support tickets
- [ ] Confirm rotation successful

### 7 Days Before Expiry

- [ ] Receive 7-day warning email (for old Cert A)
- [ ] Confirm Cert B is serving correctly
- [ ] Old cert (A) can now expire safely
- [ ] Document rotation completion
- [ ] Update cert management spreadsheet

### After Expiry (Day +1)

- [ ] Old Cert A expired
- [ ] Confirm no user impact
- [ ] Users on old app version (Cert A only): Broken (expected)
- [ ] Users on new app version (Cert A + B): Working fine
- [ ] Monitor support tickets for connection issues

### 30 Days After Expiry

- [ ] Prepare cleanup release
- [ ] Remove Cert A from `acceptedCertificateFingerprints`
- [ ] Add Cert C placeholder (commented, for next rotation)
- [ ] Update app version
- [ ] Submit to stores
- [ ] Release (no urgency)

### 60 Days After Expiry (Day +60)

- [ ] Begin planning next rotation
- [ ] Current cert (B) has ~210 days left
- [ ] If commercial cert: Purchase Cert C (expires Cert B + 6 months)
- [ ] For next rotation: Start at Day -90 again

---

## Rotation Timeline Summary

```
Day -90: Purchase Cert B, start app development
Day -85: Add Cert B to app config
Day -75: Submit app to stores
Day -60: App released, monitoring begins
Day -30: Check 80%+ adoption
Day -15: Rotate server to Cert B
Day -14: 24-hour monitoring
Day +0:  Cert A expires (expected, no impact)
Day +30: Remove Cert A from app
Day +60: Plan next rotation
```

---

## Tools & Scripts

### Certificate Monitoring
- **Script:** `/home/gameadmin/reword-utilities/cert-maintenance/manage-cert-rotation.sh`
- **Frequency:** Daily (via cron)
- **Alerts:** Email at 30/15/7 days

### Get Certificate Fingerprint
```bash
openssl x509 -in /path/to/cert.pem -noout -fingerprint -sha256
```

### Check Server Certificate
```bash
openssl s_client -connect rewordgame.net:443 -servername rewordgame.net < /dev/null 2>/dev/null | openssl x509 -noout -fingerprint -sha256
```

### Test NGINX Config
```bash
sudo nginx -t
```

### Check Cert Expiry
```bash
openssl x509 -in /path/to/cert.pem -noout -enddate
```

---

## Communication Templates

### Email: 30-Day Warning (Internal)
```
Subject: Certificate Rotation Required - 30 Days

Action Required: SSL certificate rotation in 30 days

Current Cert (A) expires: [DATE]
New Cert (B) fingerprint: [FINGERPRINT]

Next Steps:
1. Verify Cert B is ready
2. Update Flutter app with both fingerprints
3. Submit app to stores by [DATE]
4. Monitor adoption for 30 days

See: /docs/certificate_rotation_playbook.md
```

### Push Notification: Update Available
```
Title: Update Available
Body: New version with improved security. Update now!
Action: Open App Store
```

### Support FAQ
```
Q: Why can't I connect to Re-Word?
A: Please update to the latest version from the App Store / Play Store.
   We've improved security and older versions are no longer supported.
```

---

## Post-Rotation Review

After each rotation, document:

- [ ] What went well?
- [ ] What could be improved?
- [ ] How long did each phase take?
- [ ] What was the final adoption rate?
- [ ] Were there any user complaints?
- [ ] Did we need any emergency procedures?
- [ ] Updates to this playbook needed?

---

## Document History

- **2026-02-22:** Initial version
- **[Next Update]:** Document improvements after first rotation

---

## Related Documents

- Security Architecture: `/docs/SecurityArchitecture.md`
- Cert Monitoring Script: `/reword-utilities/cert-maintenance/manage-cert-rotation.sh`
- Daily Maintenance: `/gameadmin-server/scripts/dailymaintenance`
