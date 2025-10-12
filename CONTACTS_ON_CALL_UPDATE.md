# On-Call Doctors Contact Update

## Overview
Updated the On-Call Doctors view to show only department information (without doctor names) and provide direct call/message functionality.

## Changes Made

### 1. New Custom View - OnCallDoctorCard
Created a specialized card for on-call doctors that:
- Shows department icon and title
- Displays department description
- Provides call and message buttons
- Hides doctor names for privacy/simplicity

### 2. Direct Communication Actions
**Call Button** (Green):
- Taps phone icon → opens Phone app
- Automatically dials the on-call number
- URL scheme: `tel://[number]`

**Message Button** (Blue):
- Taps message icon → opens Messages app
- Pre-fills phone number for SMS
- URL scheme: `sms://[number]`

### 3. Phone Number Handling
- Extracts phone number from contact options
- Cleans formatting (removes spaces, parentheses, dashes)
- Converts to proper URL scheme format

## UI Design

### On-Call Doctor Card Layout
```
┌─────────────────────────────────────────┐
│ [Icon]  Department Title        [📞] [💬] │
│         Description text                │
└─────────────────────────────────────────┘
```

**Components**:
- **Left**: Department icon (40pt, blue)
- **Center**: Title and description
- **Right**: Call (green) and Message (blue) buttons

### All Contacts (Unchanged)
- Shows full contact details with names
- Uses standard SpeziContact view
- Includes email options

## Example Display

### On-Call Doctors Tab
```
🫀 Cardiology - On Call                    📞 💬
   Cardiology specialist available for 
   urgent consultations

🚑 Emergency Medicine - On Call            📞 💬
   Emergency department attending 
   physician

🫁 Internal Medicine - On Call             📞 💬
   Hospitalist for general medicine 
   consultations
```

### All Contacts Tab (Unchanged)
```
Dr. Emily Rodriguez
Chief of Medicine
Department head and internal medicine specialist
📞 e.rodriguez@rwjuh.edu
```

## Code Structure

### New Components

**OnCallDoctorsList**:
- ScrollView container for on-call cards
- Replaces standard ContactsList for tab 0

**OnCallDoctorCard**:
- Custom card showing department info
- Call and message action buttons
- Phone number extraction logic

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

private func sendMessage(_ phoneNumber: String) {
    let cleanNumber = phoneNumber.replacingOccurrences(of: " ", with: "")
        .replacingOccurrences(of: "(", with: "")
        .replacingOccurrences(of: ")", with: "")
        .replacingOccurrences(of: "-", with: "")
    if let url = URL(string: "sms://\(cleanNumber)") {
        UIApplication.shared.open(url)
    }
}
```

## User Experience

### On-Call Doctors Tab
1. User opens Contacts → On Call Doctors
2. Sees list of departments (no names)
3. Taps green phone icon → Phone app opens with number
4. Taps blue message icon → Messages app opens with number
5. Quick access for urgent consultations

### All Contacts Tab
1. User opens Contacts → All Contacts
2. Sees full staff directory with names
3. Taps contact → detailed view
4. Multiple contact options (call, email)

## Benefits

### Privacy
- On-call numbers are department-based
- No individual doctor names exposed
- Maintains professional boundaries

### Simplicity
- Clear department identification
- One-tap call/message actions
- No navigation to detail view needed

### Efficiency
- Faster access for urgent calls
- Direct communication channels
- Reduced steps to contact on-call doctor

## Testing Checklist

- [ ] Open Contacts from bottom nav
- [ ] Switch to On Call Doctors tab
- [ ] Verify 8 department cards displayed
- [ ] Verify no doctor names shown
- [ ] Verify department titles visible
- [ ] Verify descriptions visible
- [ ] Tap green phone icon
- [ ] Verify Phone app opens with number
- [ ] Tap blue message icon
- [ ] Verify Messages app opens with number
- [ ] Switch to All Contacts tab
- [ ] Verify full contact details with names
- [ ] Verify standard contact view works

## Phone Number Format

**Input**: `+1 (732) 555-0101`
**Cleaned**: `+17325550101`
**URL**: `tel://+17325550101`

## Icon Colors

| Button | Color | Purpose |
|--------|-------|---------|
| Phone | Green | Call action |
| Message | Blue (#1976D2) | SMS action |
| Department Icon | Blue (#1976D2) | Visual identification |

## Comparison: Before vs After

### Before
- Showed doctor names on on-call list
- Required tap to view contact details
- Standard contact card layout
- Multiple steps to call/message

### After
- Shows only department names
- Direct call/message buttons
- Custom card layout
- One-tap communication

## Code Location

**File**: `TemplateApplication/Contacts/Contacts.swift`

**New Components**:
- `OnCallDoctorsList` (lines ~105-115)
- `OnCallDoctorCard` (lines ~117-195)

**Modified**:
- `Contacts.body` - uses `OnCallDoctorsList` for tab 0

## URL Schemes Used

| Action | URL Scheme | Example |
|--------|-----------|---------|
| Call | `tel://` | `tel://+17325550101` |
| Message | `sms://` | `sms://+17325550101` |

## Future Enhancements

- [ ] Add availability status (available/busy)
- [ ] Show estimated response time
- [ ] Add pager numbers
- [ ] Include backup on-call contacts
- [ ] Add department-specific protocols
- [ ] Show current on-call schedule
- [ ] Add emergency vs routine contact options
- [ ] Include video call option
- [ ] Add contact history
- [ ] Show last contacted timestamp

## Summary

**On-Call Doctors Tab**:
- Department-focused display
- No doctor names shown
- Direct call/message buttons
- Optimized for urgent communication

**All Contacts Tab**:
- Full staff directory
- Complete contact information
- Standard contact view
- Comprehensive details
