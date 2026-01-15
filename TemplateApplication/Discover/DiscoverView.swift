//
// Discover View for Health Companion
//

import FirebaseAuth
import SwiftUI

struct DiscoverView: View {
    @State private var selectedTab = 0
    @State private var showCreatePost = false
    @State private var articles: [Article] = []
    @State private var announcements: [Announcement] = []
    @StateObject private var postsService = PostsService()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Content Type", selection: $selectedTab) {
                    Text("Posts").tag(0)
                    Text("Announcements").tag(1)
                }
                .pickerStyle(.segmented)
                .padding()
                
                if selectedTab == 0 {
                    ArticlesListView(articles: $articles, postsService: postsService)
                } else {
                    AnnouncementsListView(announcements: $announcements, postsService: postsService)
                }
            }
            .navigationTitle("Discover")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showCreatePost = true }) {
                        Image(systemName: "plus.circle.fill")
                            .accessibilityLabel("Create new post")
                    }
                }
            }
            .sheet(isPresented: $showCreatePost) {
                CreatePostView(postsService: postsService, articles: $articles, announcements: $announcements)
            }
            .onAppear {
                Task {
                    await loadData()
                }
            }
        }
    }
    
    private func loadData() async {
        await postsService.fetchPosts()
        await postsService.fetchAnnouncements()
        articles = postsService.posts
        announcements = postsService.announcements
    }
}

struct ArticlesListView: View {
    @Binding var articles: [Article]
    @ObservedObject var postsService: PostsService
    
    var body: some View {
        ScrollView {
            VStack(spacing: 15) {
                ForEach(articles) { article in
                    NavigationLink(destination: ArticleDetailView(article: article)) {
                        ArticleCard(article: article, postsService: postsService, articles: $articles)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
        }
    }
}

struct AnnouncementsListView: View {
    @Binding var announcements: [Announcement]
    @ObservedObject var postsService: PostsService
    
    var body: some View {
        ScrollView {
            VStack(spacing: 15) {
                ForEach(announcements) { announcement in
                    AnnouncementCard(announcement: announcement, postsService: postsService, announcements: $announcements)
                }
            }
            .padding()
        }
    }
}

struct ArticleCard: View {
    let article: Article
    @ObservedObject var postsService: PostsService
    @Binding var articles: [Article]
    @State private var showDeleteAlert = false
    
    private var userId: String {
        Auth.auth().currentUser?.uid ?? ""
    }
    
    private var currentUserEmail: String {
        Auth.auth().currentUser?.email ?? ""
    }
    
    private var userRole: String {
        UserDefaults.standard.string(forKey: "userRole") ?? "doctor"
    }
    
    private var isAuthor: Bool {
        article.author == currentUserEmail
    }
    
    private var canDelete: Bool {
        isAuthor || userRole == "administrator"
    }
    
    private var hasLiked: Bool {
        article.likedBy.contains(userId)
    }
    
    private var hasDisliked: Bool {
        article.dislikedBy.contains(userId)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                articleHeader
                Spacer()
                if canDelete {
                    deleteButton
                }
            }
            articleMetadata
            articleContent
            reactionButtons
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .gray.opacity(0.15), radius: 5, x: 0, y: 2)
        .alert("Delete Post", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                Task {
                    try? await postsService.deletePost(postId: article.id)
                    articles = postsService.posts
                }
            }
        } message: {
            Text("Are you sure you want to delete this post? This action cannot be undone.")
        }
    }
    
    private var articleHeader: some View {
        Text(article.title)
            .font(.headline)
            .foregroundColor(Color(hex: "1976D2"))
    }
    
    private var articleMetadata: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(article.department)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(hex: "1976D2"))
                    .cornerRadius(8)
                Spacer()
                Text(article.date, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Text("By: \(article.author)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private var articleContent: some View {
        Text(article.content)
            .font(.body)
            .foregroundColor(.secondary)
            .lineLimit(3)
    }
    
    private var deleteButton: some View {
        Button {
            showDeleteAlert = true
        } label: {
            Image(systemName: "trash")
                .foregroundColor(.red)
                .accessibilityLabel("Delete post")
        }
        .buttonStyle(.plain)
    }
    
    private var reactionButtons: some View {
        HStack(spacing: 20) {
            Button {
                Task {
                    await postsService.toggleLike(
                        postId: article.id,
                        userId: userId,
                        currentlyLiked: hasLiked,
                        currentlyDisliked: hasDisliked
                    )
                    articles = postsService.posts
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: hasLiked ? "hand.thumbsup.fill" : "hand.thumbsup")
                        .accessibilityHidden(true)
                    Text("\(article.likes)")
                }
                .foregroundColor(hasLiked ? .blue : .gray)
                .accessibilityLabel("Like, \(article.likes) likes")
            }

            Button {
                Task {
                    await postsService.toggleDislike(
                        postId: article.id,
                        userId: userId,
                        currentlyDisliked: hasDisliked,
                        currentlyLiked: hasLiked
                    )
                    articles = postsService.posts
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: hasDisliked ? "hand.thumbsdown.fill" : "hand.thumbsdown")
                        .accessibilityHidden(true)
                    Text("\(article.dislikes)")
                }
                .foregroundColor(hasDisliked ? .red : .gray)
                .accessibilityLabel("Dislike, \(article.dislikes) dislikes")
            }
        }
    }
}

