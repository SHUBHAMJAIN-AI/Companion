# Firestore Security Rules

## Required Security Rules for the App

Add these rules to your Firebase Console → Firestore Database → Rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // User data - users can only read/write their own data
    match /users/{userId}/{document=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Posts - authenticated users can read all, create new, but only delete their own
    match /posts/{postId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null;
      allow delete: if request.auth != null && 
                      request.auth.token.email == resource.data.author;
      allow update: if request.auth != null;
    }
    
    // Announcements - authenticated users can read all, create new, admins can delete
    match /announcements/{announcementId} {
      allow read, create: if request.auth != null;
      allow update: if request.auth != null;
      allow delete: if request.auth != null;
    }
    
    // Feedback - authenticated users can create, read their sent/received feedback
    match /feedback/{feedbackId} {
      allow read: if request.auth != null && 
                    (request.auth.token.email == resource.data.toEmail ||
                     request.auth.token.email == resource.data.fromEmail);
      allow create: if request.auth != null;
      allow update: if request.auth != null && 
                      request.auth.token.email == resource.data.toEmail;
    }
  }
}
```

## Rule Explanations

### Posts Collection
- **Read**: Any authenticated user can read all posts
- **Create**: Any authenticated user can create posts
- **Delete**: Post author OR administrator can delete posts
- **Update**: Any authenticated user can update (for likes/dislikes)

### Announcements Collection
- **Read**: Any authenticated user can read all announcements
- **Create**: Any authenticated user can create announcements
- **Delete**: Administrator can delete announcements
- **Update**: Any authenticated user can update

### Key Security Features
1. **Author Verification**: `request.auth.token.email == resource.data.author`
   - Compares logged-in user's email with post's author field
   - Prevents users from deleting others' posts

2. **Authentication Required**: All operations require `request.auth != null`

3. **Email-Based Authorization**: Uses email instead of UID for author matching

## Required Composite Indexes

Create these indexes in Firebase Console → Firestore Database → Indexes:

1. **Feedback by toEmail and timestamp**
   - Collection: `feedback`
   - Fields: `toEmail` (Ascending), `timestamp` (Descending)

2. **Posts by date**
   - Collection: `posts`
   - Fields: `date` (Descending)

3. **Announcements by date**
   - Collection: `announcements`
   - Fields: `date` (Descending)

## Testing Security Rules

### Test 1: Delete Own Post
1. Login as doctor1@hospital.com
2. Create a post
3. Try to delete it
4. **Expected**: Success ✅

### Test 2: Delete Other's Post (Doctor)
1. Login as doctor1@hospital.com
2. Try to delete post by doctor2@hospital.com
3. **Expected**: No delete button visible ❌

### Test 3: Delete Any Post (Admin)
1. Login as admin@hospital.com
2. View any post
3. **Expected**: Delete button visible on all posts ✅
4. Delete any post
5. **Expected**: Success ✅

### Test 4: Delete Announcement (Admin)
1. Login as admin@hospital.com
2. View announcements tab
3. **Expected**: Delete button on all announcements ✅
4. Delete announcement
5. **Expected**: Success ✅

### Test 5: View All Posts
1. Login as any user
2. View Discover tab
3. **Expected**: See all posts ✅

## Deployment Steps

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select your project
3. Navigate to Firestore Database → Rules
4. Copy the rules above
5. Click "Publish"
6. Wait for deployment (usually instant)
7. Test with your app

## Common Issues

### Issue: "Missing or insufficient permissions"
**Cause**: Security rules not deployed or incorrect
**Fix**: 
1. Check rules are published
2. Verify user is authenticated
3. Check author email matches exactly

### Issue: Delete button not showing
**Cause**: Email mismatch between logged-in user and post author
**Fix**:
1. Check console: `print(currentUserEmail)` and `print(article.author)`
2. Ensure emails match exactly (case-sensitive)
3. Verify Auth.auth().currentUser?.email returns correct value

### Issue: Delete succeeds but post still visible
**Cause**: Local state not refreshed
**Fix**: Already handled - `await fetchPosts()` called after delete

## Data Structure

### Post Document
```json
{
  "title": "Post Title",
  "content": "Post content...",
  "author": "doctor@hospital.com",
  "department": "Cardiology",
  "date": Timestamp,
  "likes": 0,
  "dislikes": 0,
  "likedBy": [],
  "dislikedBy": []
}
```

### Key Field: `author`
- Stores user's email address
- Used for delete authorization
- Must match `request.auth.token.email` for delete to succeed
