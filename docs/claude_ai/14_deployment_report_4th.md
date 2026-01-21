# AWS Lightsail Production Deployment Complete Response Report

**Date**: December 15, 2025  
**Assignee**: Claude Code  
**Task**: AWS Lightsail production environment issue resolution・deployment safety improvement  
**Source**: `/reports/2025-12-15/4th.md`

---

## 🎯 Implementation Summary

Today we resolved multiple critical issues in the AWS Lightsail production environment and constructed a safe and sustainable deployment environment.

### Resolved Issues
1. **Solid Queue/Cache Missing Issue**: Migration creation・worker addition
2. **OGP/ActiveStorage URL Issue**: Host configuration・nginx integration
3. **Let's Encrypt Rate Limiting Incident**: deploy.sh safety improvement・emergency recovery function

## 📊 Detailed Problems and Solutions

### 1. Solid Queue/Cache Problem

#### Symptoms
- 500 error when saving images in admin panel
- `PG::UndefinedTable: solid_queue_jobs`
- `solid_cache_entries` table missing

#### Root Cause
- Migration files missing from repository (commit oversight)
- Solid Queue worker process non-existent

#### Solutions
```ruby
# 1. Solid Cache Migration Creation
class CreateSolidCacheEntries < ActiveRecord::Migration[8.1]
  # Already implemented
end

# 2. Solid Queue Migration Creation
class CreateSolidQueueTables < ActiveRecord::Migration[8.1]
  # 11 tables created
end
```

```yaml
# 3. Added worker to docker-compose.production.yml
portfolio-worker:
  command: bundle exec rails solid_queue:start
  # Same environment and volumes as web
```

### 2. OGP/ActiveStorage URL Generation Problem

#### Symptoms
- Frontend page 500 error: `Missing host to link to!`
- Image URL: `https://portfolio-web/rails/active_storage/...`
- `net::ERR_NAME_NOT_RESOLVED`

#### Root Cause
- Rails.application.routes.default_url_options not configured
- Inappropriate nginx Host header
- ActiveStorage::Current.url_options not configured

#### Solutions
```ruby
# config/environments/production.rb
Rails.application.routes.default_url_options[:host] = ENV.fetch("APP_HOST", "example.test")
Rails.application.routes.default_url_options[:protocol] = "https"

config.after_initialize do
  ActiveStorage::Current.url_options = Rails.application.routes.default_url_options
end
```

```nginx
# nginx.production.conf
proxy_set_header Host $http_host;
proxy_set_header X-Forwarded-Host $http_host;
```

### 3. Let's Encrypt Rate Limiting Incident

#### Symptoms
- SSL certificate deletion with `docker compose down -v`
- 429 error from repeated reissuance attempts
- https-portal in Restarting loop
- Complete site shutdown

#### Root Cause
- deploy.sh executing destructive operations by default
- Lack of volume protection functionality

#### Solutions

**A) Complete deploy.sh Overhaul**
```bash
# Safe default behavior
./scripts/deploy.sh                # Protect all volumes
./scripts/deploy.sh --clean-cache   # Delete tmp/log only
./scripts/deploy.sh --wipe-all      # Requires "WIPE_ALL_VOLUMES" input
```

**B) Emergency HTTP Recovery Function**
```yaml
# docker-compose.production.http.yml
services:
  https-portal:
    profiles: ["disabled"]
  nginx:
    ports: ["80:80"]
```

## 🔧 Implemented Safety Features

### 1. Volume Protection System
```bash
Protected (never delete):
- https_portal_data  # SSL certificates
- postgres_data      # Database
- storage_data       # Uploaded images

Safe to delete:
- tmp_data
- log_data
```

### 2. Staged Verification Flow
```bash
1. Environment variable validation (including APP_HOST)
2. Docker image build
3. Container startup and wait
4. DB connection verification
5. Migration execution
6. Worker startup verification
7. https-portal status verification
```

### 3. Automatic Error Diagnosis
```bash
on_error() {
  # Automatic dump of all container logs
  # portfolio-web/worker/db/nginx/https-portal
}
```

## 📝 Deployment Work Lessons

### 1. Absolutely Never Do
- ❌ `docker compose down -v` in production
- ❌ Frequent SSL certificate reissuance
- ❌ Deploy without environment variables configured
- ❌ Use ActiveStorage without worker

### 2. Must Always Do
- ✅ Confirm migration commits
- ✅ Pre-configure environment variables (APP_HOST etc.)
- ✅ Full local testing
- ✅ Volume protection awareness

### 3. Emergency Response
- Use emergency HTTP mode when Let's Encrypt rate limited
- Utilize automatic log diagnosis on errors
- Destructive operations require explicit confirmation

## 🎯 Completion Status

### Normal Operation Confirmed
- ✅ Frontend page display
- ✅ Admin panel login
- ✅ Image upload and display
- ✅ OGP URL generation
- ✅ Background job processing

### Security & Stability
- ✅ SSL certificate protection
- ✅ Database protection
- ✅ Emergency recovery procedures established
- ✅ GitHub and AWS synchronization

## 💡 Future Recommendations

1. **Regular Backups**
   ```bash
   docker exec portfolio-prod-portfolio-db-1 pg_dump -U portfolio portfolio_production > backup.sql
   ```

2. **SSL Certificate Renewal Monitoring**
   - Verify automatic renewal every 90 days
   - Use emergency HTTP mode on failure

3. **Pre-Deployment Checklist**
   - [ ] Confirm migration commits
   - [ ] Confirm environment variable configuration
   - [ ] Complete local testing
   - [ ] Take backup

## 🚀 Next Deployment Commands

```bash
# Normal safe deployment
cd ~/web-server/portfolio
git pull origin main
./scripts/deploy.sh

# When problems occur
./scripts/deploy.sh --clean-cache  # Cache clear
# or refer to HTTPS_RECOVERY.md
```

---

**Conclusion**: Used the experience of hitting production deployment "landmines" to construct safe and recoverable operation environment. Complete recovery expected morning of 17th after Let's Encrypt restriction lift.