struct AnnouncementCard: View {
    let announcement: Announcement
    @ObservedObject var postsService: PostsService
    @Binding var announcements: [Announcement]
    @State private var showDeleteAlert = false
    
    private var userRole: String {
        UserDefaults.standard.string(forKey: "userRole") ?? "doctor"
    }
    
    private var isAdmin: Bool {
        userRole == "administrator"
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: announcement.type.icon)
                .font(.title2)
                .foregroundColor(announcement.type.color)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 5) {
                Text(announcement.title)
                    .font(.headline)
                Text(announcement.content)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(announcement.date, style: .date)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            Spacer()
            if isAdmin {
                Button {
                    showDeleteAlert = true
                } label: {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                        .accessibilityLabel("Delete announcement")
                }
                .buttonStyle(.plain)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .gray.opacity(0.15), radius: 5, x: 0, y: 2)
        .alert("Delete Announcement", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                Task {
                    try? await postsService.deleteAnnouncement(announcementId: announcement.id)
                    announcements = postsService.announcements
                }
            }
        } message: {
            Text("Are you sure you want to delete this announcement? This action cannot be undone.")
        }
    }
}

struct CreatePostView: View {
    @State private var postType = 0
    @State private var title = ""
    @State private var content = ""
    @State private var selectedDepartment = "Cardiology"
    @State private var announcementType = 0
    @ObservedObject var postsService: PostsService
    @Binding var articles: [Article]
    @Binding var announcements: [Announcement]
    @Environment(\.dismiss) private var dismiss
    
    private let departments = ["Cardiology", "Emergency Medicine", "Internal Medicine", "Surgery", "Radiology", "Administration"]
    
    var body: some View {
        NavigationStack {
            formContent
        }
    }
    
    private var formContent: some View {
        Form {
            Picker("Type", selection: $postType) {
                Text("Post").tag(0)
                Text("Announcement").tag(1)
            }
            
            if postType == 0 {
                Picker("Department", selection: $selectedDepartment) {
                    ForEach(departments, id: \.self) { dept in
                        Text(dept).tag(dept)
                    }
                }
            } else {
                Picker("Priority", selection: $announcementType) {
                    Text("Info").tag(0)
                    Text("Success").tag(1)
                    Text("Warning").tag(2)
                }
            }
            
            TextField("Title", text: $title)
            TextEditor(text: $content).frame(height: 200)
        }
        .navigationTitle("Create Post")
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Post") {
                    Task {
                        await savePost()
                        dismiss()
                    }
                }
                .disabled(title.isEmpty || content.isEmpty)
            }
        }
    }
    
    private func savePost() async {
        let userEmail = Auth.auth().currentUser?.email ?? "Unknown"
        if postType == 0 {
            try? await postsService.createPost(title: title, content: content, author: userEmail, department: selectedDepartment)
            articles = postsService.posts
        } else {
            let typeStr = announcementType == 0 ? "info" : (announcementType == 1 ? "success" : "warning")
            try? await postsService.createAnnouncement(title: title, content: content, type: typeStr, author: userEmail)
            announcements = postsService.announcements
        }
    }
}

struct ArticleDetailView: View {
    let article: Article
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text(article.title)
                    .font(.title)
                    .fontWeight(.bold)
                
                HStack {
                    Text("By \(article.author)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(article.date, style: .date)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Divider()
                
                Text(article.content)
                    .font(.body)
            }
            .padding()
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct Article: Identifiable {
    let id: String
    let title: String
    let author: String
    let department: String
    let date: Date
    let content: String
    var likes: Int
    var dislikes: Int
    var likedBy: [String]
    var dislikedBy: [String]
}

struct Announcement: Identifiable {
    let id: String
    let title: String
    let type: AnnouncementType
    let date: Date
    let content: String
}

enum AnnouncementType {
    case info, success, warning
    
    var icon: String {
        switch self {
        case .info: return "info.circle.fill"
        case .success: return "checkmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .info: return .blue
        case .success: return .green
        case .warning: return .orange
        }
    }
}
