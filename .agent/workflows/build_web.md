---
description: How to build and serve the Flutter web application
---

### Prerequisites
- Flutter SDK installed and configured.
- Google Chrome installed (for testing).

### Steps

1. **Verify Web Support**
   Ensure that web is a valid target for your environment:
   ```bash
   flutter devices
   ```
   You should see "Chrome (web)" in the list.

2. **Run in Development Mode**
   To start the app with hot reload in Chrome:
   // turbo
   ```bash
   flutter run -d chrome
   ```

3. **Build for Release**
   To generate a production build with optimized performance:
   // turbo
   ```bash
   flutter build web --release
   ```
   The output will be in `build/web/`.

4. **Serve Locally (for testing)**
   To quickly verify the release build:
   // turbo
   ```bash
   cd build/web && python3 -m http.server 8081
   ```
   Access the app at `http://localhost:8081`.

5. **Deployment**
   Upload the contents of `build/web/` to any static hosting provider.

   #### Vercel
   - **Command Line**: Install Vercel CLI (`npm i -g vercel`) and run `vercel`.
   - **Dashboard**: Push your code to GitHub/GitLab/Bitbucket and import the project.
   - **Build Settings**:
     - Framework Preset: `Other`
     - Build Command: `flutter build web --release`
     - Output Directory: `build/web`
     - Install Command: (Leave blank or use a custom script to install Flutter if using Vercel's build environment)
   - **Note**: It's often easier to build locally and deploy the `build/web` folder: `vercel deploy build/web`.

   #### Netlify
   - **Command Line**: Install Netlify CLI (`npm i -g netlify-cli`) and run `netlify deploy --dir=build/web`.
   - **Dashboard**: Connect your repository.
   - **Build Settings**:
     - Build Command: `flutter build web --release`
     - Publish Directory: `build/web`
   - **Note**: Similar to Vercel, Netlify requires Flutter to be in the CI path. If not available, build locally and run `netlify deploy --prod --dir=build/web`.

   #### Other Options
   - Firebase Hosting
   - GitHub Pages
   - AWS S3 / CloudFront
```