//
// Discover View for Health Companion
//

import SwiftUI
import FirebaseAuth

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
                    AnnouncementsListView(announcements: $announcements)
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
    
    var body: some View {
        ScrollView {
            VStack(spacing: 15) {
                ForEach(announcements) { announcement in
                    AnnouncementCard(announcement: announcement)
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
    
    private var userId: String {
        Auth.auth().currentUser?.uid ?? ""
    }
    
    private var hasLiked: Bool {
        article.likedBy.contains(userId)
    }
    
    private var hasDisliked: Bool {
        article.dislikedBy.contains(userId)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            articleHeader
            articleMetadata
            articleContent
            reactionButtons
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .gray.opacity(0.15), radius: 5, x: 0, y: 2)
    }
    
    private var articleHeader: some View {
        Text(article.title)
            .font(.headline)
            .foregroundColor(Color(hex: "1976D2"))
    }
    
    private var articleMetadata: some View {
        HStack {
            Text(article.author)
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()
            Text(article.date, style: .date)
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
    
    private var reactionButtons: some View {
        HStack(spacing: 20) {
            Button {
                Task {
                    await postsService.toggleLike(
                        postId: article.id, userId: userId,
                        currentlyLiked: hasLiked, currentlyDisliked: hasDisliked
                    )
                    articles = postsService.posts
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: hasLiked ? "hand.thumbsup.fill" : "hand.thumbsup")
                    Text("\(article.likes)")
                }
                .foregroundColor(hasLiked ? .blue : .gray)
            }
            
            Button {
                Task {
                    await postsService.toggleDislike(
                        postId: article.id, userId: userId,
                        currentlyDisliked: hasDisliked, currentlyLiked: hasLiked
                    )
                    articles = postsService.posts
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: hasDisliked ? "hand.thumbsdown.fill" : "hand.thumbsdown")
                    Text("\(article.dislikes)")
                }
                .foregroundColor(hasDisliked ? .red : .gray)
            }
        }
    }
}

struct AnnouncementCard: View {
    let announcement: Announcement
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: announcement.type.icon)
                .font(.title2)
                .foregroundColor(announcement.type.color)
            
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
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .gray.opacity(0.15), radius: 5, x: 0, y: 2)
    }
}

struct CreatePostView: View {
    @State private var postType = 0
    @State private var title = ""
    @State private var content = ""
    @State private var announcementType = 0
    @ObservedObject var postsService: PostsService
    @Binding var articles: [Article]
    @Binding var announcements: [Announcement]
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                Picker("Type", selection: $postType) {
                    Text("Post").tag(0)
                    Text("Announcement").tag(1)
                }
                
                if postType == 1 {
                    Picker("Priority", selection: $announcementType) {
                        Text("Info").tag(0)
                        Text("Success").tag(1)
                        Text("Warning").tag(2)
                    }
                }
                
                TextField("Title", text: $title)
                
                TextEditor(text: $content)
                    .frame(height: 200)
            }
            .navigationTitle("Create Post")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
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
    }
    
    private func savePost() async {
        if postType == 0 {
            try? await postsService.createPost(title: title, content: content, author: "Current User")
            articles = postsService.posts
        } else {
            let typeStr = announcementType == 0 ? "info" : (announcementType == 1 ? "success" : "warning")
            try? await postsService.createAnnouncement(title: title, content: content, type: typeStr, author: "Current User")
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
    let date: Date
    let content: String
    var likes: Int
    var dislikes: Int
    var likedBy: [String]
    var dislikedBy: [String]
}

struct Announcement: Identifiable {
    let id = UUID()
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
