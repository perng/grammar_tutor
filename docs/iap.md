# In-App Purchase (IAP) Feature Proposal

## Executive Summary
This document outlines a proposal for integrating In-App Purchases (IAP) into the Grammar Tutor application. The goal is to monetize the application while maintaining a high-quality free experience that encourages user growth and retention.

## 1. Monetization Strategy
The recommended strategy is a **"Freemium" model with a Lifetime Unlock**. 
- **Free Tier**: Users get access to the first **3-5 levels** of every game category. This allows them to experience the variety and quality of the content.
- **paid Tier ("Pro Access")**: A one-time purchase unlocks all current and future levels across all game categories.

### Why Lifetime Unlock?
- **Simplicity**: Easier to implement than subscriptions.
- **User Preference**: Educational apps often benefit from "own it forever" perceived value.
- **Content Nature**: Grammar is a finite subject for many learners; a subscription might feel punitive if they just want to study at their own pace.

## 2. Proposed IAP Products

### A. **Premium Access (Non-Consumable)**
*   **Name**: `grammar_tutor_premium_unlock`
*   **Display Name**: "Full Access / Pro Version"
*   **Description**: "Unlock all levels, track advanced stats, and remove future ads."
*   **Price Point**: $4.99 - $9.99 USD (Tier 5-10)

### B. **Coffee Donation (Consumable)**
*   **Name**: `donation_coffee`
*   **Display Name**: "Buy me a Coffee"
*   **Description**: "Support the developer to keep the updates coming!"
*   **Price Point**: $1.99 - $2.99 USD

## 3. UI/UX Changes

### Locked Content Visuals
- **StoryMenuScreen**: 
    - Levels beyond the free limit (e.g., Level > 5) will be displayed with a **Padlock Icon** instead of the usual completion indicator.
    - Tapping a locked level opens the **Paywall / Upsell Screen**.
    - Locked levels can have a slightly dimmed or greyscale background to visually distinguish them.

### Upsell Screen (Paywall)
- A dedicated, beautiful modal or screen that appears when a user tries to access locked content.
- **Features**:
    - "Unlock All Content" button.
    - "Restore Purchases" button (mandatory for iOS).
    - clear benefits list (e.g., "100+ Stories", "Offline Support", "Support Development").

### Settings
- Add a "Upgrade to Pro" entry in the settings/home menu if the user hasn't purchased yet.

## 4. Technical Implementation Plan

We will use the **`in_app_purchase`** package (official Flutter package) or **`revenue_cat`** (wrapper for easier management).

### Recommended Stack: `in_app_purchase` + `provider`
1.  **Dependency**: Add `in_app_purchase` to `pubspec.yaml`.
2.  **State Management**: Create an `IAPProvider` to handle:
    -   Initialization of the connection.
    -   Loading available products.
    -   Listening to purchase streams (pending, bought, error).
    -   Verifying purchases (local or server-side).
    -   Persisting "Pro" status securely (e.g., SecureStorage or simplistic SharedPrefs for MVP).
3.  **UI Integration**:
    -   Wrap `MaterialApp` with `IAPProvider`.
    -   In `StoryMenuScreen`, read `IAPProvider.isPro`.
    -   Conditional rendering for list items based on `levelIndex` and `isPro`.

## 5. Future Considerations
-   **Ad Integration**: If revenue from IAP is low, non-intrusive banner ads can be added, with the "Pro Access" also removing them.
-   **Themed Content**: Seasonal unlocks or specialized packs (e.g., "Business English Pack").

---
**Next Steps**:
1.  Approve this proposal.
2.  Set up App Store Connect (iOS) and Google Play Console (Android) with the product IDs.
3.  Begin implementation of `IAPProvider` and the UI modifications.
