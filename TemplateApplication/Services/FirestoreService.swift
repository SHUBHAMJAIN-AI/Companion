//
// Firestore-based Social Posts Service
//

import Foundation
import FirebaseFirestore

@MainActor
class PostsService: ObservableObject {
    private let db = Firestore.firestore()
    @Published var posts: [Article] = []
    @Published var announcements: [Announcement] = []
    
    func createPost(title: String, content: String, author: String) async throws {
        print("📤 Uploading post to Firestore: \(title)")
        let postData: [String: Any] = [
            "title": title,
            "content": content,
            "author": author,
            "date": Timestamp(date: Date()),
            "likes": 0,
            "dislikes": 0,
            "likedBy": [],
            "dislikedBy": []
        ]
        try await db.collection("posts").addDocument(data: postData)
        print("✅ Post uploaded successfully: \(title)")
        await fetchPosts()
    }
    
    func createAnnouncement(title: String, content: String, type: String, author: String) async throws {
        print("📤 Uploading announcement to Firestore: \(title)")
        let announcementData: [String: Any] = [
            "title": title,
            "content": content,
            "type": type,
            "author": author,
            "date": Timestamp(date: Date())
        ]
        try await db.collection("announcements").addDocument(data: announcementData)
        print("✅ Announcement uploaded successfully: \(title)")
        await fetchAnnouncements()
    }
    
    func fetchPosts() async {
        print("📥 Fetching posts from Firestore...")
        do {
            let snapshot = try await db.collection("posts").order(by: "date", descending: true).getDocuments()
            posts = snapshot.documents.compactMap { doc in
                let data = doc.data()
                guard let title = data["title"] as? String,
                      let author = data["author"] as? String,
                      let content = data["content"] as? String,
                      let timestamp = data["date"] as? Timestamp else { return nil }
                let likes = data["likes"] as? Int ?? 0
                let dislikes = data["dislikes"] as? Int ?? 0
                let likedBy = data["likedBy"] as? [String] ?? []
                let dislikedBy = data["dislikedBy"] as? [String] ?? []
                return Article(
                    id: doc.documentID, title: title, author: author, date: timestamp.dateValue(),
                    content: content, likes: likes, dislikes: dislikes, likedBy: likedBy, dislikedBy: dislikedBy
                )
            }
            print("✅ Downloaded \(posts.count) posts from Firestore")
        } catch {
            print("❌ Error fetching posts: \(error)")
        }
    }
    
    func toggleLike(postId: String, userId: String, currentlyLiked: Bool, currentlyDisliked: Bool) async {
        if currentlyLiked {
            try? await db.collection("posts").document(postId).updateData([
                "likes": FieldValue.increment(Int64(-1)),
                "likedBy": FieldValue.arrayRemove([userId])
            ])
        } else {
            var updates: [String: Any] = [
                "likes": FieldValue.increment(Int64(1)),
                "likedBy": FieldValue.arrayUnion([userId])
            ]
            if currentlyDisliked {
                updates["dislikes"] = FieldValue.increment(Int64(-1))
                updates["dislikedBy"] = FieldValue.arrayRemove([userId])
            }
            try? await db.collection("posts").document(postId).updateData(updates)
        }
        await fetchPosts()
    }
    
    func toggleDislike(postId: String, userId: String, currentlyDisliked: Bool, currentlyLiked: Bool) async {
        if currentlyDisliked {
            try? await db.collection("posts").document(postId).updateData([
                "dislikes": FieldValue.increment(Int64(-1)),
                "dislikedBy": FieldValue.arrayRemove([userId])
            ])
        } else {
            var updates: [String: Any] = [
                "dislikes": FieldValue.increment(Int64(1)),
                "dislikedBy": FieldValue.arrayUnion([userId])
            ]
            if currentlyLiked {
                updates["likes"] = FieldValue.increment(Int64(-1))
                updates["likedBy"] = FieldValue.arrayRemove([userId])
            }
            try? await db.collection("posts").document(postId).updateData(updates)
        }
        await fetchPosts()
    }
    
    func fetchAnnouncements() async {
        print("📥 Fetching announcements from Firestore...")
        do {
            let snapshot = try await db.collection("announcements").order(by: "date", descending: true).getDocuments()
            announcements = snapshot.documents.compactMap { doc in
                let data = doc.data()
                guard let title = data["title"] as? String,
                      let content = data["content"] as? String,
                      let typeString = data["type"] as? String,
                      let timestamp = data["date"] as? Timestamp else { return nil }
                let type: AnnouncementType = typeString == "success" ? .success : .info
                return Announcement(title: title, type: type, date: timestamp.dateValue(), content: content)
            }
            print("✅ Downloaded \(announcements.count) announcements from Firestore")
        } catch {
            print("❌ Error fetching announcements: \(error)")
        }
    }
    
    func loadPosts() -> [Article] {
        return [
            Article(
                id: "1", title: "New COVID-19 Treatment Guidelines", author: "Dr. Sarah Johnson",
                date: Date(), content: "Updated protocols for managing COVID-19 patients in the ICU. Follow new dosing guidelines...",
                likes: 0, dislikes: 0, likedBy: [], dislikedBy: []
            ),
            Article(
                id: "2", title: "Sepsis Management Best Practices", author: "Dr. Michael Chen",
                date: Date().addingTimeInterval(-86400),
                content: "Evidence-based approach to early sepsis recognition and treatment...",
                likes: 0, dislikes: 0, likedBy: [], dislikedBy: []
            )
        ]
    }
    
    func loadAnnouncements() -> [Announcement] {
        // Return sample data for now
        return [
            Announcement(
                title: "System Maintenance - Jan 15", type: .info, date: Date(),
                content: "Epic will be down for maintenance from 2-4 AM"
            ),
            Announcement(
                title: "New CT Scanner Available", type: .success, date: Date().addingTimeInterval(-86400),
                content: "Floor 3 now has a new high-speed CT scanner"
            )
        ]
    }
}
