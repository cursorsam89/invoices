# Troubleshooting Guide

## Common Issues and Solutions

### 1. **SDK Version Mismatch Error**

**Error:**
```
Because app requires SDK version ^3.8.1, version solving failed.
```

**Solution:**
- Update `pubspec.yaml` to use compatible SDK version:
  ```yaml
  environment:
    sdk: '>=3.3.0 <4.0.0'
  ```

### 2. **Package Resolution Issues**

**Error:**
```
Error: Couldn't resolve the package 'app' in 'package:app/main.dart'.
```

**Solution:**
- Clean the build cache:
  ```bash
  flutter clean
  flutter pub get
  ```

### 3. **GitHub Actions Build Failures**

**Common Causes:**
- SDK version incompatibility
- Missing environment variables
- Flutter version mismatch

**Solutions:**
1. **Check Flutter Version**: Ensure GitHub Actions uses compatible Flutter version
2. **Update pubspec.yaml**: Use flexible SDK constraints
3. **Add Environment Variables**: Configure Supabase credentials in GitHub Secrets

### 4. **Environment Variables Not Working**

**Issue:** App can't connect to Supabase

**Solution:**
- For GitHub Pages: Add secrets in repository settings
- For Netlify: Add environment variables in site settings
- For Vercel: Add environment variables in project settings

### 5. **Build Cache Issues**

**Symptoms:** Strange build errors, package not found

**Solution:**
```bash
flutter clean
flutter pub get
flutter build web --release
```

### 6. **Web Build Failures**

**Common Issues:**
- Missing web support
- Incompatible dependencies
- Memory issues during build

**Solutions:**
1. Enable web support: `flutter config --enable-web`
2. Update dependencies: `flutter pub upgrade`
3. Use release build: `flutter build web --release`

### 7. **Deployment Platform Specific Issues**

#### GitHub Pages
- **Issue:** 404 errors
- **Solution:** Ensure base href is set correctly in `web/index.html`

#### Netlify
- **Issue:** Build fails
- **Solution:** Add build command: `flutter build web --release`

#### Vercel
- **Issue:** Build timeout
- **Solution:** Increase build timeout in Vercel settings

### 8. **Performance Issues**

**Symptoms:** Slow loading, large bundle size

**Solutions:**
1. Use release build: `flutter build web --release`
2. Enable tree-shaking (already enabled by default)
3. Optimize images and assets
4. Use CDN for static assets

### 9. **Authentication Issues**

**Common Problems:**
- CORS errors
- Invalid Supabase credentials
- Missing authentication setup

**Solutions:**
1. Configure CORS in Supabase dashboard
2. Verify environment variables
3. Enable authentication in Supabase

### 10. **Mobile/Desktop Compatibility**

**Issues:** App doesn't work on certain devices

**Solutions:**
1. Test responsive design
2. Check browser compatibility
3. Ensure PWA features are working

## Quick Fix Commands

```bash
# Fix most common issues
flutter clean
flutter pub get
flutter config --enable-web
flutter build web --release

# Check Flutter version
flutter --version

# Check dependencies
flutter pub deps

# Analyze code
flutter analyze
```

## Getting Help

1. **Check Logs**: Look at build logs for specific error messages
2. **Flutter Doctor**: Run `flutter doctor` to check setup
3. **GitHub Issues**: Check for similar issues in Flutter repository
4. **Community**: Ask in Flutter Discord or Stack Overflow

## Prevention Tips

1. **Use Compatible Versions**: Keep Flutter and dependencies up to date
2. **Test Locally**: Always test builds locally before deploying
3. **Environment Variables**: Never commit sensitive data
4. **Regular Updates**: Update dependencies regularly
5. **Backup**: Keep backups of working configurations

---

**Need more help?** Check the [Deployment Guide](DEPLOYMENT_GUIDE.md) or create an issue in the repository.