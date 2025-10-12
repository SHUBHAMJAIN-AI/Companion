# All Contacts - Direct Call & Email Feature

## Overview
Updated All Contacts tab to provide direct call and email functionality with custom card layout, matching the on-call doctors experience.

## Changes Made

### 1. New Custom View - AllContactCard
Created specialized card for all contacts that:
- Shows contact name, title, and description
- Provides direct call button (green phone icon)
- Provides direct email button (blue envelope icon)
- One-tap communication without navigation

### 2. Direct Communication Actions

**Call Button** (Green):
- Taps phone icon → opens Phone app
- Automatically dials the contact number
- URL scheme: `tel://[number]`

**Email Button** (Blue):
- Taps envelope icon → opens Mail app
- Pre-fills recipient email address
- URL scheme: `mailto:[email]`

### 3. Contact Information Extraction
- Extracts phone number from contact options
- Extracts email from contact options
- Displays both action buttons when available
- Cleans phone number formatting

## UI Design

### All Contact Card Layout
```
┌─────────────────────────────────────────┐
│ [Icon]  Dr. Emily Rodriguez      [📞] [✉️] │
│         Chief of Medicine               │
│         Department head and internal    │
│         medicine specialist             │
└─────────────────────────────────────────┘
```

**Components**:
- **Left**: Contact icon (40pt, blue)
- **Center**: Name, title, and description
- **Right**: Call (green) and Email (blue) buttons

## Example Display

### All Contacts Tab
```
👤 Dr. Emily Rodriguez                    📞 ✉️
   Chief of Medicine
   Department head and internal medicine 
   specialist

🧠 Dr. David Kim                          📞 ✉️
   Neurologist
   Neurology department specialist

❤️ Dr. Lisa Patel                         📞 ✉️
   Cardiologist
   Cardiovascular medicine specialist
```

## Code Structure

### New Components

**AllContactsList**:
- ScrollView container for contact cards
- Replaces standard ContactsList for tab 1

**AllContactCard**:
- Custom card showing full contact info
- Call and email action buttons
- Phone number and email extraction logic

### Key Functions

```swift
private func makeCall(_ phoneNumber: String) {
    let cleanNumber = phoneNumber.replacingOccurrences(of: " ", with: "")
        .replacingOccurrences(of: "(", with: "")
        .replacingOccurrences(of: ")", with: "")
        .replacingOccurrences(of: "-", with: "")
    if let url = URL(string: "tel://\(cleanNumber)") {
        UIApplication.shared.open(url)
    }
}

private func sendEmail(_ email: String) {
    if let url = URL(string: "mailto:\(email)") {
        UIApplication.shared.open(url)
    }
}
```

## User Experience

### All Contacts Tab
1. User opens Contacts → All Contacts
2. Sees full staff directory with names
3. Taps green phone icon → Phone app opens with number
4. Taps blue envelope icon → Mail app opens with email
5. Quick access for staff communication

## Benefits

### Consistency
- Matches on-call doctors UI pattern
- Unified experience across both tabs
- Same action button style

### Efficiency
- One-tap call/email actions
- No navigation to detail view needed
- Faster communication workflow

### Clarity
- Clear visual indicators (icons)
- Color-coded actions (green=call, blue=email)
- Complete contact information visible

## Testing Checklist

- [ ] Open Contacts from bottom nav
- [ ] Switch to All Contacts tab
- [ ] Verify 15 contact cards displayed
- [ ] Verify names, titles, descriptions visible
- [ ] Tap green phone icon
- [ ] Verify Phone app opens with number
- [ ] Tap blue envelope icon
- [ ] Verify Mail app opens with email
- [ ] Verify both buttons work for each contact
- [ ] Switch to On Call Doctors tab
- [ ] Verify consistent UI design

## Contact Information Display

**Name**: Full name from PersonNameComponents
**Title**: Role/position
**Description**: Detailed specialty/responsibilities
**Phone**: Extracted from `.call()` option
**Email**: Extracted from `.email()` option

## Icon Colors

| Button | Color | Icon | Purpose |
|--------|-------|------|---------|
| Call | Green | phone.fill | Phone call |
| Email | Blue (#1976D2) | envelope.fill | Email message |
| Contact Icon | Blue (#1976D2) | Various | Visual ID |

## URL Schemes

| Action | URL Scheme | Example |
|--------|-----------|---------|
| Call | `tel://` | `tel://+17325550201` |
| Email | `mailto:` | `mailto:e.rodriguez@rwjuh.edu` |

## Comparison: Before vs After

### Before
- Standard SpeziContact view
- Required tap to view details
- Multiple steps to call/email
- Different UI from on-call doctors

### After
- Custom card layout
- Direct call/email buttons
- One-tap communication
- Consistent UI with on-call doctors

## Code Location

**File**: `TemplateApplication/Contacts/Contacts.swift`

**New Components**:
- `AllContactsList` (lines ~197-207)
- `AllContactCard` (lines ~209-290)

**Modified**:
- `Contacts.body` - uses `AllContactsList` for tab 1

## Both Tabs Now Feature

### On-Call Doctors
- Department-focused (no names)
- Call + Message buttons
- Urgent consultation access

### All Contacts
- Name-focused (full details)
- Call + Email buttons
- General staff communication

## Summary

**All Contacts Tab**:
- Shows full names and titles
- Direct call and email buttons
- Custom card layout
- One-tap communication
- Consistent with on-call doctors UI
- 15 staff members with complete info
